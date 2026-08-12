# frozen_string_literal: true

require "date"
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
end
