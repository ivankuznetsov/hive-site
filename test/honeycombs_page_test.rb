# frozen_string_literal: true

require "open3"
require_relative "test_helper"

class HoneycombsPageTest < Minitest::Test
  def test_populated_page_renders_discoverable_entries_permissions_trust_and_no_js_baseline
    community = CatalogFixtures.entry(
      name: "alpha-tool",
      description: "Useful <script>alert('no')</script> & dependable",
      community_reviews: "https://github.com/ivankuznetsov/honeycomb/tree/main/reviews/alpha-tool/1.0.0"
    )
    verified = CatalogFixtures.entry(name: "verified-tool", tier: "verified", risk: "high")
    hidden = CatalogFixtures.entry(name: "hidden-tool", state: "soft_hidden")
    yanked = CatalogFixtures.entry(name: "yanked-tool", state: "yanked")
    revoked = CatalogFixtures.entry(name: "revoked-tool", state: "revoked")
    html = build_site(site_snapshot([community, hidden, revoked, verified, yanked]))

    assert_includes html, "alpha-tool"
    assert_includes html, "verified-tool"
    refute_includes html, "hidden-tool"
    refute_includes html, "yanked-tool"
    refute_includes html, "revoked-tool"
    assert_includes html, "Community"
    assert_includes html, "Verified"
    assert_includes html, "Moderate risk"
    assert_includes html, "High risk"
    assert_includes html, "Unbounded"
    assert_includes html, "None"
    assert_includes html, "Community reviews"
    assert_equal 1, html.scan("Community reviews").length
    assert_includes html, "hive workflow install honeycomb/alpha-tool"
    assert_match(/<code[^>]*>hive workflow install honeycomb\/alpha-tool<\/code>/, html)
    assert_match(/<button[^>]*hidden[^>]*data-honeycomb-copy/, html)
    assert_match(/not an\s+endorsement/, html)
    assert_match(/not a safety guarantee/, html)
    assert_includes html, "Read the trust model"
    assert_includes html, "Signature evidence"
    assert_includes html, "Build attestation"
    assert_includes html, "Useful &lt;script&gt;alert(&#39;no&#39;)&lt;/script&gt; &amp; dependable"
    refute_includes html, "<script>alert('no')</script>"
  end

  def test_valid_empty_catalog_renders_honest_empty_state
    html = build_site(site_snapshot([]))

    assert_includes html, "No honeycombs are listed yet"
    assert_includes html, "Packages appear here only after"
  end

  def test_distinct_semver_versions_render_unique_dom_ids
    prerelease = CatalogFixtures.entry(name: "versioned-tool", version: "1.0.0-1")
    release = CatalogFixtures.entry(name: "versioned-tool", version: "1.0.0")
    prerelease["latest_version"] = "1.0.0"
    html = build_site(site_snapshot([prerelease, release]))

    ids = html.scan(/\bid="([^"]+)"/).flatten
    assert_equal ids.uniq, ids
    controls = html.scan(/\baria-controls="([^"]+)"/).flatten
    assert_equal 2, controls.length
    assert_equal controls.uniq, controls
  end

  def test_page_is_discoverable_responsive_and_contains_no_catalog_network_client
    page = File.read(File.join(ROOT, "honeycombs", "index.md"))
    layout = File.read(File.join(ROOT, "_layouts", "home.html"))
    cards = File.read(File.join(ROOT, "_includes", "landing", "cards.html"))
    footer = File.read(File.join(ROOT, "_includes", "landing", "footer.html"))
    styles = File.read(File.join(ROOT, "assets", "css", "landing.scss"))
    script = File.read(File.join(ROOT, "assets", "js", "honeycomb-copy.js"))

    assert_includes page, "permalink: /honeycombs/"
    assert_includes layout, "'/honeycombs/'"
    assert_includes cards, "'/honeycombs/'"
    assert_includes footer, "'/honeycombs/'"
    assert_match(/@media \(max-width: .*\).*honeycomb/m, styles)
    refute_match(/fetch\s*\(|XMLHttpRequest|https?:\/\//, script)
  end

  private

  def site_snapshot(entries)
    {"schema" => "honeycomb-catalog/v2", "entries" => entries}
  end

  def build_site(snapshot)
    Dir.mktmpdir do |directory|
      source = File.join(directory, "source")
      destination = File.join(directory, "site")
      FileUtils.mkdir_p(source)
      copy_site(source)
      File.binwrite(File.join(source, "_data", "honeycombs.json"), JSON.pretty_generate(snapshot) + "\n")

      env = {"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"), "JEKYLL_ENV" => "test"}
      command = [RbConfig.ruby, Gem.bin_path("bundler", "bundle"), "exec", "jekyll", "build",
                 "--source", source, "--destination", destination, "--quiet"]
      stdout, stderr, status = Open3.capture3(env, *command)
      assert status.success?, "Jekyll build failed:\n#{stdout}\n#{stderr}"
      File.binread(File.join(destination, "honeycombs", "index.html"))
    end
  end

  def copy_site(destination)
    entries = Dir.children(ROOT) - %w[.git .jekyll-cache .sass-cache _site node_modules test vendor]
    entries.each { |entry| FileUtils.cp_r(File.join(ROOT, entry), destination) }
  end
end
