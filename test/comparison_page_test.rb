# frozen_string_literal: true

require "date"
require "cgi"
require "open3"
require "set"
require "uri"
require "yaml"
require_relative "test_helper"

class ComparisonPageTest < Minitest::Test
  DATA_PATH = File.join(ROOT, "_data", "comparison.yml")
  PRODUCT_IDS = %w[hive agentico omnigent].freeze
  DIMENSION_IDS = %w[
    product_scope
    workflow_state
    harnesses_providers
    planning_review
    repository_context
    isolation
    multi_repository_delivery
    policy_sandboxing
    collaboration_ui
    durability_recovery
    extensibility
    deployment
    ideal_use_cases
  ].freeze
  CLAIM_TYPES = %w[fact positioning_interpretation hive_maintainer_inference].freeze
  SCOPES = %w[product included_workflow].freeze

  def setup
    assert_path_exists DATA_PATH
    @data = YAML.safe_load_file(DATA_PATH)
  end

  def test_data_has_exact_products_dimensions_and_complete_unique_matrix
    assert_equal "hive-site-comparison/v1", @data.fetch("schema")
    assert_equal PRODUCT_IDS, @data.fetch("products").map { |product| product.fetch("id") }
    assert_equal DIMENSION_IDS, @data.fetch("dimensions").map { |dimension| dimension.fetch("id") }

    cells = @data.fetch("cells")
    keys = cells.map { |cell| [cell.fetch("dimension_id"), cell.fetch("product_id")] }
    expected = DIMENSION_IDS.product(PRODUCT_IDS)

    assert_equal expected.length, cells.length
    assert_equal expected.to_set, keys.to_set
    assert_equal keys.length, keys.uniq.length
  end

  def test_material_claims_are_classified_scoped_and_resolve_to_official_sources
    sources = @data.fetch("sources")

    @data.fetch("products").each do |product|
      %w[best_fit tradeoff].each do |field|
        claim = product.fetch(field)
        assert_includes CLAIM_TYPES, claim.fetch("claim_type")
        assert_includes SCOPES, claim.fetch("scope")
        assert_valid_source_ids claim.fetch("source_ids"), product.fetch("id"), sources
      end

      product.fetch("links").each_value do |link|
        assert_official_url product.fetch("id"), link.fetch("url")
        refute_empty link.fetch("label")
      end
    end

    @data.fetch("cells").each do |cell|
      next if cell.fetch("support_status") == "not_documented"

      assert_equal "documented", cell.fetch("support_status")
      refute_empty cell.fetch("claim")
      assert_includes CLAIM_TYPES, cell.fetch("claim_type")
      assert_includes SCOPES, cell.fetch("scope")
      assert_valid_source_ids cell.fetch("source_ids"), cell.fetch("product_id"), sources
      if cell.fetch("scope") == "included_workflow"
        refute_empty cell.fetch("scope_label")
      end
    end
  end

  def test_not_documented_cells_use_reviewed_source_sets_without_negative_prose
    sources = @data.fetch("sources")
    unknowns = @data.fetch("cells").select { |cell| cell.fetch("support_status") == "not_documented" }

    refute_empty unknowns
    unknowns.each do |cell|
      refute cell.key?("claim")
      refute cell.key?("claim_type")
      refute cell.key?("source_ids")
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, cell.fetch("reviewed_on"))
      assert_valid_source_ids cell.fetch("reviewed_source_ids"), cell.fetch("product_id"), sources
    end
  end

  def test_source_dates_and_unknown_review_dates_obey_freshness_contract
    page_date = Date.iso8601(@data.fetch("reviewed_on"))
    sources = @data.fetch("sources")

    cited_ids = @data.fetch("products").flat_map do |product|
      %w[best_fit tradeoff].flat_map { |field| product.fetch(field).fetch("source_ids") }
    end
    cited_ids.concat(@data.fetch("cells").flat_map { |cell|
      cell["source_ids"] || cell.fetch("reviewed_source_ids")
    })

    cited_ids.uniq.each do |source_id|
      assert_operator page_date, :>=, Date.iso8601(sources.fetch(source_id).fetch("verified_on"))
    end

    @data.fetch("cells").select { |cell| cell.fetch("support_status") == "not_documented" }.each do |cell|
      reviewed_on = Date.iso8601(cell.fetch("reviewed_on"))
      assert_operator page_date, :>=, reviewed_on
      cell.fetch("reviewed_source_ids").each do |source_id|
        assert_operator Date.iso8601(sources.fetch(source_id).fetch("verified_on")), :>=, reviewed_on
      end
    end
  end

  def test_included_workflow_claims_keep_product_specific_scope
    cells = @data.fetch("cells")
    hive_coding = cells.select do |cell|
      cell["product_id"] == "hive" && cell["scope"] == "included_workflow"
    end
    omnigent_polly = cells.select do |cell|
      cell["product_id"] == "omnigent" && cell["scope"] == "included_workflow"
    end

    refute_empty hive_coding
    assert hive_coding.all? { |cell| cell.fetch("scope_label").include?("Hive coding") }
    refute_empty omnigent_polly
    assert omnigent_polly.all? { |cell| cell.fetch("scope_label").include?("Polly") }
  end

  def test_omnigent_identity_and_excluded_comparison_boundaries_are_explicit
    omnigent = @data.fetch("products").find { |product| product.fetch("id") == "omnigent" }

    assert_equal "omnigent-ai/omnigent", omnigent.fetch("repository_identity")
    refute_match(/datadog/i, YAML.dump(@data))
    assert_equal %w[pricing performance_superiority popularity_adoption security_quality reliability roadmap],
                 @data.fetch("excluded_topics").map { |topic| topic.fetch("id") }
    assert_empty DIMENSION_IDS & @data.fetch("excluded_topics").map { |topic| topic.fetch("id") }
    refute_match(/overall winner|best overall|feature score|repository stars/i,
                 @data.fetch("products").to_s + @data.fetch("cells").to_s)
  end

  def test_page_is_declarative_and_renders_the_complete_decision_journey
    page_path = File.join(ROOT, "compare", "index.md")
    assert_path_exists page_path
    page = File.read(page_path)

    assert_includes page, "layout: home"
    assert_includes page, "permalink: /compare/"
    %w[intro summary matrix evidence cta].each do |partial|
      assert_includes page, "{% include comparison/#{partial}.html %}"
    end

    html, = build_site

    assert_equal 1, html.scan(/<h1\b/).length
    assert_includes html, @data.dig("page", "heading")
    assert_includes html, "Last reviewed"
    assert_includes html, "datetime=\"#{@data.fetch("reviewed_on")}\""
    assert_includes html, "does not name a generic winner"
    assert_includes html, "Three distinct best fits"
    assert_includes html, "Compare the decision dimensions"
    assert_includes html, "How to read the evidence"
    assert_includes html, "Official source register"
    assert_includes html, "What this page does not compare"
    assert_includes html, "Follow the boundary that fits"
  end

  def test_rendered_summary_and_matrix_use_every_data_claim_with_dated_evidence
    html, = build_site

    @data.fetch("products").each do |product|
      assert_includes html, product.fetch("name")
      assert_includes html, product.fetch("repository_identity")
      assert_includes html, CGI.escapeHTML(product.dig("best_fit", "text"))
      assert_includes html, CGI.escapeHTML(product.dig("tradeoff", "text"))
    end

    @data.fetch("dimensions").each do |dimension|
      assert_equal 1, html.scan(%(id="comparison-dimension-#{dimension.fetch("id")}")).length
      assert_includes html, dimension.fetch("label")
    end

    @data.fetch("cells").each do |cell|
      key = "#{cell.fetch("dimension_id")}-#{cell.fetch("product_id")}"
      assert_equal 1, html.scan(%(data-comparison-cell="#{key}")).length
      if cell.fetch("support_status") == "not_documented"
        sentence = "not documented in the reviewed official sources as of #{cell.fetch("reviewed_on")}"
        assert_includes html, sentence
      else
        assert_includes html, CGI.escapeHTML(cell.fetch("claim"))
        cell.fetch("source_ids").each do |source_id|
          source = @data.fetch("sources").fetch(source_id)
          assert_includes html, source.fetch("url")
          assert_includes html, source.fetch("verified_on")
        end
      end
    end
  end

  def test_rendered_matrix_legend_unknowns_and_actions_are_semantic_and_fair
    html, = build_site

    assert_match(/<div[^>]+class="[^"]*comparison-table-region[^"]*"[^>]+role="region"[^>]+tabindex="0"/, html)
    assert_match(/<table[^>]+class="[^"]*comparison-table[^"]*"/, html)
    assert_match(/<caption>\s*#{Regexp.escape(@data.dig("page", "matrix_caption"))}\s*<\/caption>/, html)
    assert_equal 4, html.scan(/<th[^>]*scope="col"/).length
    assert_equal 13, html.scan(/<th[^>]*scope="row"/).length

    @data.fetch("claim_types").each_value do |claim_type|
      assert_includes html, claim_type.fetch("label")
      assert_includes html, claim_type.fetch("description")
    end
    assert_includes html, "Included workflow"
    assert_includes html, "Hive coding workflow"
    assert_includes html, "Omnigent Polly workflow"
    assert_includes html, "Not documented"

    @data.fetch("excluded_topics").each do |topic|
      assert_includes html, topic.fetch("label")
      assert_includes html, topic.fetch("reason")
    end

    @data.fetch("products").each do |product|
      product.fetch("links").each_value do |link|
        assert_includes html, %(href="#{link.fetch("url")}")
        assert_includes html, link.fetch("label")
      end
    end
    assert_match(/class="[^"]*btn--primary[^"]*"[^>]+href="https:\/\/hivecli\.sh\/docs\/getting-started\/"/, html)
  end

  private

  def assert_valid_source_ids(source_ids, product_id, sources)
    refute_empty source_ids
    source_ids.each do |source_id|
      source = sources.fetch(source_id)
      assert_equal product_id, source.fetch("product_id")
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, source.fetch("verified_on"))
      refute_empty source.fetch("title")
      assert_official_url product_id, source.fetch("url")
    end
  end

  def assert_official_url(product_id, value)
    uri = URI.parse(value)
    assert_equal "https", uri.scheme

    official = case product_id
               when "hive"
                 uri.host == "hivecli.sh" ||
                   (uri.host == "github.com" && uri.path.start_with?("/ivankuznetsov/hive"))
               when "agentico"
                 uri.host == "careersatdoordash.com" ||
                   (uri.host == "github.com" && uri.path.start_with?("/doordash-oss/agentic-orchestrator"))
               when "omnigent"
                 uri.host == "omnigent.ai" ||
                   (uri.host == "github.com" && uri.path.start_with?("/omnigent-ai/omnigent"))
               end

    assert official, "expected official #{product_id} URL, got #{value}"
  end

  def build_site
    Dir.mktmpdir do |directory|
      destination = File.join(directory, "site")
      env = {"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"), "JEKYLL_ENV" => "test"}
      command = [RbConfig.ruby, Gem.bin_path("jekyll", "jekyll"), "build",
                 "--source", ROOT, "--destination", destination, "--quiet"]
      stdout, stderr, status = Open3.capture3(env, *command)
      assert status.success?, "Jekyll build failed:\n#{stdout}\n#{stderr}"
      html = File.binread(File.join(destination, "compare", "index.html"))
      sitemap = File.binread(File.join(destination, "sitemap.xml"))
      [html, sitemap]
    end
  end
end
