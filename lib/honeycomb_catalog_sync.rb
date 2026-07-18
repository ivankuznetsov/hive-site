# frozen_string_literal: true

require "digest"
require "json"
require "json_schemer"
require "open3"
require "tempfile"
require "time"
require "uri"

module HoneycombCatalogSync
  ROOT = File.expand_path("..", __dir__)
  CATALOG_SCHEMA_PATH = File.join(ROOT, "schemas", "catalog-v2.json")
  LISTING_SCHEMA_PATH = File.join(ROOT, "schemas", "listing-evidence-v1.json")
  DEFAULT_OUTPUT_PATH = File.join(ROOT, "_data", "honeycombs.json")
  SOURCE_REPOSITORY = "https://github.com/ivankuznetsov/honeycomb"
  SOURCE_SCHEMA = "honeycomb-catalog/v2"
  SNAPSHOT_SCHEMA = "hive-site-honeycombs/v1"
  SHA_PATTERN = /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/
  CAPABILITIES = %w[filesystem-read filesystem-write network shell].freeze
  PERMISSION_KEYS = %w[
    capabilities network_hosts filesystem_read filesystem_write secrets
  ].freeze

  class Invalid < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = Array(errors).map(&:to_s).uniq.sort.freeze
      super(@errors.join("; "))
    end
  end

  class SemVer
    include Comparable

    PATTERN = /\A(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?\z/

    attr_reader :major, :minor, :patch, :prerelease

    def self.parse(value)
      match = PATTERN.match(value.to_s)
      raise Invalid, "invalid SemVer 2.0 version #{value.inspect}" unless match

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
    errors = invocation_errors(catalog_path, source_sha, output_path)
    raise Invalid, errors unless errors.empty?

    catalog_bytes = File.binread(catalog_path)
    errors = source_verification_errors(catalog_path, source_sha, catalog_bytes)
    raise Invalid, errors unless errors.empty?
    document = parse(catalog_bytes)
    errors = validate(document)
    raise Invalid, errors unless errors.empty?

    snapshot = {
      "schema" => SNAPSHOT_SCHEMA,
      "source" => {
        "repository" => SOURCE_REPOSITORY,
        "commit" => source_sha,
        "path" => "catalog.json",
        "schema" => SOURCE_SCHEMA,
        "sha256" => Digest::SHA256.hexdigest(catalog_bytes)
      },
      "entries" => document.fetch("entries")
    }
    bytes = JSON.pretty_generate(snapshot, allow_nan: false) + "\n"
    atomic_replace(output_path, bytes)
    snapshot
  rescue Invalid
    raise
  rescue SystemCallError, IOError => e
    raise Invalid, "I/O failure: #{e.message}"
  end

  private

  def invocation_errors(catalog_path, source_sha, output_path)
    errors = []
    errors << "catalog input must be an explicit repository-root catalog.json path" unless File.basename(catalog_path.to_s) == "catalog.json"
    errors << "catalog input does not exist: #{catalog_path}" unless File.file?(catalog_path.to_s)
    errors << "source SHA must be a lowercase 40- or 64-character commit ID" unless SHA_PATTERN.match?(source_sha.to_s)
    errors << "output directory does not exist: #{File.dirname(output_path.to_s)}" unless File.directory?(File.dirname(output_path.to_s))
    errors
  end

  def parse(bytes)
    source = bytes.dup.force_encoding(Encoding::UTF_8)
    raise Invalid, "catalog JSON must be valid UTF-8" unless source.valid_encoding?

    JSON.parse(source, create_additions: false, allow_duplicate_key: false)
  rescue JSON::ParserError => e
    raise Invalid, "malformed JSON: #{e.message.lines.first.to_s.strip}"
  end

  def source_verification_errors(catalog_path, source_sha, catalog_bytes)
    errors = []
    root, root_error = git_stdout(File.dirname(File.expand_path(catalog_path)), "rev-parse", "--show-toplevel")
    return ["catalog input must live at the root of a local Honeycomb Git checkout: #{root_error}"] unless root

    expected_path = File.join(root, "catalog.json")
    unless File.realpath(catalog_path) == File.realpath(expected_path)
      errors << "catalog input must be the Git checkout root catalog.json"
      return errors
    end

    commit, commit_error = git_stdout(root, "rev-parse", "--verify", "#{source_sha}^{commit}")
    errors << "source SHA is not a commit in the local checkout: #{commit_error}" unless commit

    remote_main, remote_error = git_stdout(root, "rev-parse", "--verify", "refs/remotes/origin/main")
    errors << "local origin/main is required to verify the merged source commit: #{remote_error}" unless remote_main
    if commit && remote_main
      _stdout, stderr, status = Open3.capture3("git", "-C", root, "merge-base", "--is-ancestor", commit, remote_main)
      errors << "source SHA is not merged into the local origin/main ref#{stderr.empty? ? "" : ": #{stderr.strip}"}" unless status.success?
    end

    if commit
      committed_bytes, stderr, status = Open3.capture3("git", "-C", root, "show", "#{commit}:catalog.json")
      if !status.success?
        errors << "source commit does not contain repository-root catalog.json: #{stderr.strip}"
      elsif committed_bytes != catalog_bytes
        errors << "catalog input bytes do not match catalog.json at source SHA #{source_sha}"
      end
    end
    errors
  rescue Errno::ENOENT => e
    ["Git is required to verify the pinned catalog source: #{e.message}"]
  end

  def git_stdout(directory, *arguments)
    stdout, stderr, status = Open3.capture3("git", "-C", directory, *arguments)
    status.success? ? [stdout.strip, nil] : [nil, stderr.lines.first.to_s.strip]
  end

  def validate(document)
    errors = schema_errors(document)
    return errors unless errors.empty?

    entries = document.fetch("entries")
    validate_order_and_latest(entries, errors)
    entries.each_with_index { |entry, index| validate_entry(entry, "$.entries[#{index}]", errors) }
    errors
  end

  def schema_errors(document)
    catalog_schema = JSON.parse(File.binread(CATALOG_SCHEMA_PATH))
    listing_schema = JSON.parse(File.binread(LISTING_SCHEMA_PATH))
    references = {URI("https://hivecli.sh/schemas/listing-evidence-v1.json") => listing_schema}
    schemer = JSONSchemer.schema(catalog_schema, ref_resolver: references.to_proc, format: true)
    schemer.validate(document).map do |error|
      pointer = error.fetch("data_pointer", "")
      location = pointer.empty? ? "$" : "$#{pointer.gsub("/", ".")}"
      detail = error["error"] || error["type"] || "does not match the catalog schema"
      detail = "unknown field is not allowed" if detail.include?("disallowed additional property")
      "#{location}: #{detail}"
    end
  rescue JSONSchemer::UnknownRef => e
    ["local schema reference unavailable: #{e.message}"]
  rescue JSON::ParserError, SystemCallError => e
    ["local catalog schema is unreadable: #{e.message}"]
  end

  def validate_order_and_latest(entries, errors)
    identities = {}
    versions = entries.map { |entry| SemVer.parse(entry.fetch("version")) }
    entries.each_with_index do |entry, index|
      identity = [entry.fetch("name"), entry.fetch("version")]
      if identities.key?(identity)
        errors << "$.entries[#{index}]: duplicate name/version identity #{identity.join("@")}"
      end
      identities[identity] = true

      next if index.zero?

      previous = entries[index - 1]
      comparison = previous.fetch("name") <=> entry.fetch("name")
      comparison = versions[index - 1] <=> versions[index] if comparison.zero?
      errors << "$.entries: entries are not in canonical name-then-SemVer order" if comparison.positive?
      if previous.fetch("name") == entry.fetch("name") && comparison.zero? &&
         previous.fetch("version") != entry.fetch("version")
        errors << "$.entries: versions #{previous.fetch("version")} and #{entry.fetch("version")} have ambiguous SemVer precedence"
      end
    end

    entries.group_by { |entry| entry.fetch("name") }.each do |name, grouped|
      listed = grouped.select { |entry| entry.fetch("state") == "listed" }
      expected = latest_version(listed, name, errors)
      grouped.each do |entry|
        next if entry.fetch("latest_version") == expected

        errors << "$.entries: #{name}@#{entry.fetch("version")} latest_version must be #{expected.inspect}"
      end
    end
  end

  def latest_version(entries, name, errors)
    return nil if entries.empty?

    parsed = entries.map { |entry| [entry, SemVer.parse(entry.fetch("version"))] }
    parsed.combination(2) do |left, right|
      next unless (left.last <=> right.last).zero? && left.first.fetch("version") != right.first.fetch("version")

      errors << "$.entries: #{name} has ambiguous latest-version precedence"
    end
    parsed.max_by(&:last).first.fetch("version")
  end

  def validate_entry(entry, path, errors)
    validate_lifecycle(entry, path, errors)
    validate_permissions(entry, path, errors)
    validate_urls(entry, path, errors)
    validate_install_and_approval(entry, path, errors)
    validate_history(entry, path, errors)
    validate_advisories(entry, path, errors)
    validate_verification(entry, path, errors)
  end

  def validate_lifecycle(entry, path, errors)
    state = entry.fetch("state")
    discoverable = state == "listed"
    exact_resolution = state == "revoked" ? "blocked" : "allowed"
    errors << "#{path}.discoverable: must be #{discoverable} for state #{state}" unless entry.fetch("discoverable") == discoverable
    errors << "#{path}.exact_resolution: must be #{exact_resolution} for state #{state}" unless entry.fetch("exact_resolution") == exact_resolution
    if state == "revoked" && entry.fetch("advisories").empty?
      errors << "#{path}.advisories: revoked entries require a public advisory"
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
      errors << "#{path}.permissions.#{key}: values must be unique and sorted" unless values == values.uniq.sort
      if values.include?("*") && values != ["*"]
        errors << "#{path}.permissions.#{key}: wildcard must be the only value"
      end
    end
    unknown = permissions.fetch("capabilities") - CAPABILITIES
    unless unknown.empty?
      errors << "#{path}.permissions.capabilities: unknown values #{unknown.join(", ")}"
    end
  end

  def validate_urls(entry, path, errors)
    urls = {
      "#{path}.author.url" => entry.dig("author", "url"),
      "#{path}.package_url" => entry.fetch("package_url"),
      "#{path}.reviews_url" => entry.fetch("reviews_url")
    }
    community = entry.fetch("community_reviews_url")
    urls["#{path}.community_reviews_url"] = community if community
    verification = entry.fetch("verification")
    if verification
      %w[identity issuer url].each do |key|
        urls["#{path}.verification.signature.#{key}"] = verification.dig("signature", key)
      end
      urls["#{path}.verification.attestation.url"] = verification.dig("attestation", "url")
    end
    entry.fetch("history").each_with_index { |item, index| urls["#{path}.history[#{index}].url"] = item.fetch("url") }
    entry.fetch("advisories").each_with_index { |item, index| urls["#{path}.advisories[#{index}].url"] = item.fetch("url") }
    entry.dig("listing_approval", "reviews").each_with_index do |review, index|
      urls["#{path}.listing_approval.reviews[#{index}].review_url"] = review.fetch("review_url")
    end
    urls.each { |url_path, value| errors << "#{url_path}: URL must be safe absolute HTTPS without credentials or fragments" unless safe_https?(value) }
  end

  def safe_https?(value)
    uri = URI.parse(value)
    value.is_a?(String) && uri.is_a?(URI::HTTPS) && uri.host && !uri.host.empty? &&
      uri.userinfo.nil? && uri.fragment.nil?
  rescue URI::InvalidURIError, TypeError
    false
  end

  def validate_install_and_approval(entry, path, errors)
    expected_command = "hive workflow install honeycomb/#{entry.fetch("name")}"
    unless entry.fetch("install_command") == expected_command
      errors << "#{path}.install_command: must be #{expected_command.inspect}"
    end

    approval = entry.fetch("listing_approval")
    expected_package_url = "#{SOURCE_REPOSITORY}/tree/main/packages/#{entry.fetch("name")}/#{entry.fetch("version")}"
    unless entry.fetch("package_url") == expected_package_url
      errors << "#{path}.package_url: must identify the canonical main-branch package path"
    end
    reviews = approval.fetch("reviews")
    reviewers = reviews.map { |review| review.fetch("reviewer") }
    approved_by = approval.fetch("approved_by")
    errors << "#{path}.listing_approval.approved_by: must be unique and sorted" unless approved_by == approved_by.map(&:downcase).uniq.sort
    errors << "#{path}.listing_approval.reviews: must be sorted by reviewer" unless reviewers == reviewers.map(&:downcase).sort
    errors << "#{path}.listing_approval.approved_by: must match designated reviews" unless approved_by == reviewers
    minimum = entry.fetch("permission_risk") == "high" ? 2 : 1
    if approved_by.length < minimum
      errors << "#{path}.listing_approval.approved_by: #{entry.fetch("permission_risk")} risk requires at least #{minimum} approvals"
    end
    if reviews.empty?
      errors << "#{path}.listing_approval.reviews: at least one designated review is required"
    else
      unless entry.fetch("reviews_url") == reviews.first.fetch("review_url")
        errors << "#{path}.reviews_url: must match the first designated review"
      end
      approved_at = reviews.map { |review| Time.iso8601(review.fetch("reviewed_at")) }.max.iso8601
      unless Time.iso8601(approval.fetch("approved_at")).iso8601 == approved_at
        errors << "#{path}.listing_approval.approved_at: must match the newest designated review"
      end
    end

    community_url = entry.fetch("community_reviews_url")
    if community_url
      expected = "#{SOURCE_REPOSITORY}/tree/main/reviews/#{entry.fetch("name")}/#{entry.fetch("version")}"
      errors << "#{path}.community_reviews_url: must identify the canonical review directory" unless community_url == expected
    end
  end

  def validate_history(entry, path, errors)
    tier = entry.fetch("release_tier")
    state = "listed"
    history = entry.fetch("history")
    history.each_with_index do |event, index|
      current = event.fetch("kind") == "tier" ? tier : state
      unless event.fetch("from") == current && event.fetch("to") != current
        errors << "#{path}.history[#{index}]: transition must start at the preceding value and change it"
      end
      if event.fetch("kind") == "tier"
        tier = event.fetch("to")
      else
        state = event.fetch("to")
      end
    end
    unless tier == entry.fetch("current_tier") && state == entry.fetch("state")
      errors << "#{path}.history: does not project current_tier and state"
    end
    sorted = history.sort_by { |event| [Time.iso8601(event.fetch("changed_at")), event.fetch("kind"), event.fetch("actor")] }
    errors << "#{path}.history: must be ordered by time, kind, and actor" unless history == sorted
  end

  def validate_advisories(entry, path, errors)
    advisories = entry.fetch("advisories")
    ids = advisories.map { |advisory| advisory.fetch("id") }
    errors << "#{path}.advisories: advisory IDs must be unique" unless ids == ids.uniq
    sorted = advisories.sort_by { |advisory| [Time.iso8601(advisory.fetch("published_at")), advisory.fetch("id")] }
    errors << "#{path}.advisories: must be ordered by publication time and ID" unless advisories == sorted
  end

  def validate_verification(entry, path, errors)
    verified_ever = entry.fetch("release_tier") == "verified" || entry.fetch("current_tier") == "verified" ||
                    entry.fetch("history").any? do |event|
                      event.fetch("kind") == "tier" && [event.fetch("from"), event.fetch("to")].include?("verified")
                    end
    verification = entry.fetch("verification")
    if verified_ever && verification.nil?
      errors << "#{path}.verification: current or historic Verified tier requires evidence"
      return
    end
    return unless verification

    repository = verification.dig("attestation", "repository")
    workflow = verification.dig("attestation", "workflow")
    unless workflow.start_with?("#{repository}/.github/workflows/") && !workflow.include?("..")
      errors << "#{path}.verification.attestation.workflow: must belong to the attested repository"
    end
    signature = verification.fetch("signature")
    unless signature.fetch("identity") == "https://github.com/#{workflow}" &&
           signature.fetch("issuer") == "https://token.actions.githubusercontent.com"
      errors << "#{path}.verification.signature: identity must match the attested GitHub Actions workflow"
    end
  end

  def atomic_replace(path, bytes)
    directory = File.dirname(path)
    tempfile = Tempfile.new([".honeycombs", ".json"], directory)
    tempfile.binmode
    tempfile.write(bytes)
    tempfile.flush
    tempfile.fsync
    File.chmod(output_mode(path), tempfile.path)
    tempfile.close
    File.rename(tempfile.path, path)
  ensure
    tempfile&.close!
  end

  def output_mode(path)
    File.stat(path).mode
  rescue Errno::ENOENT
    0o644
  end
end
