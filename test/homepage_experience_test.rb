# frozen_string_literal: true

require_relative "test_helper"

class HomepageExperienceTest < Minitest::Test
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

  private

  def read(path)
    File.read(File.join(ROOT, path), encoding: "UTF-8")
  end
end
