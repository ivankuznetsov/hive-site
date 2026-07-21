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

  def test_concepts_defines_the_general_model_before_the_flagship_example
    concepts = read("docs/concepts.md")

    assert_includes concepts, "title: How workflows work"
    assert_includes concepts, "permalink: /docs/concepts/"
    %w[Project Workflow Task Stage Agent Artifact Marker Checkpoint Outcome Honeycomb].each do |term|
      assert_match(/\*\*#{term}[^*]*\*\*/i, concepts, "missing vocabulary definition for #{term}")
    end

    vocabulary = concepts.index("## Vocabulary")
    runtime = concepts.index("## How a task run moves")
    flagship = concepts.index("## The flagship coding workflow")
    assert vocabulary && runtime && flagship
    assert_operator vocabulary, :<, runtime
    assert_operator runtime, :<, flagship

    %w[advance pause retry revision].each { |outcome| assert_match(/#{outcome}/i, concepts) }
    assert_match(/durable files.*resum/i, concepts)
    assert_match(/recorded transitions.*audit/i, concepts)
    assert_match(/agent.*model.*stage/i, concepts)
    assert_match(/built-in.*project-local.*Honeycomb/im, concepts)
    assert_includes concepts, "{{ '/docs/custom-workflows/' | relative_url }}"
    assert_includes concepts, "{{ '/honeycombs/' | relative_url }}"
  end

  private

  def read(path)
    File.read(File.join(ROOT, path), encoding: "UTF-8")
  end
end
