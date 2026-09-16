# frozen_string_literal: true

require_relative "test_helper"

class HomepageExperienceTest < Minitest::Test
  MAIN_ORDER = %w[hero proof cards paths cta].freeze

  def test_no_javascript_narrative_uses_the_authoritative_section_order
    homepage = read("index.md")
    positions = MAIN_ORDER.map do |name|
      needle = "{% include landing/#{name}.html %}"
      [name, homepage.index(needle)]
    end

    positions.each { |name, position| refute_nil position, "missing #{name} section" }
    assert_equal positions.map(&:last).sort, positions.map(&:last)
  end

  def test_linked_proof_precedes_breadth_and_covers_the_public_evidence_contract
    proof = read("_includes/landing/proof.html")

    assert_equal 4, proof.scan(/<article\b/).length
    assert_includes proof, "36 reproducible runs"
    assert_includes proof, "Real PRs and inspectable artifacts"
    assert_includes proof, "Adversarial review and recovery"
    assert_includes proof, "Dogfood reports and limitations"
    assert_includes proof, "{{ '/bench/methodology/' | relative_url }}"
    assert_includes proof, "https://github.com/ivankuznetsov/hive/blob/main/docs/recipes.md"
    assert_includes proof, "https://github.com/ivankuznetsov/hive/tree/main/docs/dogfood-reports"
  end

  def test_three_pillars_and_two_workflow_paths_are_distinct
    pillars = read("_includes/landing/cards.html")
    paths = read("_includes/landing/paths.html")

    assert_equal 3, pillars.scan(/<article\b/).length
    %w[Durable\ execution Inspectable\ state Installable\ workflows].each do |label|
      assert_includes pillars, label.tr("\\", "")
    end

    assert_equal 2, paths.scan(/<article\b/).length
    assert_includes paths, "Software workflows"
    assert_includes paths, "General workflows"
    assert_includes paths, "flagship proof"
    assert_includes paths, "content"
    assert_includes paths, "bench"
  end

  def test_cta_has_one_primary_action_and_descriptive_secondary_routes
    cta = read("_includes/landing/cta.html")

    assert_equal 1, cta.scan(/btn--primary/).length
    assert_includes cta, "Install and run Hive"
    assert_includes cta, "Explore Hive workflows"
    assert_includes cta, "Inspect the public proof"
    assert_includes cta, "View Hive on GitHub"
    refute_match(/>\s*(read more|learn more|click here)\s*</i, cta)
  end

  def test_semantics_keyboard_motion_touch_and_visual_alternatives_are_explicit
    layout = read("_layouts/home.html")
    proof = read("_includes/landing/proof.html")
    demo = read("_includes/landing/demo.html")
    styles = read("assets/css/landing.scss")

    assert_includes layout, '<a class="skip-link" href="#main">'
    assert_includes layout, '<nav class="site-nav" aria-label="Primary">'
    assert_includes layout, '<main id="main">'
    assert_includes proof, 'aria-labelledby="proof-title"'
    assert_includes proof, '<h2 class="section-title" id="proof-title">'
    assert_includes styles, ":focus-visible"
    assert_match(/\.btn\s*\{[^}]*min-height:\s*44px/m, styles)
    assert_match(/\.site-nav a\s*\{[^}]*min-height:\s*44px/m, styles)
    assert_match(/@media\s*\(prefers-reduced-motion:\s*reduce\)/, styles)
    refute_match(/\.site-nav a:not\(\.btn\)\s*\{\s*display:\s*none/, styles)

    assert_match(/<video[^>]*\bcontrols\b/, demo)
    refute_match(/<video[^>]*\bautoplay\b/, demo)
    refute_match(/<video[^>]*\bloop\b/, demo)
    assert_includes demo, '<details class="demo__transcript"'
    assert_includes demo, "Read the demo transcript"
  end

  def test_text_palette_meets_wcag_aa_contrast
    styles = read("assets/css/landing.scss")
    tokens = styles.scan(/--([\w-]+):\s*(#[0-9a-f]{6})/i).to_h

    assert_operator contrast(tokens.fetch("text"), tokens.fetch("bg")), :>=, 4.5
    assert_operator contrast(tokens.fetch("muted"), tokens.fetch("bg")), :>=, 4.5
    assert_operator contrast(tokens.fetch("text"), tokens.fetch("surface")), :>=, 4.5
    assert_operator contrast(tokens.fetch("muted"), tokens.fetch("surface")), :>=, 4.5
    assert_operator contrast(tokens.fetch("accent-ink"), tokens.fetch("accent")), :>=, 4.5
  end

  def test_mobile_install_code_cannot_widen_the_page
    styles = read("assets/css/landing.scss")

    assert_match(/\.install__channels\s*\{[^}]*grid-template-columns:\s*minmax\(0,\s*1fr\)\s+minmax\(0,\s*1fr\)/m, styles)
    assert_match(/\.install__channel\s*\{[^}]*min-width:\s*0/m, styles)
    assert_match(/@media\s*\(max-width:\s*860px\)[\s\S]*\.install__channels[^{]*\{[^}]*grid-template-columns:\s*minmax\(0,\s*1fr\)/m, styles)
  end

  def test_default_share_card_matches_the_broad_homepage_story
    share_card = read("assets/img/og-image.svg")

    assert_includes share_card, "Run AI workflows"
    assert_includes share_card, "that survive"
    assert_includes share_card, "durable, local-first workflow engine for AI agents"
    assert_includes share_card, "Software workflows"
    assert_includes share_card, "General workflows"
    refute_includes share_card, "merge-ready pull request"
  end

  def test_supplementary_homepage_copy_stays_broad_and_source_linked
    pipeline = read("_includes/landing/pipeline.html")
    fit = read("_includes/landing/fit.html")

    assert_includes pipeline, "flagship"
    assert_includes pipeline, "content"
    assert_includes pipeline, "bench"
    assert_includes pipeline, "Honeycombs"
    refute_match(/Claude Max|ChatGPT Pro|Kimi/, fit)
    assert_includes fit, "https://github.com/ivankuznetsov/hive/blob/main/wiki/operating.md"
    assert_includes fit, "https://github.com/ivankuznetsov/hive/blob/main/wiki/modules/agent_profile.md"
  end

  private

  def read(path)
    File.read(File.join(ROOT, path), encoding: Encoding::UTF_8)
  end

  def contrast(first, second)
    high, low = [luminance(first), luminance(second)].sort.reverse
    (high + 0.05) / (low + 0.05)
  end

  def luminance(hex)
    hex.delete_prefix("#").scan(/../).map { |channel| channel.to_i(16) / 255.0 }
       .map { |value| value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4 }
       .then { |red, green, blue| (0.2126 * red) + (0.7152 * green) + (0.0722 * blue) }
  end
end
