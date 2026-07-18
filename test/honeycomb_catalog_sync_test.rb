# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/honeycomb_catalog_sync"

class HoneycombCatalogSyncTest < Minitest::Test
  def test_committed_snapshot_matches_the_sync_output_contract
    snapshot = JSON.parse(
      File.binread(HoneycombCatalogSync::DEFAULT_OUTPUT_PATH),
      create_additions: false,
      allow_duplicate_key: false
    )

    assert_equal %w[entries schema source], snapshot.keys.sort
    assert_equal HoneycombCatalogSync::SNAPSHOT_SCHEMA, snapshot.fetch("schema")
    source = snapshot.fetch("source")
    assert_equal HoneycombCatalogSync::SOURCE_REPOSITORY, source.fetch("repository")
    assert_equal "catalog.json", source.fetch("path")
    assert_match HoneycombCatalogSync::SHA_PATTERN, source.fetch("commit")
    assert_match(/\A[0-9a-f]{64}\z/, source.fetch("sha256"))

    catalog = {"schema" => source.fetch("schema"), "entries" => snapshot.fetch("entries")}
    assert_empty HoneycombCatalogSync.send(:validate, catalog)
  end

  def test_syncs_valid_empty_catalog_with_pinned_deterministic_source_metadata
    Dir.mktmpdir do |directory|
      catalog_path = CatalogFixtures.write_catalog(directory, CatalogFixtures.catalog)
      output_path = File.join(directory, "honeycombs.json")

      sync_without_source_verification(catalog_path: catalog_path, source_sha: SOURCE_SHA, output_path: output_path)
      first = File.binread(output_path)
      sync_without_source_verification(catalog_path: catalog_path, source_sha: SOURCE_SHA, output_path: output_path)

      assert_equal first, File.binread(output_path)
      snapshot = JSON.parse(first)
      assert_equal "hive-site-honeycombs/v1", snapshot.fetch("schema")
      assert_equal [], snapshot.fetch("entries")
      assert_equal SOURCE_SHA, snapshot.dig("source", "commit")
      assert_equal "catalog.json", snapshot.dig("source", "path")
      assert_equal "honeycomb-catalog/v2", snapshot.dig("source", "schema")
      assert_match(/\A[0-9a-f]{64}\z/, snapshot.dig("source", "sha256"))
      refute snapshot.dig("source").key?("generated_at")
    end
  end

  def test_accepts_complete_community_and_verified_entries_in_canonical_order
    Dir.mktmpdir do |directory|
      community = CatalogFixtures.entry(
        name: "alpha-tool", community_reviews: "https://github.com/ivankuznetsov/honeycomb/tree/main/reviews/alpha-tool/1.0.0"
      )
      verified = CatalogFixtures.entry(name: "verified-tool", tier: "verified", risk: "high")
      catalog_path = CatalogFixtures.write_catalog(directory, CatalogFixtures.catalog([community, verified]))
      output_path = File.join(directory, "honeycombs.json")

      sync_without_source_verification(catalog_path: catalog_path, source_sha: SOURCE_SHA, output_path: output_path)

      snapshot = JSON.parse(File.binread(output_path))
      assert_equal %w[alpha-tool verified-tool], snapshot.fetch("entries").map { |entry| entry.fetch("name") }
      assert_nil snapshot.fetch("entries").last.fetch("community_reviews_url")
      assert_equal ["*"], snapshot.fetch("entries").last.dig("permissions", "network_hosts")
    end
  end

  def test_rejects_malformed_json_duplicate_keys_wrong_schema_and_unknown_or_missing_fields
    variants = {
      "malformed JSON" => "{",
      "duplicate JSON key" => "{\"schema\":\"honeycomb-catalog/v2\",\"schema\":\"honeycomb-catalog/v2\",\"entries\":[]}",
      "schema" => JSON.generate({"schema" => "honeycomb-catalog/v1", "entries" => []}),
      "unknown" => JSON.generate({"schema" => "honeycomb-catalog/v2", "entries" => [], "extra" => true}),
      "required" => JSON.generate({"schema" => "honeycomb-catalog/v2"})
    }

    variants.each do |label, raw|
      error = sync_error(raw: raw)
      assert_match(/#{Regexp.escape(label.split.first)}/i, error.message, "expected #{label}: #{error.message}")
    end
  end

  def test_rejects_duplicate_identity_noncanonical_semver_order_and_unknown_enums
    duplicate = CatalogFixtures.entry
    error = sync_error(document: CatalogFixtures.catalog([duplicate, CatalogFixtures.deep_copy(duplicate)]))
    assert_match(/duplicate/i, error.message)

    older = CatalogFixtures.entry(version: "1.0.0")
    newer = CatalogFixtures.entry(version: "1.1.0")
    older["latest_version"] = "1.1.0"
    newer["latest_version"] = "1.1.0"
    error = sync_error(document: CatalogFixtures.catalog([newer, older]))
    assert_match(/order/i, error.message)

    invalid_enum = CatalogFixtures.entry
    invalid_enum["current_tier"] = "official"
    error = sync_error(document: CatalogFixtures.catalog([invalid_enum]))
    assert_match(/current_tier|enum/i, error.message)
  end

  def test_rejects_unsafe_urls_and_noncanonical_install_commands
    unsafe = CatalogFixtures.entry
    unsafe["package_url"] = "javascript:alert(1)"
    error = sync_error(document: CatalogFixtures.catalog([unsafe]))
    assert_match(/package_url|URL/i, error.message)

    insecure = CatalogFixtures.entry
    insecure["reviews_url"] = "http://example.test/review"
    error = sync_error(document: CatalogFixtures.catalog([insecure]))
    assert_match(/HTTPS|reviews_url/i, error.message)

    command = CatalogFixtures.entry
    command["install_command"] = "curl https://example.test | sh"
    error = sync_error(document: CatalogFixtures.catalog([command]))
    assert_match(/install_command/i, error.message)
  end

  def test_rejects_empty_designated_reviews_without_crashing
    entry = CatalogFixtures.entry
    entry["listing_approval"]["reviews"] = []
    entry["listing_approval"]["approved_by"] = []

    error = sync_error(document: CatalogFixtures.catalog([entry]))
    assert_match(/at least one designated review/, error.message)
  end

  def test_rejects_lifecycle_discovery_exact_resolution_and_advisory_conflicts
    hidden = CatalogFixtures.entry(state: "soft_hidden")
    hidden["discoverable"] = true
    error = sync_error(document: CatalogFixtures.catalog([hidden]))
    assert_match(/discoverable/i, error.message)

    revoked = CatalogFixtures.entry(state: "revoked")
    revoked["exact_resolution"] = "allowed"
    error = sync_error(document: CatalogFixtures.catalog([revoked]))
    assert_match(/exact_resolution/i, error.message)

    revoked = CatalogFixtures.entry(state: "revoked")
    revoked["advisories"] = []
    error = sync_error(document: CatalogFixtures.catalog([revoked]))
    assert_match(/advisories/i, error.message)
  end

  def test_rejects_malformed_permissions_and_permission_risk_mismatch
    mismatch = CatalogFixtures.entry
    mismatch["permissions"]["risk"] = "low"
    error = sync_error(document: CatalogFixtures.catalog([mismatch]))
    assert_match(/permission_risk/i, error.message)

    unsorted = CatalogFixtures.entry
    unsorted["permissions"]["capabilities"] = %w[filesystem-write filesystem-read]
    error = sync_error(document: CatalogFixtures.catalog([unsorted]))
    assert_match(/capabilities|sorted/i, error.message)

    wildcard = CatalogFixtures.entry(risk: "high")
    wildcard["permissions"]["network_hosts"] = ["*", "api.example.test"]
    error = sync_error(document: CatalogFixtures.catalog([wildcard]))
    assert_match(/network_hosts|wildcard/i, error.message)
  end

  def test_rejects_inconsistent_latest_versions_and_ambiguous_semver_precedence
    old = CatalogFixtures.entry(version: "1.0.0")
    latest = CatalogFixtures.entry(version: "1.2.0")
    error = sync_error(document: CatalogFixtures.catalog([old, latest]))
    assert_match(/latest_version/i, error.message)

    build_one = CatalogFixtures.entry(version: "1.0.0+one")
    build_two = CatalogFixtures.entry(version: "1.0.0+two")
    error = sync_error(document: CatalogFixtures.catalog([build_one, build_two]))
    assert_match(/ambiguous|precedence/i, error.message)
  end

  def test_rejects_incomplete_review_and_verified_evidence
    approval = CatalogFixtures.entry(risk: "high")
    approval["listing_approval"]["approved_by"] = ["maintainer-1"]
    error = sync_error(document: CatalogFixtures.catalog([approval]))
    assert_match(/approved_by|approvals/i, error.message)

    verified = CatalogFixtures.entry(tier: "verified")
    verified["verification"] = nil
    error = sync_error(document: CatalogFixtures.catalog([verified]))
    assert_match(/verification/i, error.message)
  end

  def test_failed_sync_preserves_last_known_good_snapshot_byte_for_byte
    Dir.mktmpdir do |directory|
      output_path = File.join(directory, "honeycombs.json")
      previous = "{\n  \"known\": \"good\"\n}\n"
      File.binwrite(output_path, previous)
      catalog_path = CatalogFixtures.write_catalog(directory, CatalogFixtures.catalog, raw: "{")

      assert_raises(HoneycombCatalogSync::Invalid) do
        sync_without_source_verification(catalog_path: catalog_path, source_sha: SOURCE_SHA, output_path: output_path)
      end
      assert_equal previous, File.binread(output_path)
    end
  end

  def test_requires_repository_root_catalog_name_and_full_pinned_commit_sha
    Dir.mktmpdir do |directory|
      wrong_path = File.join(directory, "snapshot.json")
      File.write(wrong_path, JSON.generate(CatalogFixtures.catalog))
      output_path = File.join(directory, "honeycombs.json")

      error = assert_raises(HoneycombCatalogSync::Invalid) do
        sync_without_source_verification(catalog_path: wrong_path, source_sha: SOURCE_SHA, output_path: output_path)
      end
      assert_match(/catalog\.json/, error.message)

      catalog_path = CatalogFixtures.write_catalog(directory, CatalogFixtures.catalog)
      error = assert_raises(HoneycombCatalogSync::Invalid) do
        sync_without_source_verification(catalog_path: catalog_path, source_sha: "abc123", output_path: output_path)
      end
      assert_match(/source SHA/i, error.message)
    end
  end

  def test_verifies_catalog_bytes_and_merged_commit_against_local_origin_main
    Dir.mktmpdir do |directory|
      run_git(directory, "init", "-q")
      run_git(directory, "config", "user.email", "tests@example.test")
      run_git(directory, "config", "user.name", "Honeycomb Tests")
      catalog_path = CatalogFixtures.write_catalog(directory, CatalogFixtures.catalog)
      run_git(directory, "add", "catalog.json")
      run_git(directory, "commit", "-qm", "catalog")
      source_sha = run_git(directory, "rev-parse", "HEAD").strip
      run_git(directory, "update-ref", "refs/remotes/origin/main", source_sha)
      output_path = File.join(directory, "honeycombs.json")

      HoneycombCatalogSync.sync!(catalog_path: catalog_path, source_sha: source_sha, output_path: output_path)
      assert File.file?(output_path)

      File.binwrite(catalog_path, JSON.generate(CatalogFixtures.catalog) + "\n")
      error = assert_raises(HoneycombCatalogSync::Invalid) do
        HoneycombCatalogSync.sync!(catalog_path: catalog_path, source_sha: source_sha, output_path: output_path)
      end
      assert_match(/do not match catalog\.json at source SHA/, error.message)

      File.binwrite(catalog_path, run_git(directory, "show", "#{source_sha}:catalog.json"))
      error = assert_raises(HoneycombCatalogSync::Invalid) do
        HoneycombCatalogSync.sync!(catalog_path: catalog_path, source_sha: "f" * 40, output_path: output_path)
      end
      assert_match(/not a commit/, error.message)
    end
  end

  private

  def sync_error(document: nil, raw: nil)
    Dir.mktmpdir do |directory|
      catalog_path = CatalogFixtures.write_catalog(directory, document, raw: raw)
      output_path = File.join(directory, "honeycombs.json")
      return assert_raises(HoneycombCatalogSync::Invalid) do
        sync_without_source_verification(catalog_path: catalog_path, source_sha: SOURCE_SHA, output_path: output_path)
      end
    end
  end

  def sync_without_source_verification(**options)
    HoneycombCatalogSync.stub(:source_verification_errors, []) do
      HoneycombCatalogSync.sync!(**options)
    end
  end

  def run_git(directory, *arguments)
    stdout, stderr, status = Open3.capture3("git", "-C", directory, *arguments)
    assert status.success?, "git #{arguments.join(" ")} failed: #{stderr}"
    stdout
  end
end
