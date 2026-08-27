# frozen_string_literal: true

require "yaml"
require_relative "test_helper"

class LaunchPathsTest < Minitest::Test
  PATH_IDS = %w[build content].freeze
  STATE_LABELS = {
    "launch" => "Add idea",
    "queued" => "Queued for the daemon",
    "running" => "Agent running",
    "approval_waiting" => "Needs your input",
    "provider_limit" => "Waiting on provider / scheduler",
    "recoverable_failure" => "Needs recovery",
    "terminal_failure" => "Error",
    "success" => "Archived",
    "artifact_inspection" => "Artifacts",
    "retry_resume" => "Retry stage",
    "next_action" => "Next action"
  }.freeze

  def test_build_and_content_are_individually_shareable
    PATH_IDS.each do |id|
      page = read("#{id}/index.md")

      assert_includes page, "layout: home"
      assert_includes page, "permalink: /#{id}/"
      assert_match(/^title: .+$/i, page)
      assert_match(/^description: .+$/i, page)
      assert_match(%r{^image: /assets/img/#{id}-og\.png$}i, page)
      assert_includes page, "{% include launch-path.html path_id=\"#{id}\" %}"
      assert File.file?(File.join(ROOT, "assets/img/#{id}-og.png")), "missing #{id} share image"
    end
  end

  def test_first_run_guide_and_primary_navigation_link_both_paths
    guide = read("docs/first-run.md")
    layout = read("_layouts/home.html")
    homepage_paths = read("_includes/landing/paths.html")

    PATH_IDS.each do |id|
      assert_includes guide, "{{ '/#{id}/' | relative_url }}"
      assert_includes layout, "{{ '/#{id}/' | relative_url }}"
      assert_includes homepage_paths, "{{ '/#{id}/' | relative_url }}"
    end
  end

  def test_path_data_uses_the_native_state_vocabulary
    data = YAML.safe_load_file(File.join(ROOT, "_data/launch_paths.yml"), aliases: false)

    assert_equal STATE_LABELS, data.fetch("state_labels")
    assert_equal PATH_IDS, data.fetch("paths").keys
    data.fetch("paths").each_value do |path|
      assert_equal STATE_LABELS.keys, path.fetch("journey").keys
      assert_equal "deterministic_fixture", path.fetch("evidence").fetch("sample_status")
      assert_equal "not_completed", path.fetch("evidence").fetch("live_full_replay_status")
      assert_equal "2026-07-21T15:23:25Z", path.fetch("evidence").fetch("observed_at")
      assert_nil path.fetch("evidence").fetch("live_first_artifact_time")
      assert_nil path.fetch("evidence").fetch("measured_full_completion_time")
    end
  end

  def test_fixture_copy_discloses_the_live_verification_gap_without_private_material
    data = YAML.safe_load_file(File.join(ROOT, "_data/launch_paths.yml"), aliases: false)
    include_body = read("_includes/launch-path.html")
    guide = read("docs/first-run.md")
    content = data.fetch("paths").fetch("content")
    blocker = content.fetch("evidence").fetch("blocker")

    assert_includes blocker, "Hive 0.6.4"
    assert_includes blocker, "key not found: &quot;approve&quot;"
    assert_includes blocker, "initially failed before research"
    assert_includes blocker, "recovered the tasks"
    assert_includes blocker, "2026-07-21T15:23:25Z"
    assert_includes blocker, "provider budget"
    assert_includes blocker, "single bounded retry"
    assert_includes include_body, "Deterministic fixture"
    assert_includes include_body, "not a provider-completion or timing claim"
    assert_includes guide, "five-minute acceptance target"
    assert_includes guide, "not yet verified"
    refute_match(/task \d+|[0-9a-f]{8}-[0-9a-f-]{27,}|\$\d|\d[\d,]+-byte|write-(?:a-supporting|the-canonical)-launch/i, blocker)
  end

  def test_copyable_commands_preserve_the_full_sample_guardrails
    include_body = read("_includes/launch-path.html")
    guide = read("docs/first-run.md")
    data = YAML.safe_load_file(File.join(ROOT, "_data/launch_paths.yml"), aliases: false)

    assert_includes include_body, "hive new . {{ path.sample_input | jsonify }}"
    refute_includes include_body, "path.launch_command"
    assert_includes include_body, "hive setup --service"
    assert_includes guide, "hive setup --service"
    assert_includes data.dig("paths", "build", "sample_input"), "never expose environment variables or secrets"
    assert_includes data.dig("paths", "content", "sample_input"), "stop at a reviewable article"
  end

  def test_every_example_and_state_contract_has_public_source_evidence
    data = YAML.safe_load_file(File.join(ROOT, "_data/launch_paths.yml"), aliases: false)
    revision = data.fetch("hive_source_revision")

    assert_match(/\A[0-9a-f]{40}\z/, revision)

    data.fetch("paths").each_value do |path|
      path.fetch("sources").each_value do |url|
        assert_match(%r{\Ahttps://github\.com/ivankuznetsov/hive/(?:blob|tree)/}, url)
      end
      assert_includes path.dig("sources", "walkthrough"), "/blob/#{revision}/docs/launch-paths.md"
      path.fetch("artifacts").each do |artifact|
        assert_includes artifact.fetch("url"), "/blob/#{revision}/docs/fixtures/launch-paths/"
      end
    end
  end

  private

  def read(path)
    File.read(File.join(ROOT, path), encoding: Encoding::UTF_8)
  end
end
