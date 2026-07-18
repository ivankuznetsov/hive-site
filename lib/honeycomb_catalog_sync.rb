# frozen_string_literal: true

require "json"
require "json_schemer"
require "open3"
require "tempfile"
require "uri"

module HoneycombCatalogSync
  ROOT = File.expand_path("..", __dir__)
  SCHEMA_ROOT = File.join(__dir__, "honeycomb_catalog_schemas")
  CATALOG_SCHEMA_PATH = File.join(SCHEMA_ROOT, "catalog-v2.json")
  LISTING_SCHEMA_PATH = File.join(SCHEMA_ROOT, "listing-evidence-v1.json")
  DEFAULT_OUTPUT_PATH = File.join(ROOT, "_data", "honeycombs.json")
  SOURCE_REPOSITORY = "https://github.com/ivankuznetsov/honeycomb"
  SOURCE_SCHEMA = "honeycomb-catalog/v2"
  SHA_PATTERN = /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/
  CAPABILITIES = %w[filesystem-read filesystem-write network shell].freeze
  PERMISSION_KEYS = %w[
    capabilities network_hosts filesystem_read filesystem_write secrets
  ].freeze

  class Error < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = Array(errors).map(&:to_s).uniq.sort.freeze
      super(@errors.join("; "))
    end
  end

  class UsageError < Error; end
  class SourceError < Error; end
  class ValidationError < Error; end
  class WriteError < Error; end

  # Kept until callers have migrated to the more specific error classes.
  Invalid = Error

  class SemVer
    include Comparable

    PATTERN = /\A(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?\z/

    attr_reader :major, :minor, :patch, :prerelease

    def self.parse(value)
      match = PATTERN.match(value.to_s)
      raise ValidationError, "invalid SemVer 2.0 version #{value.inspect}" unless match

      new(value, match)
    end

    def initialize(text, match)
      @text = text
      @major = Integer(match[1], 10)
      @minor = Integer(match[2], 10)
      @patch = Integer(match[3], 10)
      @prerelease = match[4]&.split(".")
    end

    def <=>(other)
      core = [major, minor, patch] <=> [other.major, other.minor, other.patch]
      return core unless core.zero?
      return 0 if prerelease.nil? && other.prerelease.nil?
      return 1 if prerelease.nil?
      return -1 if other.prerelease.nil?

      compare_prerelease(prerelease, other.prerelease)
    end

    def to_s
      @text
    end

    private

    def compare_prerelease(left, right)
      [left.length, right.length].max.times do |index|
        return -1 unless left[index]
        return 1 unless right[index]

        comparison = compare_identifier(left[index], right[index])
        return comparison unless comparison.zero?
      end
      0
    end

    def compare_identifier(left, right)
      left_numeric = left.match?(/\A\d+\z/)
      right_numeric = right.match?(/\A\d+\z/)
      return Integer(left, 10) <=> Integer(right, 10) if left_numeric && right_numeric
      return -1 if left_numeric
      return 1 if right_numeric

      left <=> right
    end
  end

  extend self

  def sync!(catalog_path:, source_sha:, output_path: DEFAULT_OUTPUT_PATH)
    validate_invocation!(catalog_path: catalog_path, source_sha: source_sha, output_path: output_path)
    catalog_bytes = read_catalog(catalog_path)
    validate_source!(catalog_path: catalog_path, source_sha: source_sha, catalog_bytes: catalog_bytes)
    document = validate_payload!(catalog_bytes)
    atomic_replace(output_path, catalog_bytes)
    document
  end

  def validate_payload!(bytes)
    document = parse(bytes)
    errors = schema_errors(document)
    raise ValidationError, errors unless errors.empty?

    errors = []
    entries = document.fetch("entries")
    validate_order_and_latest(entries, errors)
    entries.each_with_index { |entry, index| validate_entry(entry, "$.entries[#{index}]", errors) }
    raise ValidationError, errors unless errors.empty?

    document
  end

  def validate_source!(catalog_path:, source_sha:, catalog_bytes: nil)
    errors = source_input_errors(catalog_path, source_sha)
    raise SourceError, errors unless errors.empty?

    absolute_catalog = File.expand_path(catalog_path)
    root, root_error = git_stdout(File.dirname(absolute_catalog), "rev-parse", "--show-toplevel")
    unless root
      raise SourceError, "catalog input must live at the root of a local Honeycomb Git checkout: #{root_error}"
    end

    errors = []
    expected_path = File.join(root, "catalog.json")
    errors << "catalog input must be the Git checkout repository root catalog.json" unless same_file?(absolute_catalog, expected_path)

    origin, origin_error = git_stdout(root, "remote", "get-url", "origin")
    if !origin
      errors << "canonical Honeycomb origin is required: #{origin_error}"
    elsif !canonical_origin?(origin)
      errors << "canonical origin must identify the ivankuznetsov/honeycomb GitHub repository"
    end

    commit, commit_error = git_stdout(root, "rev-parse", "--verify", "#{source_sha}^{commit}")
    errors << "source SHA is not a commit in the local checkout: #{commit_error}" unless commit

    remote_main, remote_error = git_stdout(root, "rev-parse", "--verify", "refs/remotes/origin/main")
    errors << "local origin/main is required to verify the merged source commit: #{remote_error}" unless remote_main
    if commit && remote_main
      _stdout, stderr, status = Open3.capture3("git", "-C", root, "merge-base", "--is-ancestor", commit, remote_main)
      detail = stderr.empty? ? "" : ": #{stderr.lines.first.to_s.strip}"
      errors << "source SHA is not merged into the local origin/main ref#{detail}" unless status.success?
    end

    if commit
      committed_bytes, stderr, status = Open3.capture3("git", "-C", root, "show", "#{commit}:catalog.json")
      if !status.success?
        errors << "source commit does not contain repository-root catalog.json: #{stderr.lines.first.to_s.strip}"
      elsif committed_bytes != (catalog_bytes || read_catalog(catalog_path))
        errors << "catalog input bytes do not match catalog.json at source SHA #{source_sha}"
      end
    end

    raise SourceError, errors unless errors.empty?

    root
  rescue Errno::ENOENT => e
    raise SourceError, "Git is required to verify the pinned catalog source: #{e.message}"
  end

  private

  def validate_invocation!(catalog_path:, source_sha:, output_path:)
    errors = source_input_errors(catalog_path, source_sha)
    output_directory = File.dirname(output_path.to_s)
    errors << "output directory does not exist: #{output_directory}" unless File.directory?(output_directory)
    raise UsageError, errors unless errors.empty?
  end

  def source_input_errors(catalog_path, source_sha)
    errors = []
    unless File.basename(catalog_path.to_s) == "catalog.json"
      errors << "catalog input must be an explicit repository-root catalog.json path"
    end
    errors << "catalog input does not exist: #{catalog_path}" unless File.file?(catalog_path.to_s)
    unless SHA_PATTERN.match?(source_sha.to_s)
      errors << "source SHA must be a lowercase 40- or 64-character full commit ID"
    end
    errors
  end

  def read_catalog(path)
    File.binread(path)
  rescue SystemCallError, IOError => e
    raise SourceError, "catalog input is unreadable: #{e.message}"
  end

  def parse(bytes)
    source = bytes.to_s.dup.force_encoding(Encoding::UTF_8)
    raise ValidationError, "catalog JSON must be valid UTF-8" unless source.valid_encoding?

    JSON.parse(source, create_additions: false, allow_duplicate_key: false)
  rescue JSON::ParserError => e
    label = e.message.match?(/duplicate/i) ? "duplicate JSON key" : "malformed JSON"
    raise ValidationError, "#{label}: #{e.message.lines.first.to_s.strip}"
  end

  def schema_errors(document)
    catalog_schema = load_schema(CATALOG_SCHEMA_PATH)
    listing_schema = load_schema(LISTING_SCHEMA_PATH)
    references = {URI(listing_schema.fetch("$id")) => listing_schema}
    schemer = JSONSchemer.schema(catalog_schema, ref_resolver: references.to_proc, format: true)
    schemer.validate(document).map { |error| format_schema_error(error) }
  rescue JSONSchemer::UnknownRef => e
    ["local schema reference unavailable: #{e.message}"]
  rescue JSON::ParserError, KeyError, SystemCallError => e
    ["local catalog schema is unreadable: #{e.message}"]
  end

  def load_schema(path)
    JSON.parse(File.binread(path), create_additions: false, allow_duplicate_key: false)
  end

  def format_schema_error(error)
    location = json_pointer_path(error.fetch("data_pointer", ""))
    missing = error.dig("details", "missing_keys")
    location = "#{location}.#{missing.first}" if error["type"] == "required" && missing&.one?
    detail = error["error"] || error["type"] || "does not match the catalog schema"
    detail = "unknown field is not allowed" if detail.include?("disallowed additional property")
    "#{location}: #{detail}"
  end

  def json_pointer_path(pointer)
    pointer.to_s.split("/").drop(1).reduce("$") do |path, raw|
      segment = raw.gsub("~1", "/").gsub("~0", "~")
      segment.match?(/\A\d+\z/) ? "#{path}[#{segment}]" : "#{path}.#{segment}"
    end
  end

  def validate_order_and_latest(entries, errors)
    parsed_versions = entries.map { |entry| SemVer.parse(entry.fetch("version")) }
    identities = {}

    entries.each_with_index do |entry, index|
      identity = [entry.fetch("name"), entry.fetch("version")]
      errors << "$.entries[#{index}]: duplicate name/version identity #{identity.join('@')}" if identities.key?(identity)
      identities[identity] = true
      next if index.zero?

      previous = entries[index - 1]
      comparison = previous.fetch("name") <=> entry.fetch("name")
      comparison = parsed_versions[index - 1] <=> parsed_versions[index] if comparison.zero?
      errors << "$.entries: entries are not in canonical name-then-SemVer order" if comparison.positive?
    end

    entries.group_by { |entry| entry.fetch("name") }.each do |name, grouped|
      parsed = grouped.map { |entry| [entry, SemVer.parse(entry.fetch("version"))] }
      parsed.combination(2) do |left, right|
        next unless (left.last <=> right.last).zero? && left.first.fetch("version") != right.first.fetch("version")

        errors << "$.entries: #{name} versions #{left.first.fetch('version')} and #{right.first.fetch('version')} have ambiguous SemVer precedence"
      end

      listed = parsed.select { |entry, _version| entry.fetch("state") == "listed" }
      expected = listed.empty? ? nil : listed.max_by(&:last).first.fetch("version")
      grouped.each do |entry|
        next if entry.fetch("latest_version") == expected

        errors << "$.entries: #{name}@#{entry.fetch('version')} latest_version must be #{expected.inspect}"
      end
    end
  end

  def validate_entry(entry, path, errors)
    validate_lifecycle(entry, path, errors)
    validate_permissions(entry, path, errors)
    validate_urls(entry, path, errors)
    validate_install_and_review_links(entry, path, errors)
  end

  def validate_lifecycle(entry, path, errors)
    state = entry.fetch("state")
    expected_discoverable = state == "listed"
    expected_resolution = state == "revoked" ? "blocked" : "allowed"
    unless entry.fetch("discoverable") == expected_discoverable
      errors << "#{path}.discoverable: must be #{expected_discoverable} for state #{state}"
    end
    unless entry.fetch("exact_resolution") == expected_resolution
      errors << "#{path}.exact_resolution: must be #{expected_resolution} for state #{state}"
    end
  end

  def validate_permissions(entry, path, errors)
    permissions = entry.fetch("permissions")
    unless entry.fetch("permission_risk") == permissions.fetch("risk")
      errors << "#{path}.permission_risk: must match permissions.risk"
    end

    PERMISSION_KEYS.each do |key|
      values = permissions.fetch(key)
      if values.any? { |value| value.empty? || value != value.strip }
        errors << "#{path}.permissions.#{key}: values must be non-empty normalized strings"
      end
      unless values == values.uniq.sort
        errors << "#{path}.permissions.#{key}: values must be unique and sorted"
      end
      if values.include?("*") && values != ["*"]
        errors << "#{path}.permissions.#{key}: wildcard must be the only value"
      end
    end

    unknown = permissions.fetch("capabilities") - CAPABILITIES
    unless unknown.empty?
      errors << "#{path}.permissions.capabilities: unknown values #{unknown.join(', ')}"
    end
  end

  def validate_urls(entry, path, errors)
    urls = {
      "#{path}.author.url" => entry.dig("author", "url"),
      "#{path}.package_url" => entry.fetch("package_url"),
      "#{path}.reviews_url" => entry.fetch("reviews_url")
    }
    urls["#{path}.community_reviews_url"] = entry.fetch("community_reviews_url") if entry.fetch("community_reviews_url")

    if (verification = entry.fetch("verification"))
      %w[identity issuer url].each do |key|
        urls["#{path}.verification.signature.#{key}"] = verification.dig("signature", key)
      end
      urls["#{path}.verification.attestation.url"] = verification.dig("attestation", "url")
    end
    entry.fetch("history").each_with_index do |item, index|
      urls["#{path}.history[#{index}].url"] = item.fetch("url")
    end
    entry.fetch("advisories").each_with_index do |item, index|
      urls["#{path}.advisories[#{index}].url"] = item.fetch("url")
    end
    entry.dig("listing_approval", "reviews").each_with_index do |review, index|
      urls["#{path}.listing_approval.reviews[#{index}].review_url"] = review.fetch("review_url")
    end

    urls.each do |url_path, value|
      errors << "#{url_path}: URL must be safe absolute HTTPS without credentials or control characters" unless safe_https?(value)
    end
  end

  def safe_https?(value)
    return false unless value.is_a?(String) && !value.match?(/[[:cntrl:]]/)

    uri = URI.parse(value)
    uri.is_a?(URI::HTTPS) && uri.host && !uri.host.empty? && uri.userinfo.nil?
  rescue URI::InvalidURIError
    false
  end

  def validate_install_and_review_links(entry, path, errors)
    name = entry.fetch("name")
    version = entry.fetch("version")
    expected_command = "hive workflow install honeycomb/#{name}"
    unless entry.fetch("install_command") == expected_command
      errors << "#{path}.install_command: must be #{expected_command.inspect}"
    end

    expected_package = "#{SOURCE_REPOSITORY}/tree/main/packages/#{name}/#{version}"
    unless entry.fetch("package_url") == expected_package
      errors << "#{path}.package_url: must identify the canonical default-branch version path"
    end

    reviews = entry.dig("listing_approval", "reviews")
    if reviews.empty?
      errors << "#{path}.listing_approval.reviews: at least one designated review is required"
    elsif entry.fetch("reviews_url") != reviews.first.fetch("review_url")
      errors << "#{path}.reviews_url: must match the first designated review"
    end

    community_url = entry.fetch("community_reviews_url")
    return unless community_url

    expected_community = "#{SOURCE_REPOSITORY}/tree/main/reviews/#{name}/#{version}"
    unless community_url == expected_community
      errors << "#{path}.community_reviews_url: must identify the canonical default-branch review directory"
    end
  end

  def same_file?(left, right)
    File.realpath(left) == File.realpath(right)
  rescue SystemCallError
    false
  end

  def canonical_origin?(origin)
    return false if origin.to_s.match?(/[[:cntrl:]]/)

    if (match = origin.match(/\A(?:[^@\s]+@)?github\.com:([^\s]+)\z/))
      return canonical_repository_path?(match[1])
    end

    uri = URI.parse(origin)
    return false unless %w[https ssh].include?(uri.scheme) && uri.host&.downcase == "github.com"

    canonical_repository_path?(uri.path)
  rescue URI::InvalidURIError
    false
  end

  def canonical_repository_path?(path)
    path.to_s.sub(%r{\A/}, "").sub(%r{/\z}, "").sub(/\.git\z/, "") == "ivankuznetsov/honeycomb"
  end

  def git_stdout(directory, *arguments)
    stdout, stderr, status = Open3.capture3("git", "-C", directory, *arguments)
    status.success? ? [stdout.strip, nil] : [nil, stderr.lines.first.to_s.strip]
  end

  def atomic_replace(path, bytes)
    tempfile = Tempfile.new([".honeycombs", ".json"], File.dirname(path))
    tempfile.binmode
    tempfile.write(bytes)
    tempfile.flush
    tempfile.fsync
    File.chmod(output_mode(path), tempfile.path)
    tempfile.close
    File.rename(tempfile.path, path)
  rescue SystemCallError, IOError => e
    raise WriteError, "snapshot write failed: #{e.message}"
  ensure
    begin
      tempfile&.close!
    rescue SystemCallError, IOError
      nil
    end
  end

  def output_mode(path)
    File.stat(path).mode & 0o7777
  rescue Errno::ENOENT
    0o644
  end
end
