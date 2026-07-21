# frozen_string_literal: true

require "yaml"
require_relative "test_helper"

class WorkflowDocumentationTest < Minitest::Test
  STABLE_HIVE_VERSION = "0.6.5"

  def test_site_and_command_pages_match_the_stable_workflow_surface
    config = YAML.safe_load(read("_config.yml"))
    init = read("docs/commands/init.md")
    new_command = read("docs/commands/new.md")
    approve = read("docs/commands/approve.md")

    assert_equal STABLE_HIVE_VERSION, config.fetch("hive_version")
    assert_includes init, "--workflow <id>"
    assert_includes init, "--new-workflow <id>"
    assert_includes new_command, "--workflow <id>"
    assert_includes approve, "--to <stage>"
    assert_match(/forward or back/i, approve)
  end

  def test_custom_workflow_guide_names_only_stable_templates
    guide = read("docs/custom-workflows.md")

    assert_includes guide, "available: blank, research"
    refute_match(/`writing`\s*\|/, guide)
    refute_includes guide, "--template writing"
  end

  private

  def read(path)
    File.read(File.join(ROOT, path), encoding: "UTF-8")
  end
end
