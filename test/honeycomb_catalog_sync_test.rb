# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/honeycomb_catalog_sync"

class HoneycombCatalogSyncTest < Minitest::Test
  def test_accepts_the_complete_empty_catalog
    document = HoneycombCatalogSync.validate_payload!(JSON.pretty_generate(CatalogFixtures.catalog) + "\n")

    assert_equal "honeycomb-catalog/v2", document.fetch("schema")
    assert_empty document.fetch("entries")
  end

  def test_accepts_complete_entries_across_tiers_lifecycles_permissions_and_semver
    prerelease = CatalogFixtures.entry(name: "alpha-tool", version: "1.0.0-beta.1")
    release = CatalogFixtures.entry(
      name: "alpha-tool", version: "1.0.0", tier: "verified", risk: "high",
      community_reviews: "https://github.com/ivankuznetsov/honeycomb/tree/main/reviews/alpha-tool/1.0.0"
    )
    prerelease["latest_version"] = "1.0.0"
    hidden = CatalogFixtures.entry(name: "hidden-tool", state: "soft_hidden")
    revoked = CatalogFixtures.entry(name: "revoked-tool", state: "revoked")
    yanked = CatalogFixtures.entry(name: "yanked-tool", state: "yanked")

    document = validate(CatalogFixtures.catalog([prerelease, release, hidden, revoked, yanked]))

    assert_equal %w[alpha-tool alpha-tool hidden-tool revoked-tool yanked-tool],
                 document.fetch("entries").map { |entry| entry.fetch("name") }
  end

  def test_rejects_malformed_utf8_json_and_duplicate_keys
    malformed_utf8 = "{\"schema\":\"honeycomb-catalog/v2\",\"entries\":[]}".b << "\xFF".b
    variants = {
      "UTF-8" => malformed_utf8,
      "malformed JSON" => "{",
      "duplicate JSON key" => "{\"schema\":\"honeycomb-catalog/v2\",\"schema\":\"honeycomb-catalog/v2\",\"entries\":[]}"
    }

    variants.each do |label, bytes|
      error = assert_raises(HoneycombCatalogSync::ValidationError) do
        HoneycombCatalogSync.validate_payload!(bytes)
      end
      assert_match(/#{Regexp.escape(label)}/i, error.message)
    end
  end

  def test_schema_rejects_wrong_versions_unknown_fields_missing_fields_types_and_enums
    variants = {
      "$.schema" => {"schema" => "honeycomb-catalog/v1", "entries" => []},
      "$.extra" => CatalogFixtures.catalog.merge("extra" => true),
      "$.entries" => {"schema" => "honeycomb-catalog/v2"},
      "$.entries[0].author.extra" => mutate_entry { |entry| entry.fetch("author")["extra"] = true },
      "$.entries[0].permissions.risk" => mutate_entry { |entry| entry.fetch("permissions").delete("risk") },
      "$.entries[0].discoverable" => mutate_entry { |entry| entry["discoverable"] = "yes" },
      "$.entries[0].current_tier" => mutate_entry { |entry| entry["current_tier"] = "official" }
    }

    variants.each do |path, document|
      error = validation_error(document)
      assert_includes error.message, path, "expected path #{path} in #{error.message}"
    end
  end

  def test_schema_rejects_invalid_names_semver_dates_digests_and_nested_evidence
    variants = {
      "name" => mutate_entry { |entry| entry["name"] = "bad;name" },
      "version" => mutate_entry { |entry| entry["version"] = "01.0.0" },
      "lint_checked_at" => mutate_entry { |entry| entry.dig("listing_approval")["lint_checked_at"] = "yesterday" },
      "release_sha256" => mutate_entry { |entry| entry.dig("listing_approval")["release_sha256"] = "abc" },
      "reviewed_at" => mutate_entry { |entry| entry.dig("listing_approval", "reviews", 0)["reviewed_at"] = "soon" },
      "verification" => mutate_entry(tier: "verified") { |entry| entry.fetch("verification").delete("attestation") },
      "history" => mutate_entry(state: "soft_hidden") { |entry| entry.fetch("history").first["kind"] = "other" },
      "advisories" => mutate_entry(state: "revoked") { |entry| entry.fetch("advisories").first["severity"] = "maximum" }
    }

    variants.each do |field, document|
      assert_match(/#{Regexp.escape(field)}/i, validation_error(document).message)
    end
  end

  def test_rejects_duplicate_identity_noncanonical_order_and_ambiguous_precedence
    duplicate = CatalogFixtures.entry
    assert_match(/duplicate name\/version/, validation_error(
      CatalogFixtures.catalog([duplicate, CatalogFixtures.deep_copy(duplicate)])
    ).message)

    alpha = CatalogFixtures.entry(name: "alpha-tool")
    zulu = CatalogFixtures.entry(name: "zulu-tool")
    assert_match(/canonical name-then-SemVer order/, validation_error(
      CatalogFixtures.catalog([zulu, alpha])
    ).message)

    old = CatalogFixtures.entry(name: "versioned-tool", version: "1.0.0")
    new = CatalogFixtures.entry(name: "versioned-tool", version: "1.1.0")
    old["latest_version"] = "1.1.0"
    new["latest_version"] = "1.1.0"
    assert_match(/canonical name-then-SemVer order/, validation_error(
      CatalogFixtures.catalog([new, old])
    ).message)

    one = CatalogFixtures.entry(name: "versioned-tool", version: "1.0.0+one")
    two = CatalogFixtures.entry(name: "versioned-tool", version: "1.0.0+two")
    assert_match(/ambiguous SemVer precedence/, validation_error(
      CatalogFixtures.catalog([one, two])
    ).message)
  end

  def test_rejects_incoherent_latest_versions
    old = CatalogFixtures.entry(name: "versioned-tool", version: "1.0.0")
    latest = CatalogFixtures.entry(name: "versioned-tool", version: "1.2.0")
    assert_match(/latest_version must be "1.2.0"/, validation_error(
      CatalogFixtures.catalog([old, latest])
    ).message)

    hidden = CatalogFixtures.entry(name: "hidden-tool", state: "soft_hidden")
    hidden["latest_version"] = "1.0.0"
    assert_match(/latest_version must be nil/, validation_error(CatalogFixtures.catalog([hidden])).message)

    listed = CatalogFixtures.entry(name: "versioned-tool", version: "1.0.0")
    hidden = CatalogFixtures.entry(name: "versioned-tool", version: "2.0.0", state: "yanked")
    hidden["latest_version"] = "2.0.0"
    assert_match(/latest_version must be "1.0.0"/, validation_error(
      CatalogFixtures.catalog([listed, hidden])
    ).message)
  end

  def test_rejects_every_lifecycle_discoverability_and_resolution_conflict
    {
      "listed" => [false, "allowed"],
      "soft_hidden" => [true, "allowed"],
      "yanked" => [true, "allowed"],
      "revoked" => [false, "allowed"]
    }.each do |state, (discoverable, resolution)|
      entry = CatalogFixtures.entry(state: state)
      entry["discoverable"] = discoverable
      entry["exact_resolution"] = resolution
      assert_match(/discoverable|exact_resolution/, validation_error(CatalogFixtures.catalog([entry])).message)
    end
  end

  def test_rejects_unsafe_urls_in_every_url_bearing_branch
    url_paths = [
      %w[author url], %w[package_url], %w[reviews_url], %w[community_reviews_url],
      %w[listing_approval reviews 0 review_url], %w[verification signature identity],
      %w[verification signature issuer], %w[verification signature url],
      %w[verification attestation url], %w[history 0 url], %w[advisories 0 url]
    ]

    url_paths.each do |segments|
      entry = CatalogFixtures.entry(
        tier: "verified", state: "revoked",
        community_reviews: "https://github.com/ivankuznetsov/honeycomb/tree/main/reviews/example/1.0.0"
      )
      assign(entry, segments, "http://user@example.test/unsafe\n")
      error = validation_error(CatalogFixtures.catalog([entry]))
      assert_match(/#{Regexp.escape(segments.last)}|HTTPS|uri/i, error.message,
                   "expected rejection for #{segments.join('.')} but got #{error.message}")
    end
  end

  def test_rejects_noncanonical_install_package_and_review_links
    command = CatalogFixtures.entry
    command["install_command"] = "hive workflow install honeycomb/other"
    assert_match(/install_command/, validation_error(CatalogFixtures.catalog([command])).message)

    package = CatalogFixtures.entry
    package["package_url"] = "https://github.com/ivankuznetsov/honeycomb/tree/#{'a' * 40}/packages/example/1.0.0"
    assert_match(/package_url/, validation_error(CatalogFixtures.catalog([package])).message)

    review = CatalogFixtures.entry
    review["reviews_url"] = "https://example.test/other-review"
    assert_match(/reviews_url/, validation_error(CatalogFixtures.catalog([review])).message)

    community = CatalogFixtures.entry(community_reviews: "https://example.test/reviews/example/1.0.0")
    assert_match(/community_reviews_url/, validation_error(CatalogFixtures.catalog([community])).message)

    missing_review = CatalogFixtures.entry
    missing_review.fetch("listing_approval")["reviews"] = []
    assert_match(/designated review/, validation_error(CatalogFixtures.catalog([missing_review])).message)
  end

  def test_rejects_malformed_permissions_unknown_capabilities_and_risk_mismatch
    variants = {
      "permission_risk" => mutate_entry { |entry| entry.fetch("permissions")["risk"] = "low" },
      "normalized" => mutate_entry { |entry| entry.dig("permissions", "filesystem_read") << " spaced " },
      "sorted" => mutate_entry { |entry| entry.fetch("permissions")["capabilities"] = %w[network filesystem-read] },
      "unique" => mutate_entry { |entry| entry.fetch("permissions")["secrets"] = %w[TOKEN TOKEN] },
      "wildcard" => mutate_entry { |entry| entry.fetch("permissions")["network_hosts"] = ["*", "api.example.test"] },
      "unknown" => mutate_entry { |entry| entry.fetch("permissions")["capabilities"] = ["database-admin"] }
    }

    variants.each do |label, document|
      assert_match(/#{label}|permissions|permission_risk/i, validation_error(document).message)
    end
  end

  def test_does_not_duplicate_producer_only_review_history_or_verification_policy
    high_risk = CatalogFixtures.entry(tier: "verified", risk: "high", state: "revoked")
    approval = high_risk.fetch("listing_approval")
    approval["approved_by"] = ["different-reviewer"]
    approval["approved_at"] = "2020-01-01T00:00:00Z"
    approval["reviews"] = [approval.fetch("reviews").first]
    high_risk["reviews_url"] = approval.dig("reviews", 0, "review_url")
    high_risk["history"] = []
    high_risk["advisories"] = []
    high_risk["verification"]["signature"]["identity"] = "https://example.test/valid-but-not-producer-coherent"

    assert_equal high_risk, validate(CatalogFixtures.catalog([high_risk])).fetch("entries").first
  end

  def test_source_verification_accepts_canonical_https_and_ssh_origin_forms
    [
      "https://github.com/ivankuznetsov/honeycomb.git",
      "git@github.com:ivankuznetsov/honeycomb.git",
      "ssh://git@github.com/ivankuznetsov/honeycomb.git"
    ].each do |origin|
      in_source_repo(origin: origin) do |root, catalog_path, source_sha|
        assert_equal root, HoneycombCatalogSync.validate_source!(catalog_path: catalog_path, source_sha: source_sha)
      end
    end
  end

  def test_source_verification_rejects_nonroot_fork_missing_unmerged_and_changed_inputs
    in_source_repo do |root, catalog_path, source_sha|
      run_git(root, "remote", "set-url", "origin", "https://github.com/example/honeycomb.git")
      assert_match(/canonical.*origin/i, source_error(catalog_path, source_sha).message)

      run_git(root, "remote", "set-url", "origin", "https://github.com/ivankuznetsov/honeycomb.git")
      nested = File.join(root, "nested", "catalog.json")
      FileUtils.mkdir_p(File.dirname(nested))
      File.binwrite(nested, File.binread(catalog_path))
      assert_match(/repository root/i, source_error(nested, source_sha).message)

      assert_match(/not a commit/i, source_error(catalog_path, "f" * 40).message)

      File.binwrite(File.join(root, "marker"), "new")
      run_git(root, "add", "marker")
      run_git(root, "commit", "-qm", "unmerged")
      unmerged_sha = run_git(root, "rev-parse", "HEAD").strip
      assert_match(/not merged.*origin\/main/i, source_error(catalog_path, unmerged_sha).message)

      File.binwrite(catalog_path, JSON.generate(CatalogFixtures.catalog) + "\n")
      assert_match(/bytes do not match/i, source_error(catalog_path, source_sha).message)
    end
  end

  def test_source_verification_is_local_only
    source = File.read(File.join(ROOT, "lib", "honeycomb_catalog_sync.rb"))

    refute_match(/\bgit[^\n]*\bfetch\b|Net::HTTP|URI\.open|open-uri/, source)
  end

  def test_committed_snapshot_is_the_exact_valid_catalog_v2_shape
    bytes = File.binread(HoneycombCatalogSync::DEFAULT_OUTPUT_PATH)
    document = HoneycombCatalogSync.validate_payload!(bytes)

    assert_equal %w[entries schema], document.keys.sort
    assert_equal "honeycomb-catalog/v2", document.fetch("schema")
    assert_empty document.fetch("entries")
    refute_includes bytes, "hive-site-honeycombs"
    refute_includes bytes, "generated_at"
  end

  def test_sync_copies_exact_upstream_bytes_deterministically
    in_source_repo do |_root, catalog_path, source_sha|
      Dir.mktmpdir do |output_root|
        output_path = File.join(output_root, "honeycombs.json")
        expected = File.binread(catalog_path)

        first = HoneycombCatalogSync.sync!(
          catalog_path: catalog_path, source_sha: source_sha, output_path: output_path
        )
        first_bytes = File.binread(output_path)
        second = HoneycombCatalogSync.sync!(
          catalog_path: catalog_path, source_sha: source_sha, output_path: output_path
        )

        assert_equal expected, first_bytes
        assert_equal expected, File.binread(output_path)
        assert_equal CatalogFixtures.catalog, first
        assert_equal first, second
      end
    end
  end

  def test_source_and_validation_failures_preserve_snapshot_bytes_mode_and_tempfiles
    failures = [
      ["source", CatalogFixtures.catalog, ->(root, _path) {
        run_git(root, "remote", "set-url", "origin", "https://github.com/example/honeycomb.git")
      }, HoneycombCatalogSync::SourceError],
      ["malformed", nil, ->(_root, _path) {}, HoneycombCatalogSync::ValidationError, "{"],
      ["unsafe", mutate_entry { |entry| entry["author"]["url"] = "javascript:alert(1)" },
       ->(_root, _path) {}, HoneycombCatalogSync::ValidationError]
    ]

    failures.each do |label, document, setup, error_class, raw|
      in_source_repo(document: document, raw: raw) do |root, catalog_path, source_sha|
        setup.call(root, catalog_path)
        output_path = File.join(root, "last-known-good.json")
        previous = "{\n  \"known\": \"good\"\n}\n"
        File.binwrite(output_path, previous)
        File.chmod(0o600, output_path)

        assert_raises(error_class, label) do
          HoneycombCatalogSync.sync!(
            catalog_path: catalog_path, source_sha: source_sha, output_path: output_path
          )
        end
        assert_equal previous, File.binread(output_path), label
        assert_equal 0o600, File.stat(output_path).mode & 0o777, label
        assert_empty Dir.glob(File.join(root, ".honeycombs*.json")), label
      end
    end
  end

  def test_rename_failure_preserves_snapshot_and_cleans_temporary_file
    in_source_repo do |root, catalog_path, source_sha|
      output_path = File.join(root, "last-known-good.json")
      previous = "last known good\n"
      File.binwrite(output_path, previous)
      File.chmod(0o640, output_path)

      error = assert_raises(HoneycombCatalogSync::WriteError) do
        File.stub(:rename, ->(*) { raise Errno::EACCES, "simulated rename failure" }) do
          HoneycombCatalogSync.sync!(
            catalog_path: catalog_path, source_sha: source_sha, output_path: output_path
          )
        end
      end

      assert_match(/rename failure|Permission denied/i, error.message)
      assert_equal previous, File.binread(output_path)
      assert_equal 0o640, File.stat(output_path).mode & 0o777
      assert_empty Dir.glob(File.join(root, ".honeycombs*.json"))
    end
  end

  def test_command_reports_distinct_usage_source_and_validation_failures
    _stdout, stderr, status = run_sync_command
    assert_equal 2, status.exitstatus
    assert_match(/Usage: script\/sync-honeycombs/, stderr)

    in_source_repo do |root, catalog_path, source_sha|
      run_git(root, "remote", "set-url", "origin", "https://github.com/example/honeycomb.git")
      _stdout, stderr, status = run_sync_command("--catalog", catalog_path, "--source-sha", source_sha)
      assert_equal 3, status.exitstatus
      assert_match(/source:/, stderr)
    end

    unsafe = mutate_entry { |entry| entry["author"]["url"] = "javascript:alert(1)" }
    in_source_repo(document: unsafe) do |_root, catalog_path, source_sha|
      _stdout, stderr, status = run_sync_command("--catalog", catalog_path, "--source-sha", source_sha)
      assert_equal 4, status.exitstatus
      assert_match(/validation:/, stderr)
    end
  end

  def test_jekyll_hook_rejects_directly_corrupted_snapshots_before_catalog_output
    unsafe = CatalogFixtures.entry
    unsafe["author"]["url"] = "javascript:alert(1)"
    status, destination, output = build_with_snapshot(CatalogFixtures.catalog([unsafe]))
    refute status.success?, output
    refute File.exist?(File.join(destination, "honeycombs", "index.html"))
    assert_match(/Honeycomb catalog snapshot is invalid|safe absolute HTTPS/, output)

    incoherent = CatalogFixtures.entry
    incoherent["discoverable"] = false
    status, destination, output = build_with_snapshot(CatalogFixtures.catalog([incoherent]))
    refute status.success?, output
    refute File.exist?(File.join(destination, "honeycombs", "index.html"))
    assert_match(/discoverable/, output)

    status, destination, output = build_with_snapshot(CatalogFixtures.catalog)
    assert status.success?, output
    assert File.file?(File.join(destination, "honeycombs", "index.html"))
  end

  def test_jekyll_hook_performs_payload_validation_without_git_or_network
    hook = File.read(File.join(ROOT, "_plugins", "honeycomb_catalog_validator.rb"))

    assert_includes hook, "validate_payload!"
    refute_match(/validate_source|Open3|Net::HTTP|fetch\s*\(/, hook)
  end

  private

  def validate(document)
    HoneycombCatalogSync.validate_payload!(JSON.pretty_generate(document) + "\n")
  end

  def validation_error(document)
    assert_raises(HoneycombCatalogSync::ValidationError) { validate(document) }
  end

  def mutate_entry(**options)
    entry = CatalogFixtures.entry(**options)
    yield entry
    CatalogFixtures.catalog([entry])
  end

  def assign(document, segments, value)
    parent = segments[0...-1].reduce(document) do |cursor, segment|
      segment.match?(/\A\d+\z/) ? cursor.fetch(segment.to_i) : cursor.fetch(segment)
    end
    key = segments.last
    key.match?(/\A\d+\z/) ? parent[key.to_i] = value : parent[key] = value
  end

  def in_source_repo(origin: "https://github.com/ivankuznetsov/honeycomb.git",
                     document: CatalogFixtures.catalog, raw: nil)
    Dir.mktmpdir do |root|
      run_git(root, "init", "-q")
      run_git(root, "config", "user.email", "tests@example.test")
      run_git(root, "config", "user.name", "Honeycomb Tests")
      run_git(root, "remote", "add", "origin", origin)
      catalog_path = CatalogFixtures.write_catalog(root, document, raw: raw)
      run_git(root, "add", "catalog.json")
      run_git(root, "commit", "-qm", "catalog")
      source_sha = run_git(root, "rev-parse", "HEAD").strip
      run_git(root, "update-ref", "refs/remotes/origin/main", source_sha)
      yield root, catalog_path, source_sha
    end
  end

  def source_error(catalog_path, source_sha)
    assert_raises(HoneycombCatalogSync::SourceError) do
      HoneycombCatalogSync.validate_source!(catalog_path: catalog_path, source_sha: source_sha)
    end
  end

  def run_git(directory, *arguments)
    stdout, stderr, status = Open3.capture3("git", "-C", directory, *arguments)
    assert status.success?, "git #{arguments.join(' ')} failed: #{stderr}"
    stdout
  end

  def run_sync_command(*arguments)
    env = {"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"), "BUNDLE_PATH" => File.join(ROOT, "vendor", "bundle")}
    Open3.capture3(env, RbConfig.ruby, File.join(ROOT, "script", "sync-honeycombs"), *arguments)
  end

  def build_with_snapshot(snapshot)
    directory = Dir.mktmpdir
    source = File.join(directory, "source")
    destination = File.join(directory, "site")
    FileUtils.mkdir_p(source)
    entries = Dir.children(ROOT) - %w[.git .jekyll-cache .sass-cache _site node_modules test vendor]
    entries.each { |entry| FileUtils.cp_r(File.join(ROOT, entry), source) }
    File.binwrite(File.join(source, "_data", "honeycombs.json"), JSON.pretty_generate(snapshot) + "\n")

    env = {"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"), "BUNDLE_PATH" => File.join(ROOT, "vendor", "bundle"),
           "JEKYLL_ENV" => "test"}
    command = [RbConfig.ruby, Gem.bin_path("bundler", "bundle"), "exec", "jekyll", "build",
               "--source", source, "--destination", destination, "--quiet"]
    stdout, stderr, status = Open3.capture3(env, *command)
    [status, destination, "#{stdout}\n#{stderr}"]
  end
end
