# frozen_string_literal: true

require "open3"
require_relative "test_helper"

class HoneycombsPageTest < Minitest::Test
  def test_populated_page_preserves_order_filters_lifecycles_and_escapes_text
    old = CatalogFixtures.entry(
      name: "alpha-tool", version: "1.0.0",
      description: "Useful <script>alert('no')</script> & dependable"
    )
    old["latest_version"] = "1.1.0"
    old["author"]["name"] = "<img src=x onerror=alert('author')>"
    latest = CatalogFixtures.entry(
      name: "alpha-tool", version: "1.1.0", tier: "verified", risk: "high",
      community_reviews: "https://github.com/ivankuznetsov/honeycomb/tree/main/reviews/alpha-tool/1.1.0"
    )
    hidden = CatalogFixtures.entry(name: "hidden-tool", state: "soft_hidden", description: "HIDDEN DESCRIPTION")
    revoked = CatalogFixtures.entry(name: "revoked-tool", state: "revoked", description: "REVOKED DESCRIPTION")
    yanked = CatalogFixtures.entry(name: "yanked-tool", state: "yanked", description: "YANKED DESCRIPTION")

    html = build_site(site_snapshot([old, latest, hidden, revoked, yanked]))

    assert_equal %w[alpha-tool@1.0.0 alpha-tool@1.1.0],
                 html.scan(/data-honeycomb-entry="([^"]+)"/).flatten
    %w[hidden-tool revoked-tool yanked-tool].each { |identity| refute_includes html, identity }
    %w[HIDDEN\ DESCRIPTION REVOKED\ DESCRIPTION YANKED\ DESCRIPTION].each do |text|
      refute_includes html, text.tr("\\", "")
    end
    assert_includes html, "Useful &lt;script&gt;alert(&#39;no&#39;)&lt;/script&gt; &amp; dependable"
    assert_includes html, "&lt;img src=x onerror=alert(&#39;author&#39;)&gt;"
    refute_includes html, "<script>alert('no')</script>"
    refute_includes html, "<img src=x"
  end

  def test_cards_render_independent_labels_install_guidance_links_and_permissions
    old = CatalogFixtures.entry(name: "alpha-tool", version: "1.0.0")
    old["latest_version"] = "1.1.0"
    latest = CatalogFixtures.entry(
      name: "alpha-tool", version: "1.1.0", tier: "verified", risk: "high",
      community_reviews: "https://github.com/ivankuznetsov/honeycomb/tree/main/reviews/alpha-tool/1.1.0"
    )

    html = build_site(site_snapshot([old, latest]))

    %w[Community Verified Listed Moderate High Latest Earlier].each { |label| assert_includes html, label }
    assert_match(/name-based/i, html)
    assert_includes html, "not version-pinned"
    assert_match(/does not target (?:this )?earlier 1\.0\.0 release/i, html)
    assert_equal 2, html.scan("hive workflow install honeycomb/alpha-tool").length
    assert_includes html, "https://github.com/ivankuznetsov/honeycomb/tree/main/packages/alpha-tool/1.0.0"
    assert_includes html, "https://github.com/ivankuznetsov/honeycomb/tree/main/packages/alpha-tool/1.1.0"
    assert_includes html, old.fetch("reviews_url")
    assert_includes html, latest.fetch("reviews_url")
    assert_equal 1, html.scan(">Community reviews<").length
    assert_includes html, latest.fetch("community_reviews_url")
    %w[Capabilities Network\ hosts Filesystem\ read Filesystem\ write Secrets].each do |label|
      assert_includes html, label.tr("\\", "")
    end
    assert_includes html, "repository"
    assert_includes html, "task/state.json"
    assert_includes html, "None"
    assert_includes html, "Unbounded"
    assert_includes html, "Signature evidence"
    assert_includes html, "Build attestation"
  end

  def test_trust_copy_and_empty_state_are_truthful_and_actionable
    html = build_site(site_snapshot([]))

    assert_includes html, "No honeycombs are listed yet"
    assert_match(/no releases have completed listing review/i, html)
    assert_match(/not an\s+endorsement/, html)
    assert_match(/not a safety guarantee/, html)
    assert_match(/not a substitute for (?:reading|inspecting).*permissions.*linked evidence/im, html)
    assert_includes html, "https://github.com/ivankuznetsov/honeycomb"
    assert_includes html, "https://github.com/ivankuznetsov/honeycomb/blob/main/docs/TRUST.md"
    assert_includes html, "https://github.com/ivankuznetsov/honeycomb/blob/main/SECURITY.md"
    refute_includes html, "honeycomb-card"
  end

  def test_no_javascript_baseline_and_copy_controls_have_unique_live_statuses
    first = CatalogFixtures.entry(name: "alpha-tool")
    second = CatalogFixtures.entry(name: "beta-tool")
    html = build_site(site_snapshot([first, second]))

    assert_includes html, "hive workflow install honeycomb/alpha-tool"
    assert_includes html, "Complete permissions"
    assert_match(/<button[^>]*type="button"[^>]*hidden[^>]*data-honeycomb-copy/, html)
    assert_match(/<script src="\/assets\/js\/honeycomb-copy\.js" defer(?:="")?><\/script>/, html)
    controls = html.scan(/aria-controls="([^"]+)"/).flatten
    descriptions = html.scan(/aria-describedby="([^"]+)"/).flatten
    statuses = html.scan(/id="([^"]+)"[^>]*data-honeycomb-copy-status[^>]*aria-live="polite"/).flatten
    assert_equal 2, controls.length
    assert_equal controls.uniq, controls
    assert_equal 2, descriptions.length
    assert_equal descriptions.uniq, descriptions
    assert_equal descriptions.sort, statuses.sort
    controls.each { |id| assert_match(/id="#{Regexp.escape(id)}"[^>]*tabindex="0"/, html) }
  end

  def test_copy_enhancement_handles_success_failure_focus_and_timer_reset
    script_path = File.join(ROOT, "assets", "js", "honeycomb-copy.js")
    stdout, stderr, status = Open3.capture3("node", "-e", copy_harness, script_path)

    assert status.success?, "copy enhancement harness failed:\n#{stdout}\n#{stderr}"
    assert_equal "copy behavior passed", stdout.strip
  end

  def test_page_assets_are_responsive_and_contain_no_catalog_network_client
    styles = File.read(File.join(ROOT, "assets", "css", "landing.scss"))
    script = File.read(File.join(ROOT, "assets", "js", "honeycomb-copy.js"))
    page = File.read(File.join(ROOT, "honeycombs", "index.md"))

    assert_includes page, "permalink: /honeycombs/"
    assert_match(/@media \(max-width: 720px\).*honeycomb-detail-grid\s*\{\s*grid-template-columns:\s*1fr/m, styles)
    assert_match(/honeycomb-install__command.*flex-direction:\s*column/m, styles)
    assert_match(/overflow-wrap:\s*anywhere/, styles)
    refute_match(/fetch\s*\(|XMLHttpRequest|WebSocket|EventSource|import\s*\(|https?:\/\//, script)
  end

  def test_catalog_is_discoverable_from_header_homepage_and_footer_at_mobile_widths
    layout = File.read(File.join(ROOT, "_layouts", "home.html"))
    cards = File.read(File.join(ROOT, "_includes", "landing", "cards.html"))
    footer = File.read(File.join(ROOT, "_includes", "landing", "footer.html"))
    styles = File.read(File.join(ROOT, "assets", "css", "landing.scss"))

    [layout, cards, footer].each do |source|
      assert_match(/href="\{\{ '\/honeycombs\/' \| relative_url \}\}"/, source)
    end
    assert_includes layout, "href=\"{{ '/' | relative_url }}#install\""
    assert_match(/@media \(max-width: 600px\).*\.site-nav a:not\(\.btn\)\s*\{\s*display:\s*none/m, styles)
    assert_match(/@media \(max-width: 600px\).*\.cards__grid\s*\{\s*grid-template-columns:\s*1fr/m, styles)
    assert_match(/@media \(max-width: 860px\).*\.site-footer__inner\s*\{\s*grid-template-columns:\s*1fr/m, styles)
    refute_match(/site-footer__links[^}]*display:\s*none/, styles)
  end

  def test_maintainer_documentation_describes_the_offline_exact_snapshot_workflow
    readme = File.read(File.join(ROOT, "README.md"))

    assert_match(/git -C .* fetch origin main/, readme)
    assert_includes readme, "--catalog"
    assert_includes readme, "--source-sha"
    assert_match(/full.*SHA|SHA.*full/i, readme)
    assert_match(/does not fetch|performs no fetch/i, readme)
    assert_match(/byte-for-byte|exact upstream bytes/i, readme)
    assert_match(/last-known-good/i, readme)
    assert_includes readme, "ruby -Itest test/run.rb"
    assert_includes readme, "jekyll build"
    refute_match(/snapshot envelope|public schemas|five Honeycomb contracts/i, readme)
  end

  def test_repository_gate_is_deterministic_network_denied_and_excludes_internals
    runner = File.read(File.join(ROOT, "test", "run.rb"))
    config = File.read(File.join(ROOT, "_config.yml"))

    assert_match(/Dir\[.*\]\.sort\.each/, runner)
    %w[lib script test].each { |path| assert_match(/^\s*- #{path}$/m, config) }
    assert_raises(NetworkAccessDenied) { TCPSocket.new("example.test", 443) }

    with_built_site(site_snapshot([])) do |destination, html|
      emitted = Dir.glob(File.join(destination, "**", "*"), File::FNM_DOTMATCH)
                   .select { |path| File.file?(path) }
                   .map { |path| path.delete_prefix("#{destination}/") }
      refute emitted.any? { |path| path.start_with?("lib/", "script/", "test/") }, emitted.inspect
      assert_includes emitted, "honeycombs/index.html"

      refute_match(/<script\b[^>]*\bsrc=["']https?:\/\//i, html)
      refute_match(/<(?:img|iframe|video|audio|source)\b[^>]*\bsrc=["']https?:\/\//i, html)
      refute_match(/<link\b[^>]*\brel=["'](?:stylesheet|icon|preload|modulepreload)["'][^>]*\bhref=["']https?:\/\//i, html)
      assert_match(/<a\b[^>]*href="https:\/\/github\.com\/ivankuznetsov\/honeycomb/, html)
    end
  end

  private

  def site_snapshot(entries)
    {"schema" => "honeycomb-catalog/v2", "entries" => entries}
  end

  def build_site(snapshot)
    html = nil
    with_built_site(snapshot) { |_destination, built_html| html = built_html }
    html
  end

  def with_built_site(snapshot)
    Dir.mktmpdir do |directory|
      source = File.join(directory, "source")
      destination = File.join(directory, "site")
      FileUtils.mkdir_p(source)
      copy_site(source)
      File.binwrite(File.join(source, "_data", "honeycombs.json"), JSON.pretty_generate(snapshot) + "\n")

      env = {"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"),
             "BUNDLE_PATH" => File.join(ROOT, "vendor", "bundle"), "JEKYLL_ENV" => "test"}
      command = [RbConfig.ruby, Gem.bin_path("bundler", "bundle"), "exec", "jekyll", "build",
                 "--source", source, "--destination", destination, "--quiet"]
      stdout, stderr, status = Open3.capture3(env, *command)
      assert status.success?, "Jekyll build failed:\n#{stdout}\n#{stderr}"
      yield destination, File.binread(File.join(destination, "honeycombs", "index.html"))
    end
  end

  def copy_site(destination)
    entries = Dir.children(ROOT) - %w[.git .jekyll-cache .sass-cache _site node_modules test vendor]
    entries.each { |entry| FileUtils.cp_r(File.join(ROOT, entry), destination) }
  end

  def copy_harness
    <<~'JAVASCRIPT'
      const fs = require("node:fs");
      const vm = require("node:vm");
      const assert = require("node:assert/strict");
      const script = fs.readFileSync(process.argv[1], "utf8");
      const timers = [];

      function element(attributes = {}) {
        return {
          hidden: true,
          textContent: attributes.textContent || "",
          focused: false,
          listeners: {},
          getAttribute(name) { return attributes[name]; },
          addEventListener(name, callback) { this.listeners[name] = callback; },
          focus() { this.focused = true; }
        };
      }

      const successCode = element({textContent: "hive workflow install honeycomb/success"});
      const failureCode = element({textContent: "hive workflow install honeycomb/failure"});
      const successStatus = element();
      const failureStatus = element();
      const successButton = element({textContent: "Copy", "aria-controls": "success", "aria-describedby": "success-status"});
      const failureButton = element({textContent: "Copy", "aria-controls": "failure", "aria-describedby": "failure-status"});
      const elements = {
        success: successCode,
        failure: failureCode,
        "success-status": successStatus,
        "failure-status": failureStatus
      };
      const writes = [];
      const context = {
        navigator: {clipboard: {writeText(value) {
          writes.push(value);
          return value.endsWith("failure") ? Promise.reject(new Error("denied")) : Promise.resolve();
        }}},
        document: {
          querySelectorAll(selector) {
            assert.equal(selector, "[data-honeycomb-copy]");
            return [successButton, failureButton];
          },
          getElementById(id) { return elements[id]; }
        },
        window: {setTimeout(callback, delay) { timers.push({callback, delay}); return timers.length; }}
      };

      vm.runInNewContext(script, context);
      assert.equal(successButton.hidden, false);
      assert.equal(failureButton.hidden, false);

      (async () => {
        await successButton.listeners.click();
        assert.equal(successButton.textContent, "Copied");
        assert.match(successStatus.textContent, /copied/i);
        await failureButton.listeners.click();
        assert.match(failureButton.textContent, /select|failed/i);
        assert.match(failureStatus.textContent, /select.*manually/i);
        assert.equal(failureCode.focused, true);
        assert.deepEqual(writes, [successCode.textContent, failureCode.textContent]);
        assert.equal(timers.length, 2);
        assert.ok(timers.every((timer) => timer.delay >= 1000));
        timers.forEach((timer) => timer.callback());
        assert.equal(successButton.textContent, "Copy");
        assert.equal(failureButton.textContent, "Copy");
        assert.equal(successStatus.textContent, "");
        assert.equal(failureStatus.textContent, "");
        console.log("copy behavior passed");
      })().catch((error) => { console.error(error); process.exitCode = 1; });
    JAVASCRIPT
  end
end
