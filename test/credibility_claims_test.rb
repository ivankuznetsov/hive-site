# frozen_string_literal: true

require "yaml"
require_relative "test_helper"

class CredibilityClaimsTest < Minitest::Test
  CURRENT_VERSION = "0.6.5"
  CATEGORY = "Hive is a durable, local-first workflow engine for AI agents."

  def test_release_and_category_metadata_match_the_current_public_product
    config = YAML.safe_load_file(File.join(ROOT, "_config.yml"), aliases: false)
    index = read("index.md")
    hero = read("_includes/landing/hero.html")

    assert_equal CURRENT_VERSION, config.fetch("hive_version")
    assert_includes config.fetch("description"), CATEGORY
    assert_includes index, "title: Hive — Run AI workflows that survive"
    assert_includes hero, "Run AI workflows that survive"
    assert_includes hero, CATEGORY
    assert_match(/pull requests,\s+research, content, audits, and operations/, hero)
    assert_includes hero, "Claude, Codex, Pi, and Grok"
  end

  def test_homepage_names_the_three_pillars_both_paths_and_sourced_capabilities
    cards = read("_includes/landing/cards.html")
    install = read("_includes/landing/install.html")

    %w[Durable\ execution Inspectable\ state Installable\ workflows Software\ workflows General\ workflows].each do |claim|
      assert_includes cards, claim.tr("\\", "")
    end
    assert_includes cards, "https://github.com/ivankuznetsov/hive/blob/main/docs/workflows.md"
    assert_includes cards, "https://github.com/ivankuznetsov/hive/blob/main/wiki/commands/web.md"
    assert_includes cards, "https://github.com/ivankuznetsov/hive-bench"
    assert_includes cards, "https://github.com/ivankuznetsov/honeycomb"
    assert_includes install, "openclaw skills install @ivankuznetsov/hive-cli"
  end

  def test_docs_match_current_workflows_web_and_agent_surfaces
    docs_index = read("docs/index.md")
    workflows = read("docs/custom-workflows.md")
    configuration = read("docs/configuration.md")
    faq = read("docs/faq.md")

    assert_includes docs_index, "`coding`, `content`, and `bench`"
    assert_includes workflows, "Hive ships three workflows out of the box"
    assert_includes workflows, "hive workflow install honeycomb/architecture --yes"
    assert_includes workflows, "hive workflow install honeycomb/writing --yes"
    assert_includes workflows, "hive workflow install honeycomb/seo-content --yes --allow-escalation"
    refute_includes workflows, "Hive ships with two workflows out of the box"
    refute_includes workflows, "last stage must be `kind: terminal`"
    refute_includes workflows, "`writing` | `inbox → research → draft → edit → done`"
    assert_includes configuration, "`claude`, `codex`, `pi`, and `grok`"
    assert_includes faq, "hive web"
    refute_includes faq, "Why no built-in web UI?"
  end

  def test_public_templates_have_a_privacy_minimal_baseline
    paths = Dir.glob(File.join(ROOT, "{_includes,_layouts,assets/js}", "**", "*"))
               .select { |path| File.file?(path) }
    text = paths.map { |path| File.binread(path) }.join("\n")

    refute_match(/googletagmanager|google-analytics|plausible\.io|posthog|segment\.com/i, text)
  end

  private

  def read(path)
    File.read(File.join(ROOT, path), encoding: Encoding::UTF_8)
  end
end
