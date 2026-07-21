# frozen_string_literal: true

require_relative "test_helper"

class HomepageExperienceTest < Minitest::Test
  include SiteTestHelpers
  def test_workflow_section_explains_what_how_and_why_in_semantic_order
    section = read("_includes/landing/pipeline.html")

    assert_includes section, 'id="how-it-works"'
    assert_includes section, '<ol class="workflow-explainer__steps">'
    assert_match(/reusable, ordered process/i, section)
    assert_match(/durable/i, section)
    assert_match(/checkpoint/i, section)
    assert_match(/retry|revision/i, section)
    assert_match(/human/i, section)
    assert_match(/single prompt/i, section)
    assert_match(/flagship.*coding/im, section)
    assert_match(/editorial/i, section)
    assert_match(/research|triage/i, section)
    assert_includes section, "{{ '/docs/concepts/' | relative_url }}"
    refute_includes section, "pipeline__stages"
    refute_match(/<img|aria-hidden/, section)
  end

  def test_workflow_section_has_isolated_responsive_and_focus_styles
    styles = read("assets/css/landing.scss")

    assert_includes styles, ".workflow-explainer__steps"
    assert_match(/\.workflow-explainer__cta:focus-visible/, styles)
    assert_match(/@media \(max-width: 600px\).*workflow-explainer__steps/m, styles)
    refute File.exist?(File.join(ROOT, "assets/img/pipeline-1-to-9.svg"))
  end

  def test_rendered_homepage_keeps_the_workflow_story_semantic
    with_built_site do |site|
      html = File.binread(File.join(site, "index.html"))
      section = html[/<section class="workflow-explainer".*?<\/section>/m]

      assert section
      assert_equal 1, html.scan(/<h1\b/).length
      assert_equal 1, section.scan(/<h2\b/).length
      steps = section[/<ol class="workflow-explainer__steps">.*?<\/ol>/m]
      assert steps
      assert_equal 4, steps.scan(/<li>/).length
      assert_includes section, 'href="/docs/concepts/"'
      refute_match(/<img|aria-hidden/, section)
    end
  end

  private

  def read(path)
    File.read(File.join(ROOT, path), encoding: "UTF-8")
  end
end
