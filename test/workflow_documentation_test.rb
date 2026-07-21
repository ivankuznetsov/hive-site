# frozen_string_literal: true

require "yaml"
require "cgi"
require "uri"
require_relative "test_helper"

class WorkflowDocumentationTest < Minitest::Test
  include SiteTestHelpers
  STABLE_HIVE_VERSION = "0.6.5"

  def test_site_and_command_pages_match_the_stable_workflow_surface
    config = YAML.safe_load(read("_config.yml"))
    init = read("docs/commands/init.md")
    new_command = read("docs/commands/new.md")
    approve = read("docs/commands/approve.md")
    command_index = read("docs/commands/index.md")
    operating = read("docs/operating.md")

    assert_equal STABLE_HIVE_VERSION, config.fetch("hive_version")
    assert_includes init, "--workflow <id>"
    assert_includes init, "--new-workflow <id>"
    assert_includes new_command, "--workflow <id>"
    assert_match(/coding\s+workflow starts at `1-inbox`.*`idea\.md`/m, new_command)
    assert_match(/editorial workflow.*`1-brief`.*`brief\.md`/m, new_command)
    assert_match(/0\.6\.5.*human capture summary.*do not expect a typed result/i, new_command)
    [command_index, operating].each do |page|
      assert_match(/command-specific/i, page)
      refute_match(/every (?:workflow )?(?:verb|command).*supports `--json`/i, page)
    end
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

  def test_editorial_descriptor_has_distinct_status_and_deliverable_files
    guide = read("docs/custom-workflows.md")
    descriptor = YAML.safe_load(fenced_block(guide, "editorial.yml", "yaml"))

    assert_equal "editorial", descriptor.fetch("id")
    stages = descriptor.fetch("stages")
    assert_equal %w[brief research draft approval done], stages.map { |stage| stage.fetch("name") }
    assert_equal %w[brief.md research-status.md draft-status.md approval-status.md done.md],
                 stages.map { |stage| stage.fetch("state_file") }
    assert_equal %w[terminal agent agent agent terminal], stages.map { |stage| stage.fetch("kind") }

    active = stages.select { |stage| stage.fetch("kind") == "agent" }
    assert_equal %w[./editorial/research.md ./editorial/draft.md ./editorial/approval.md],
                 active.map { |stage| stage.fetch("instruction") }
    active.each do |stage|
      assert_equal "claude", stage.fetch("agent")
      assert_equal "scoped", stage.dig("permissions", "preset")
    end
    assert_equal ["Read", "WebSearch", "WebFetch", "Edit(./**)"],
                 active.first.dig("permissions", "tools")
    active.drop(1).each do |stage|
      assert_equal ["Read", "Edit(./**)"], stage.dig("permissions", "tools")
    end

    %w[brief.md research.md draft.md decision.md publish-ready.md].each do |deliverable|
      assert_includes guide, deliverable
      refute_includes active.map { |stage| stage.fetch("state_file") }, deliverable
    end
  end

  def test_editorial_instructions_cover_wait_reject_revise_and_approve
    guide = read("docs/custom-workflows.md")
    research = fenced_block(guide, "editorial/research.md", "markdown")
    draft = fenced_block(guide, "editorial/draft.md", "markdown")
    approval = fenced_block(guide, "editorial/approval.md", "markdown")

    assert_includes research, "brief.md"
    assert_includes research, "research.md"
    assert_includes research, "research-status.md"
    assert_includes research, "WebSearch"
    assert_includes research, "WebFetch"
    assert_match(/not been\s+checked.*unknowns/im, research)
    assert_includes research, "<!-- COMPLETE -->"

    assert_includes draft, "research.md"
    assert_includes draft, "draft.md"
    assert_includes draft, "decision.md"
    assert_includes draft, "draft-status.md"
    assert_match(/rejected.*feedback/im, draft)

    assert_includes approval, "decision: pending"
    assert_includes approval, "decision: rejected"
    assert_includes approval, "decision: approved"
    assert_includes approval, "draft-status.md"
    assert_includes approval, "<!-- WAITING -->"
    assert_includes approval, "publish-ready.md"
    assert_includes approval, "selected_artifact"
    assert_includes approval, "approved_at"
    assert_includes approval, "sha256"
    assert_match(/Do not.*publish|no external/i, approval)
  end

  def test_editorial_guide_uses_stable_operator_paths_and_warns_about_mistakes
    guide = read("docs/custom-workflows.md")

    assert_includes guide, "hive workflow new editorial"
    assert_includes guide, "hive init --new-workflow editorial"
    assert_includes guide, "hive new my-project --workflow editorial"
    assert_includes guide, "hive approve <slug> --to draft"
    assert_includes guide, "sha256sum draft.md"
    assert_includes guide, "hive workflow list --json"
    refute_includes guide, "--to research --force"
    assert_match(/placeholder instruction/i, guide)
    assert_match(/`inbox → work → done`.*`idea\.md`/m, guide)
    assert_includes guide, "ruby -rbase64"
    assert_includes guide, "gem install base64 --no-document"
    assert_match(/vague outcome/i, guide)
    assert_match(/missing.*COMPLETE/i, guide)
    assert_match(/too many.*checkpoint/i, guide)
    assert_match(/nine-stage/i, guide)
    assert_match(/excessive permissions/i, guide)
    refute_match(/natural-language workflow creator|upcoming/i, guide)
    refute_match(/automatically publish|publishes? to (a )?(CMS|website|social)/i, guide)
  end

  def test_rendered_journey_raw_markdown_and_internal_links_stay_in_sync
    with_built_site do |site|
      docs_index = html(site, "docs/index.html")
      getting_started = html(site, "docs/getting-started/index.html")
      concepts = html(site, "docs/concepts/index.html")
      custom = html(site, "docs/custom-workflows/index.html")

      assert_includes docs_index, "Start with the workflow model"
      assert_includes docs_index, 'href="/docs/concepts/"'
      assert_includes docs_index, 'href="/docs/custom-workflows/"'
      assert_includes getting_started, "workflow definition"
      assert_includes getting_started, 'href="/docs/concepts/"'
      assert_includes getting_started, 'href="/docs/custom-workflows/"'

      assert_equal 1, concepts.scan(/<h1\b/).length
      assert_includes concepts, "Workflow definition"
      assert_includes concepts, 'href="/docs/custom-workflows/"'
      assert_includes concepts, 'href="/honeycombs/"'

      assert_equal 1, custom.scan(/<h1\b/).length
      assert_match(/class="language-yaml\b/, custom)
      assert_includes custom, "research-status.md"
      assert_includes custom, "publish-ready.md"
      assert_includes custom, 'href="/docs/concepts/"'
      refute_match(/workflow creator|upcoming/i, custom)

      concepts_raw = File.binread(File.join(site, "docs", "concepts.md"))
      custom_raw = File.binread(File.join(site, "docs", "custom-workflows.md"))
      llms_full = File.binread(File.join(site, "llms-full.txt"))
      [concepts_raw, custom_raw].each do |markdown|
        refute_match(/\A---/, markdown)
        refute_match(/\{\{|\{%|include\s+/, markdown)
      end
      assert_includes concepts_raw, "# How Hive workflows work"
      assert_includes custom_raw, "id: editorial"
      assert_includes custom_raw, "editorial/approval.md"
      assert_includes llms_full, "# How Hive workflows work"
      assert_includes llms_full, "# Creating custom workflows"

      affected_pages = %w[
        index.html
        docs/index.html
        docs/getting-started/index.html
        docs/concepts/index.html
        docs/custom-workflows/index.html
        docs/commands/index.html
        docs/commands/init/index.html
        docs/commands/new/index.html
        docs/commands/approve/index.html
      ]
      assert_internal_links_resolve(site, affected_pages)
    end
  end

  def test_docs_navigation_keeps_a_visible_keyboard_focus_indicator
    styles = read("_sass/custom/custom.scss")

    assert_match(/\.nav-list-link:focus-visible\s*\{[^}]*outline:\s*2px solid/m, styles)
  end

  private

  def read(path)
    File.read(File.join(ROOT, path), encoding: "UTF-8")
  end

  def html(site, relative_path)
    File.binread(File.join(site, relative_path))
  end

  def assert_internal_links_resolve(site, page_paths)
    page_paths.each do |page_path|
      document = html(site, page_path)
      document.scan(/\bhref=(['"])(.*?)\1/).each do |_quote, raw_href|
        href = CGI.unescapeHTML(raw_href)
        next if href.empty? || href.match?(/\A(?:https?:|mailto:|tel:|javascript:|data:|\/\/)/)

        resolved = URI.join("https://hive.test/#{page_path}", href)
        # Pagefind assets are generated after Jekyll by `npm run build`.
        next if resolved.path.start_with?("/pagefind/")

        target_path = resolved.path.sub(%r{\A/}, "")
        target_path = "index.html" if target_path.empty?
        target_path = File.join(target_path, "index.html") if target_path.end_with?("/")
        target = File.join(site, target_path)
        assert File.file?(target), "#{page_path} links to missing #{href} (#{target_path})"

        next if resolved.fragment.to_s.empty? || File.extname(target_path) != ".html"

        fragment = URI.decode_www_form_component(resolved.fragment)
        ids = File.binread(target).scan(/\bid=(['"])(.*?)\1/).map(&:last)
        assert_includes ids, fragment, "#{page_path} links to missing fragment #{href}"
      end
    end
  end

  def fenced_block(source, label, language)
    match = source.match(/^###\s+[^\n]*#{Regexp.escape(label)}[^\n]*\n.*?```#{language}\n(.*?)\n```/m)
    assert match, "missing #{language} block after #{label}"
    match[1]
  end
end
