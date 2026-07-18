# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/honeycomb_catalog_sync"

class PublicSchemasTest < Minitest::Test
  SCHEMAS = %w[
    catalog-v1.json
    catalog-v2.json
    listing-approval-v1.json
    listing-evidence-v1.json
    security-lint-evidence-v1.json
  ].freeze

  def test_all_honeycomb_contracts_are_checked_in_under_the_public_hivecli_path
    SCHEMAS.each do |name|
      path = File.join(ROOT, "schemas", name)
      assert File.file?(path), "missing #{path}"
      bytes = File.binread(path)
      schema = JSON.parse(bytes)

      expected_id = if name == "catalog-v1.json"
                      "https://hive.sh/schemas/catalog-v1.json"
                    else
                      "https://hivecli.sh/schemas/#{name}"
                    end
      assert_equal expected_id, schema.fetch("$id")
      assert_equal "https://json-schema.org/draft/2020-12/schema", schema.fetch("$schema")
      refute_includes bytes, "https://hive.sh/schemas/" unless name == "catalog-v1.json"
    end
  end

  def test_sync_validator_uses_the_same_catalog_schema_that_jekyll_serves
    assert_equal File.join(ROOT, "schemas", "catalog-v2.json"), HoneycombCatalogSync::CATALOG_SCHEMA_PATH
    assert_equal File.join(ROOT, "schemas", "listing-evidence-v1.json"), HoneycombCatalogSync::LISTING_SCHEMA_PATH
  end
end
