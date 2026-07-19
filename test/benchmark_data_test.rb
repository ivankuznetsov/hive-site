# frozen_string_literal: true

require_relative "test_helper"

class BenchmarkDataTest < Minitest::Test
  CAMPAIGNS = JSON.parse(File.read(File.join(ROOT, "_data", "bench.json"))).fetch("experimental_campaigns")

  def test_experimental_publication_contains_only_dual_judged_cells
    cells = CAMPAIGNS.flat_map { |campaign| campaign.fetch("cells") }

    assert_equal 6, cells.length
    assert_equal cells.length, cells.map { |cell| [cell.fetch("candidate_id"), cell.fetch("task_id")] }.uniq.length

    cells.each do |cell|
      assert_equal %w[fable-5 gpt-5.6-sol], cell.fetch("judges").keys.sort

      cell.fetch("judges").each_value do |judge|
        scores = judge.fetch("scores")
        assert_equal 3, scores.length
        assert_in_delta scores.sum / scores.length, judge.fetch("mean"), 0.001
      end
    end
  end

  def test_experimental_coverage_reconciles_to_each_registered_matrix
    CAMPAIGNS.each do |campaign|
      coverage = campaign.fetch("coverage")

      assert_equal coverage.fetch("expected_cells"),
                   coverage.fetch("dual_judged_cells", 0) +
                     coverage.fetch("single_judge_cells", 0) +
                     coverage.fetch("empty_diff_cells", 0) +
                     coverage.fetch("provider_pending_cells", 0),
                   campaign.fetch("id")
      assert_equal coverage.fetch("dual_judged_cells"), campaign.fetch("cells").length
    end
  end

  def test_experimental_campaign_identity_and_corpus_provenance_are_explicit
    mixed = CAMPAIGNS.find { |entry| entry.fetch("id") == "v3-mixed-workflows-three-seed-20260713" }
    kimi = CAMPAIGNS.find { |entry| entry.fetch("id") == "v3-all-kimi-add-i-key-three-seed-20260716" }

    assert_equal "v3-mixed-workflows-followup-20260713", mixed.dig("corpus", "requested_version")
    assert_equal mixed.dig("corpus", "requested_version"), mixed.dig("corpus", "serialized_version")
    assert_equal "v3-all-kimi-add-i-key-20260716", kimi.dig("corpus", "requested_version")
    assert_equal "v2", kimi.dig("corpus", "serialized_version")
  end

  def test_experimental_data_never_claims_public_raw_evidence
    CAMPAIGNS.each do |campaign|
      assert_equal false, campaign.fetch("raw_evidence_published")
    end
  end
end
