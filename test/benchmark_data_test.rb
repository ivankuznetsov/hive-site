# frozen_string_literal: true

require_relative "test_helper"
require "open3"

class BenchmarkDataTest < Minitest::Test
  DATA = JSON.parse(File.read(File.join(ROOT, "_data", "bench.json")))
  DISCUSSION_FIXTURE = JSON.parse(
    File.read(File.join(ROOT, "test", "fixtures", "bench", "discussion_scores.json"))
  )
  DISCUSSION_JUDGES = {
    "fable-5" => "fable",
    "gpt-5.6-sol" => "sol"
  }.freeze
  DISCUSSION_SOURCES = {
    "v2-ce" => {
      "source_repository" => "hive-bench",
      "source_artifact" => "runs/v2-ce/deliberation.json",
      "source_sha256" => "e2968cca16739c25fea2d20ba1dee11e57255ab1a616068b18d1b5b6e6581f4f",
      "round_one_mode" => "reused_published_independent_verdicts"
    },
    "v3-mixed-workflows-three-seed-20260713" => {
      "source_repository" => "hive-bench-followup",
      "source_artifact" => "runs/v3-mixed-workflows-three-seed-20260713/deliberation.json",
      "source_sha256" => "f05d50a12940a94276cf24babdb63eb92c402b7744f119ed2d919c1854271cf5",
      "round_one_mode" => "fresh_regrade"
    },
    "v3-production-review-panels-three-seed-20260723" => {
      "source_repository" => "hive-bench-flagship-campaign",
      "source_artifact" => "runs/v3-production-review-panels-three-seed-20260723/deliberation.json",
      "source_sha256" => "d04c4b5e990d7a39d4b46161b3584bca368a9f777e7e885faac6d146fac8d201",
      "round_one_mode" => "fresh_regrade"
    },
    "v3-deepseek-v4-0813-20260813-r2" => {
      "source_repository" => "hive-bench",
      "source_artifact" => "runs/v3-deepseek-v4-0813-20260813-r2/deliberation.json",
      "source_sha256" => "a3de17cabb4fee957743ea1f911bb6aff980a341e0b1d725c1c1d7d3e04cc8bc",
      "round_one_mode" => "fresh_regrade"
    },
    "v3-pi-ox-alpha-high-20260825-r3" => {
      "source_repository" => "hive-bench",
      "source_artifact" => "runs/v3-pi-ox-alpha-high-20260825-r3/deliberation.json",
      "source_sha256" => "91a6b3230417a33e1ad40d154b216ccf8d582ef83f6e63f68b6cfac18e82665b",
      "round_one_mode" => "fresh_regrade"
    },
    "v3-pi-ox-alpha-glm-5-3-flash-max-20260826-r6-sealed" => {
      "source_repository" => "hive-bench",
      "source_artifact" => "runs/v3-pi-ox-alpha-glm-5-3-flash-max-20260826-r6-sealed/deliberation.json",
      "source_sha256" => "3d4ae3eb585922b6ca2b9b3505e7484b54e913b4ac08ee2c761b720976b92d5b",
      "round_one_mode" => "fresh_regrade"
    }
  }.freeze
  FOLLOWUP_CAMPAIGN_BY_ID = {
    "fable-plan->grok-exec-sol-review" => "v3-mixed-workflows-three-seed-20260713",
    "sol-plan->grok-exec-sol-review" => "v3-mixed-workflows-three-seed-20260713",
    "sol-plan->terra-exec-sol-review" => "v3-mixed-workflows-three-seed-20260713",
    "sol-plan->terra-exec-grok-review" => "v3-production-review-panels-three-seed-20260723",
    "sol-plan@xhigh->exec@high+grok-review" => "v3-production-review-panels-three-seed-20260723"
  }.freeze
  FOLLOWUP_IDS = FOLLOWUP_CAMPAIGN_BY_ID.keys.freeze
  DEEPSEEK_IDS = [
    "all-deepseek-v4-pro-0813@xhigh",
    "deepseek-pro@xhigh->flash@xhigh-exec+pro-review"
  ].freeze
  OX_ALPHA_PI_ID = "all-ox-alpha@high"
  OX_ALPHA_PI_MAX_ID = "all-ox-alpha@max"
  OX_ALPHA_PI_MAX_CAMPAIGN_ID = "v3-pi-ox-alpha-glm-5-3-flash-max-20260826-r6-sealed"
  OX_ALPHA_PI_IDS = [OX_ALPHA_PI_ID, OX_ALPHA_PI_MAX_ID].freeze
  UNSPECIFIED_FABLE_IDS = (DEEPSEEK_IDS + OX_ALPHA_PI_IDS).freeze
  RANKED_LABELS = [
    "GPT-5.6 Sol xhigh",
    "Sol plan → Sol execute → Sol + Grok review",
    "Sol plan → Grok execute → Sol review",
    "Sol plan → Terra execute → Sol review",
    "DeepSeek V4 Pro 0813 xhigh",
    "Opus plan → Codex 5.5 xhigh",
    "Fable plan → Grok execute → Sol review",
    "Grok 4.5 xhigh",
    "Sol plan → Terra execute → Grok review",
    "Opus 4.8",
    "GLM 5.3 Flash (0x Alpha) via Pi high",
    "GLM 5.3 Flash (0x Alpha) via Pi max",
    "DeepSeek V4 Pro plan → V4 Flash execute → V4 Pro review",
    "Codex 5.5 xhigh",
    "GLM 5.2"
  ].freeze

  def test_completed_followup_expands_the_existing_board
    assert_equal 14, DATA.fetch("schema_version")
    assert_equal(
      "v2-ce + v3-mixed-workflows-followup-20260713 + v3-production-review-panels-20260723 + v3-deepseek-v4-0813-20260813-r2 + v3-pi-ox-alpha-high-20260825-r3 + v3-pi-ox-alpha-glm-5-3-flash-max-20260826-r6-sealed",
      DATA.fetch("corpus_version")
    )
    assert_equal 90, DATA.dig("coverage", "cells")
    assert_equal 90, DATA.dig("coverage", "expected_cells")
    assert_equal 15, DATA.dig("coverage", "candidates")
    assert_equal 15, DATA.fetch("candidates").length
    assert DATA.fetch("notes").any? { |note| note.include?("All six active campaigns ran adversarial deliberation") }

    DATA.fetch("primary_judges").each do |judge|
      assert_equal 15, judge.fetch("rows").length
    end

    FOLLOWUP_IDS.each do |candidate_id|
      candidate = DATA.fetch("candidates").find { |row| row.fetch("id") == candidate_id }

      refute_nil candidate
      assert_equal FOLLOWUP_CAMPAIGN_BY_ID.fetch(candidate_id), candidate.fetch("campaign_id")
      assert_equal 3, candidate.fetch("samples_per_cell")
      assert_equal 6, candidate.fetch("completed")
      assert_equal 6, candidate.fetch("cells").length
      assert_equal false, candidate.fetch("raw_evidence_published")
      assert_equal true, candidate.fetch("patches_published")

      candidate.fetch("cells").each do |task_key, cell|
        assert_equal %w[fable-5 gpt-5.6-sol], cell.fetch("judge_samples").keys.sort
        cell.fetch("judge_samples").each_value do |judge_sample|
          scores = judge_sample.fetch("scores")
          mean = scores.sum / 3.0
          stddev = Math.sqrt(scores.sum { |score| (score - mean)**2 } / 3.0)

          assert_equal 3, judge_sample.fetch("scores").length
          assert_in_delta mean, judge_sample.fetch("mean"), 0.001
          assert_in_delta stddev, judge_sample.fetch("stddev"), 0.001
          assert_in_delta mean - stddev, judge_sample.fetch("interval").first, 0.001
          assert_in_delta mean + stddev, judge_sample.fetch("interval").last, 0.001
        end
        displayed_scores = cell.fetch("scores").split(" / ").map(&:to_f)
        assert_in_delta cell.dig("judge_samples", "fable-5", "mean"), displayed_scores.first, 0.001
        assert_in_delta cell.dig("judge_samples", "gpt-5.6-sol", "mean"), displayed_scores.last, 0.001
        assert_equal true, cell.dig("judge_samples", "gpt-5.6-sol", "same_family")
        assert_match %r{\A/bench/patches/#{Regexp.escape(candidate.fetch("campaign_id"))}/[^/]+/#{task_key}\.patch\z},
                     cell.fetch("patch_url")
        assert_path_exists File.join(ROOT, cell.fetch("patch_url").delete_prefix("/"))
      end
    end

    DEEPSEEK_IDS.each do |candidate_id|
      candidate = DATA.fetch("candidates").find { |row| row.fetch("id") == candidate_id }

      refute_nil candidate
      assert_equal "v3-deepseek-v4-0813-20260813-r2", candidate.fetch("campaign_id")
      assert_equal 3, candidate.fetch("samples_per_cell")
      assert_equal [6, 6], candidate.values_at("completed", "total")
      assert_equal false, candidate.fetch("raw_evidence_published")
      assert_equal true, candidate.fetch("patches_published")
      assert_equal 6, candidate.fetch("cells").length

      candidate.fetch("cells").each do |task_key, cell|
        assert_equal %w[fable-5 gpt-5.6-sol], cell.fetch("judge_samples").keys.sort
        cell.fetch("judge_samples").each_value do |judge_sample|
          scores = judge_sample.fetch("scores")
          mean = scores.sum / 3.0
          stddev = Math.sqrt(scores.sum { |score| (score - mean)**2 } / 3.0)

          assert_equal 3, scores.length
          assert_in_delta mean, judge_sample.fetch("mean"), 0.001
          assert_in_delta stddev, judge_sample.fetch("stddev"), 0.001
          assert_in_delta mean - stddev, judge_sample.fetch("interval").first, 0.001
          assert_in_delta mean + stddev, judge_sample.fetch("interval").last, 0.001
          assert_equal false, judge_sample.fetch("same_family")
        end
        assert_match %r{\A/bench/patches/v3-deepseek-v4-0813-20260813-r2/[^/]+/#{task_key}\.patch\z},
                     cell.fetch("patch_url")
        assert_path_exists File.join(ROOT, cell.fetch("patch_url").delete_prefix("/"))
      end
    end

    ox_pi = DATA.fetch("candidates").find { |row| row.fetch("id") == OX_ALPHA_PI_ID }
    refute_nil ox_pi
    assert_equal "v3-pi-ox-alpha-high-20260825-r3", ox_pi.fetch("campaign_id")
    assert_equal 3, ox_pi.fetch("samples_per_cell")
    assert_equal [6, 6], ox_pi.values_at("completed", "total")
    assert_equal false, ox_pi.fetch("raw_evidence_published")
    assert_equal true, ox_pi.fetch("patches_published")
    assert_equal 6, ox_pi.fetch("cells").length
    ox_pi.fetch("cells").each do |task_key, cell|
      assert_equal %w[fable-5 gpt-5.6-sol], cell.fetch("judge_samples").keys.sort
      cell.fetch("judge_samples").each_value do |judge_sample|
        scores = judge_sample.fetch("scores")
        mean = scores.sum / 3.0
        stddev = Math.sqrt(scores.sum { |score| (score - mean)**2 } / 3.0)
        assert_equal 3, scores.length
        assert_in_delta mean, judge_sample.fetch("mean"), 0.001
        assert_in_delta stddev, judge_sample.fetch("stddev"), 0.001
        assert_in_delta mean - stddev, judge_sample.fetch("interval").first, 0.001
        assert_in_delta mean + stddev, judge_sample.fetch("interval").last, 0.001
        assert_equal false, judge_sample.fetch("same_family")
      end
      assert_match %r{\A/bench/patches/v3-pi-ox-alpha-high-20260825-r3/[^/]+/#{task_key}\.patch\z},
                   cell.fetch("patch_url")
      assert_path_exists File.join(ROOT, cell.fetch("patch_url").delete_prefix("/"))
    end

    ox_pi_max = DATA.fetch("candidates").find { |row| row.fetch("id") == OX_ALPHA_PI_MAX_ID }
    refute_nil ox_pi_max
    assert_equal OX_ALPHA_PI_MAX_CAMPAIGN_ID, ox_pi_max.fetch("campaign_id")
    assert_equal "GLM 5.3 Flash (0x Alpha) via Pi max", ox_pi_max.fetch("label")
    assert_equal 3, ox_pi_max.fetch("samples_per_cell")
    assert_equal [6, 6], ox_pi_max.values_at("completed", "total")
    assert_equal false, ox_pi_max.fetch("raw_evidence_published")
    assert_equal true, ox_pi_max.fetch("patches_published")
    assert_equal 6, ox_pi_max.fetch("cells").length
    ox_pi_max.fetch("cells").each do |task_key, cell|
      assert_equal %w[fable-5 gpt-5.6-sol], cell.fetch("judge_samples").keys.sort
      cell.fetch("judge_samples").each_value do |judge_sample|
        scores = judge_sample.fetch("scores")
        mean = scores.sum / 3.0
        stddev = Math.sqrt(scores.sum { |score| (score - mean)**2 } / 3.0)
        assert_equal 3, scores.length
        assert_in_delta mean, judge_sample.fetch("mean"), 0.001
        assert_in_delta stddev, judge_sample.fetch("stddev"), 0.001
        assert_in_delta mean - stddev, judge_sample.fetch("interval").first, 0.001
        assert_in_delta mean + stddev, judge_sample.fetch("interval").last, 0.001
        assert_equal false, judge_sample.fetch("same_family")
      end
      assert_match %r{\A/bench/patches/#{OX_ALPHA_PI_MAX_CAMPAIGN_ID}/all-ox-alpha-max/#{task_key}\.patch\z},
                   cell.fetch("patch_url")
      assert_path_exists File.join(ROOT, cell.fetch("patch_url").delete_prefix("/"))
    end

    withdrawn = DATA.fetch("withdrawn_campaigns")
    assert_equal ["all-ox-alpha-opencode@high"], withdrawn.map { |row| row.fetch("candidate_id") }
    opencode_withdrawal = withdrawn.first
    assert_equal "excluded from ranking and active coverage", opencode_withdrawal.fetch("disposition")
    assert_match(/held-out merge commit/, opencode_withdrawal.fetch("reason"))
    assert_match(/reached Hive execute-complete/, opencode_withdrawal.fetch("reason"))
    refute_match(/nonzero execute/, opencode_withdrawal.fetch("reason"))
    assert_path_exists File.join(ROOT, opencode_withdrawal.fetch("artifact_path").delete_prefix("/"))

    fable_candidate = DATA.fetch("candidates").find do |candidate|
      candidate.fetch("id") == "fable-plan->grok-exec-sol-review"
    end
    assert_nil fable_candidate.fetch("cost_per_task_usd")
    assert_nil fable_candidate.fetch("cost_total_usd")
    assert_equal 0, fable_candidate.fetch("cost_sample")
    assert fable_candidate.fetch("efficiency_by_task").values.all? { |task| task["cost_usd"].nil? }
    assert_equal 9.24, fable_candidate.fetch("normalized_mtokens_per_task")
    assert_equal 6, fable_candidate.fetch("token_sample")
    assert_equal "Fable plan + Sol review only · Grok telemetry unavailable",
                 fable_candidate.fetch("token_scope")
    assert_in_delta 7.10495, fable_candidate.fetch("known_cost_per_task_usd"), 0.000001
    assert_equal 6, fable_candidate.fetch("known_cost_sample")
    assert_equal FOLLOWUP_IDS.first, fable_candidate.fetch("id")
    assert_equal fable_candidate.fetch("efficiency_by_task").keys,
                 fable_candidate.fetch("efficiency_by_task").filter_map { |task, stat|
      task if stat["tokens"]
    }

    sol_grok_candidate = DATA.fetch("candidates").find do |candidate|
      candidate.fetch("id") == "sol-plan->grok-exec-sol-review"
    end
    assert_nil sol_grok_candidate.fetch("cost_per_task_usd")
    assert_nil sol_grok_candidate.fetch("cost_total_usd")
    assert_equal 0, sol_grok_candidate.fetch("cost_sample")
    assert sol_grok_candidate.fetch("efficiency_by_task").values.all? { |task| task["cost_usd"].nil? }
    assert_equal 29.123, sol_grok_candidate.fetch("normalized_mtokens_per_task")
    assert_equal 6, sol_grok_candidate.fetch("token_sample")
    assert_equal "Sol plan/review only · Grok telemetry unavailable", sol_grok_candidate.fetch("token_scope")
    assert_in_delta 21.353217, sol_grok_candidate.fetch("known_cost_per_task_usd"), 0.000001
    assert_equal 6, sol_grok_candidate.fetch("known_cost_sample")
    assert sol_grok_candidate.fetch("efficiency_by_task").values.all? { |task| task["tokens"] }

    [fable_candidate, sol_grok_candidate].each do |candidate|
      measured = candidate.fetch("efficiency_by_task").values.select { |task| task["tokens"] }
      %w[input output cache_read cache_write].each do |bucket|
        assert_equal measured.sum { |task| task.dig("tokens", bucket) }, candidate.dig("token_totals", bucket)
      end
      mean = measured.sum { |task| task.fetch("normalized_mtokens") } / measured.length
      assert_in_delta mean, candidate.fetch("normalized_mtokens_per_task"), 0.001
      assert_in_delta candidate.fetch("efficiency_by_task").values.sum { |task| task.fetch("known_cost_usd") },
                      candidate.fetch("known_cost_total_usd"), 0.0001
      assert_in_delta candidate.fetch("known_cost_total_usd") / candidate.fetch("known_cost_sample"),
                      candidate.fetch("known_cost_per_task_usd"), 0.001
    end

    discussion = DATA.fetch("discussion_adjusted")
    assert_equal "diagnostic", discussion.fetch("status")
    assert_equal %w[v2-ce v3-mixed-workflows-three-seed-20260713 v3-production-review-panels-three-seed-20260723 v3-deepseek-v4-0813-20260813-r2 v3-pi-ox-alpha-high-20260825-r3 v3-pi-ox-alpha-glm-5-3-flash-max-20260826-r6-sealed],
                 discussion.fetch("source_campaign_ids")
    assert_equal 90, discussion.dig("coverage", "cells")
    assert_equal 90, discussion.dig("coverage", "expected_cells")
    assert_equal 180, discussion.dig("coverage", "judge_decisions")
    assert_equal 180, discussion.dig("coverage", "expected_judge_decisions")
    assert_equal 90, discussion.dig("coverage", "fully_adjusted_cells")
    assert_empty discussion.dig("coverage", "missing")

    summary = discussion.fetch("summary")
    discussion_cells = discussion.fetch("candidates").flat_map do |candidate|
      candidate.fetch("cells").values
    end
    assert_equal 90, discussion_cells.length
    assert_equal discussion_cells.length, summary.fetch("cells")

    DISCUSSION_JUDGES.each do |summary_judge, cell_judge|
      decisions = discussion_cells.map { |cell| cell.fetch(cell_judge) }
      mean_revision = decisions.sum { |decision| decision.fetch("delta") } / decisions.length.to_f
      mean_abs_revision = decisions.sum { |decision| decision.fetch("delta").abs } / decisions.length.to_f

      assert_in_delta mean_revision,
                      summary.dig("mean_revision_by_judge", summary_judge), 0.001
      assert_in_delta mean_abs_revision,
                      summary.dig("mean_abs_revision_by_judge", summary_judge), 0.001
    end

    mean_spread_before = discussion_cells.sum do |cell|
      (cell.dig("fable", "initial") - cell.dig("sol", "initial")).abs
    end / discussion_cells.length.to_f
    mean_spread_after = discussion_cells.sum do |cell|
      (cell.dig("fable", "final") - cell.dig("sol", "final")).abs
    end / discussion_cells.length.to_f
    assert_in_delta mean_spread_before, summary.fetch("mean_spread_before"), 0.001
    assert_in_delta mean_spread_after, summary.fetch("mean_spread_after"), 0.001

    assert_in_delta(-0.829, summary.dig("mean_revision_by_judge", "fable-5"), 0.001)
    assert_in_delta(-0.084, summary.dig("mean_revision_by_judge", "gpt-5.6-sol"), 0.001)
    assert_in_delta 0.842, summary.dig("mean_abs_revision_by_judge", "fable-5"), 0.001
    assert_in_delta 0.3, summary.dig("mean_abs_revision_by_judge", "gpt-5.6-sol"), 0.001
    assert_in_delta 2.082, summary.fetch("mean_spread_before"), 0.001
    assert_in_delta 1.251, summary.fetch("mean_spread_after"), 0.001

    discussion_candidates = discussion.fetch("candidates").to_h { |candidate| [candidate.fetch("id"), candidate] }
    assert_equal 15, discussion_candidates.length
    assert_equal DATA.fetch("candidates").map { |candidate| candidate.fetch("id") }.sort,
                 discussion_candidates.keys.sort

    assert_equal "hive-bench-discussion-score-fixture", DISCUSSION_FIXTURE.fetch("schema")
    assert_equal 1, DISCUSSION_FIXTURE.fetch("schema_version")
    assert_equal %w[initial final delta revised], DISCUSSION_FIXTURE.fetch("tuple_fields")
    fixture_sources = DISCUSSION_FIXTURE.fetch("sources").to_h do |source|
      [source.fetch("campaign_id"), source]
    end
    assert_equal DISCUSSION_SOURCES.keys.sort, fixture_sources.keys.sort
    DISCUSSION_SOURCES.each do |campaign_id, expected_source|
      source = fixture_sources.fetch(campaign_id)
      expected_source.each do |field, expected_value|
        assert_equal expected_value, source.fetch(field)
      end
    end

    site_task_key_by_id = DATA.fetch("tasks").to_h do |task|
      [task.fetch("id"), task.fetch("key")]
    end
    fixture_cells = fixture_sources.each_with_object({}) do |(campaign_id, source), cells|
      source.fetch("cells").each do |cell|
        key = [
          campaign_id,
          cell.fetch("candidate_id"),
          site_task_key_by_id.fetch(cell.fetch("task_id"))
        ]
        refute cells.key?(key), "duplicate canonical discussion cell #{key.inspect}"
        cells[key] = cell.fetch("judges")
      end
    end
    assert_equal 90, fixture_cells.length
    assert_equal discussion_cells.length, fixture_cells.length

    discussion_candidates.each do |candidate_id, adjusted|
      candidate = DATA.fetch("candidates").find { |entry| entry.fetch("id") == candidate_id }
      assert_equal candidate.fetch("cells").keys.sort, adjusted.fetch("cells").keys.sort

      %w[fable sol].each do |judge|
        finals = adjusted.fetch("cells").values.map do |cell|
          decision = cell.fetch(judge)
          assert_in_delta decision.fetch("final") - decision.fetch("initial"),
                          decision.fetch("delta"), 0.001
          assert_equal decision.fetch("delta") != 0, decision.fetch("revised")
          decision.fetch("final")
        end
        assert_in_delta finals.sum / finals.length, adjusted.dig(judge, "mean"), 0.001
        assert_equal [6, 6], adjusted.fetch(judge).values_at("sample", "total")
      end

      combined_finals = adjusted.fetch("cells").values.flat_map do |cell|
        [cell.dig("fable", "final"), cell.dig("sol", "final")]
      end
      assert_in_delta combined_finals.sum / combined_finals.length,
                      adjusted.dig("combined", "mean"), 0.001
      assert_equal [6, 6], adjusted.fetch("combined").values_at("sample", "total")

      adjusted.fetch("cells").each do |task_key, cell|
        source_judges = fixture_cells.fetch([
          candidate.fetch("campaign_id"),
          candidate_id,
          task_key
        ])
        DISCUSSION_JUDGES.each do |source_judge, cell_judge|
          assert_equal source_judges.fetch(source_judge), cell.fetch(cell_judge)
        end
      end
    end
    assert_equal [6.25, 6, 6], discussion_candidates.dig("all-codex-5.6-sol-xhigh", "fable").values_at("mean", "sample", "total")
    assert_equal [5.867, 6, 6], discussion_candidates.dig("all-codex-5.6-sol-xhigh", "sol").values_at("mean", "sample", "total")
    assert_equal [6.058, 6, 6], discussion_candidates.dig("all-codex-5.6-sol-xhigh", "combined").values_at("mean", "sample", "total")
    assert_equal [6.583, 6, 6], discussion_candidates.dig("fable-plan->grok-exec-sol-review", "fable").values_at("mean", "sample", "total")
    assert_equal [5.517, 6, 6], discussion_candidates.dig("fable-plan->grok-exec-sol-review", "sol").values_at("mean", "sample", "total")
    assert_equal [6.05, 6, 6], discussion_candidates.dig("fable-plan->grok-exec-sol-review", "combined").values_at("mean", "sample", "total")
    assert_equal [7.383, 6, 6], discussion_candidates.dig("sol-plan->grok-exec-sol-review", "fable").values_at("mean", "sample", "total")
    assert_equal [6.433, 6, 6], discussion_candidates.dig("sol-plan->grok-exec-sol-review", "sol").values_at("mean", "sample", "total")
    assert_equal [6.908, 6, 6], discussion_candidates.dig("sol-plan->grok-exec-sol-review", "combined").values_at("mean", "sample", "total")
    assert_equal [7.45, 6, 6], discussion_candidates.dig("sol-plan->terra-exec-sol-review", "fable").values_at("mean", "sample", "total")
    assert_equal [5.483, 6, 6], discussion_candidates.dig("sol-plan->terra-exec-sol-review", "sol").values_at("mean", "sample", "total")
    assert_equal [6.467, 6, 6], discussion_candidates.dig("sol-plan->terra-exec-sol-review", "combined").values_at("mean", "sample", "total")
    assert_equal [6.517, 6, 6], discussion_candidates.dig("sol-plan->terra-exec-grok-review", "fable").values_at("mean", "sample", "total")
    assert_equal [4.917, 6, 6], discussion_candidates.dig("sol-plan->terra-exec-grok-review", "sol").values_at("mean", "sample", "total")
    assert_equal [5.717, 6, 6], discussion_candidates.dig("sol-plan->terra-exec-grok-review", "combined").values_at("mean", "sample", "total")
    assert_equal [7.917, 6, 6], discussion_candidates.dig("sol-plan@xhigh->exec@high+grok-review", "fable").values_at("mean", "sample", "total")
    assert_equal [7.133, 6, 6], discussion_candidates.dig("sol-plan@xhigh->exec@high+grok-review", "sol").values_at("mean", "sample", "total")
    assert_equal [7.525, 6, 6], discussion_candidates.dig("sol-plan@xhigh->exec@high+grok-review", "combined").values_at("mean", "sample", "total")
    assert_equal [6.833, 6, 6], discussion_candidates.dig("all-deepseek-v4-pro-0813@xhigh", "fable").values_at("mean", "sample", "total")
    assert_equal [4.95, 6, 6], discussion_candidates.dig("all-deepseek-v4-pro-0813@xhigh", "sol").values_at("mean", "sample", "total")
    assert_equal [5.892, 6, 6], discussion_candidates.dig("all-deepseek-v4-pro-0813@xhigh", "combined").values_at("mean", "sample", "total")
    assert_equal [6.75, 6, 6], discussion_candidates.dig("deepseek-pro@xhigh->flash@xhigh-exec+pro-review", "fable").values_at("mean", "sample", "total")
    assert_equal [4.817, 6, 6], discussion_candidates.dig("deepseek-pro@xhigh->flash@xhigh-exec+pro-review", "sol").values_at("mean", "sample", "total")
    assert_equal [5.783, 6, 6], discussion_candidates.dig("deepseek-pro@xhigh->flash@xhigh-exec+pro-review", "combined").values_at("mean", "sample", "total")
    assert_equal [6.333, 6, 6], discussion_candidates.dig(OX_ALPHA_PI_ID, "fable").values_at("mean", "sample", "total")
    assert_equal [5.05, 6, 6], discussion_candidates.dig(OX_ALPHA_PI_ID, "sol").values_at("mean", "sample", "total")
    assert_equal [5.692, 6, 6], discussion_candidates.dig(OX_ALPHA_PI_ID, "combined").values_at("mean", "sample", "total")
    assert_equal [6.5, 6, 6], discussion_candidates.dig(OX_ALPHA_PI_MAX_ID, "fable").values_at("mean", "sample", "total")
    assert_equal [4.467, 6, 6], discussion_candidates.dig(OX_ALPHA_PI_MAX_ID, "sol").values_at("mean", "sample", "total")
    assert_equal [5.483, 6, 6], discussion_candidates.dig(OX_ALPHA_PI_MAX_ID, "combined").values_at("mean", "sample", "total")
    assert_equal 5.6, discussion_candidates.dig("fable-plan->grok-exec-sol-review", "cells", "daemon", "sol", "final")
    assert_equal 6.5, discussion_candidates.dig("fable-plan->grok-exec-sol-review", "cells", "daemon", "fable", "final")
    assert_equal 4.5, discussion_candidates.dig("opus-plan->codex-exec-xhigh", "cells", "daemon", "sol", "final")
    assert_equal 5.5, discussion_candidates.dig("opus-plan->codex-exec-xhigh", "cells", "daemon", "fable", "final")

    terra_candidate = DATA.fetch("candidates").find do |candidate|
      candidate.fetch("id") == "sol-plan->terra-exec-sol-review"
    end
    assert_equal 26.12, terra_candidate.fetch("cost_per_task_usd")
    assert_equal 5, terra_candidate.fetch("cost_sample")
    assert_equal 34.807, terra_candidate.fetch("normalized_mtokens_per_task")
    assert_equal 5, terra_candidate.fetch("token_sample")
    assert_nil terra_candidate.dig("efficiency_by_task", "fix-review", "cost_usd")
    assert_nil terra_candidate.dig("efficiency_by_task", "fix-review", "tokens")
    assert_equal 52, DATA.dig("efficiency_accounting", "priced_cells")
    assert_equal 5, DATA.dig("efficiency_accounting", "followup_priced_cells")
    assert_equal 24, DATA.dig("efficiency_accounting", "known_partial_cost_cells")
    assert_equal 26, DATA.dig("efficiency_accounting", "followup_timed_cells")
    assert_equal 11, DATA.dig("efficiency_accounting", "deepseek_priced_cells")
    assert_equal 11, DATA.dig("efficiency_accounting", "deepseek_timed_cells")
    assert_equal 6, DATA.dig("efficiency_accounting", "ox_alpha_priced_cells")
    assert_equal 12, DATA.dig("efficiency_accounting", "ox_alpha_token_cells")
    assert_equal 9, DATA.dig("efficiency_accounting", "ox_alpha_timed_cells")
    assert_equal "assistant message_end", DATA.dig("efficiency_accounting", "pi_usage_event")
    assert_equal 90, DATA.dig("efficiency_accounting", "total_cells")

    glm = DATA.fetch("candidates").find { |candidate| candidate.fetch("id") == "all-glm-5.2" }
    assert_equal 5.65, glm.fetch("cost_per_task_usd")
    assert_equal [33.9223, 6], glm.values_at("cost_total_usd", "cost_sample")
    assert_equal [21.793, 6], glm.values_at("normalized_mtokens_per_task", "token_sample")

    all_deepseek = DATA.fetch("candidates").find { |candidate| candidate.fetch("id") == DEEPSEEK_IDS.first }
    assert_equal [120.0, 5], all_deepseek.values_at("mean_minutes", "time_sample")
    assert_equal 0.55, all_deepseek.fetch("cost_per_task_usd")
    assert_equal [2.7732, 5], all_deepseek.values_at("cost_total_usd", "cost_sample")
    assert_equal [50.754, 5], all_deepseek.values_at("normalized_mtokens_per_task", "token_sample")
    assert_nil all_deepseek.dig("efficiency_by_task", "fix-tmux", "cost_usd")
    assert_nil all_deepseek.dig("efficiency_by_task", "fix-tmux", "tokens")

    mixed_deepseek = DATA.fetch("candidates").find { |candidate| candidate.fetch("id") == DEEPSEEK_IDS.last }
    assert_equal [118.8, 6], mixed_deepseek.values_at("mean_minutes", "time_sample")
    assert_equal 0.6, mixed_deepseek.fetch("cost_per_task_usd")
    assert_equal [3.5895, 6], mixed_deepseek.values_at("cost_total_usd", "cost_sample")
    assert_equal [34.774, 6], mixed_deepseek.values_at("normalized_mtokens_per_task", "token_sample")

    [all_deepseek, mixed_deepseek].each do |candidate|
      measured = candidate.fetch("efficiency_by_task").values.select { |task| task["tokens"] }
      %w[input output cache_read cache_write].each do |bucket|
        assert_equal measured.sum { |task| task.dig("tokens", bucket) }, candidate.dig("token_totals", bucket)
      end
    end

    assert_equal [105.7, 4], ox_pi.values_at("mean_minutes", "time_sample")
    assert_equal [19.838, 6], ox_pi.values_at("normalized_mtokens_per_task", "token_sample")
    assert_equal [nil, nil, 0], ox_pi.values_at("cost_per_task_usd", "cost_total_usd", "cost_sample")
    measured_ox_pi = ox_pi.fetch("efficiency_by_task").values
    assert_equal 2, measured_ox_pi.count { |task| task.fetch("wall_minutes").nil? }
    assert measured_ox_pi.all? { |task| task.fetch("cost_usd").nil? }
    assert measured_ox_pi.all? { |task| task.fetch("tokens") }
    %w[input output cache_read cache_write].each do |bucket|
      assert_equal measured_ox_pi.sum { |task| task.dig("tokens", bucket) }, ox_pi.dig("token_totals", bucket)
    end

    assert_equal [95.5, 5], ox_pi_max.values_at("mean_minutes", "time_sample")
    assert_equal [33.343, 6], ox_pi_max.values_at("normalized_mtokens_per_task", "token_sample")
    assert_equal [6.9381, 41.6283, 6],
                 ox_pi_max.values_at("cost_per_task_usd", "cost_total_usd", "cost_sample")
    measured_ox_pi_max = ox_pi_max.fetch("efficiency_by_task").values
    assert_equal 1, measured_ox_pi_max.count { |task| task.fetch("wall_minutes").nil? }
    assert measured_ox_pi_max.all? { |task| task.fetch("cost_usd") }
    assert measured_ox_pi_max.all? { |task| task.fetch("tokens") }
    %w[input output cache_read cache_write].each do |bucket|
      assert_equal measured_ox_pi_max.sum { |task| task.dig("tokens", bucket) },
                   ox_pi_max.dig("token_totals", bucket)
    end

    terra_grok_candidate = DATA.fetch("candidates").find do |candidate|
      candidate.fetch("id") == "sol-plan->terra-exec-grok-review"
    end
    assert_equal 61.1, terra_grok_candidate.fetch("mean_minutes")
    assert_equal 6, terra_grok_candidate.fetch("time_sample")
    assert_equal 26.229, terra_grok_candidate.fetch("normalized_mtokens_per_task")
    assert_equal 6, terra_grok_candidate.fetch("token_sample")
    assert_in_delta 18.633017, terra_grok_candidate.fetch("known_cost_per_task_usd"), 0.000001
    assert_equal "Sol plan + Terra execute only · Grok review telemetry unavailable",
                 terra_grok_candidate.fetch("token_scope")

    flagship_candidate = DATA.fetch("candidates").find do |candidate|
      candidate.fetch("id") == "sol-plan@xhigh->exec@high+grok-review"
    end
    assert_equal 151.0, flagship_candidate.fetch("mean_minutes")
    assert_equal 6, flagship_candidate.fetch("time_sample")
    assert_equal 63.156, flagship_candidate.fetch("normalized_mtokens_per_task")
    assert_equal 6, flagship_candidate.fetch("token_sample")
    assert_in_delta 42.94215, flagship_candidate.fetch("known_cost_per_task_usd"), 0.000001
    assert_equal "Sol stages only · Grok reviewer telemetry unavailable",
                 flagship_candidate.fetch("token_scope")

    [terra_grok_candidate, flagship_candidate].each do |candidate|
      assert_nil candidate.fetch("cost_per_task_usd")
      assert_equal 0, candidate.fetch("cost_sample")
      assert_equal 6, candidate.fetch("known_cost_sample")
      assert candidate.fetch("efficiency_by_task").values.all? { |task| task.fetch("known_cost_usd") }
      assert candidate.fetch("efficiency_by_task").values.all? { |task| task.fetch("tokens") }
    end

    DATA.fetch("primary_judges").each do |judge|
      (FOLLOWUP_IDS + DEEPSEEK_IDS + OX_ALPHA_PI_IDS).each do |candidate_id|
        candidate = DATA.fetch("candidates").find { |row| row.fetch("id") == candidate_id }
        row = judge.fetch("rows").find { |entry| entry.fetch("id") == candidate_id }
        cell_mean = candidate.fetch("cells").values.sum do |cell|
          cell.dig("judge_samples", judge.fetch("id"), "mean")
        end / candidate.fetch("cells").length

        assert_in_delta cell_mean, row.fetch("mean"), 0.001
      end
    end

    sol_rows = DATA.fetch("primary_judges").find { |judge| judge.fetch("id") == "gpt-5.6-sol" }
    FOLLOWUP_IDS.each do |candidate_id|
      row = sol_rows.fetch("rows").find { |entry| entry.fetch("id") == candidate_id }
      assert_equal true, row.fetch("same_family")
    end
    (DEEPSEEK_IDS + OX_ALPHA_PI_IDS).each do |candidate_id|
      row = sol_rows.fetch("rows").find { |entry| entry.fetch("id") == candidate_id }
      assert_equal false, row.fetch("same_family")
    end

    fable_judge = DATA.fetch("primary_judges").find { |judge| judge.fetch("id") == "fable-5" }
    assert_equal "varies by campaign", fable_judge.fetch("reasoning_effort")
    assert fable_judge.fetch("rows").reject { |row| UNSPECIFIED_FABLE_IDS.include?(row.fetch("id")) }
                      .all? { |row| row.fetch("reasoning_effort") == "xhigh" }
    assert(UNSPECIFIED_FABLE_IDS.all? do |candidate_id|
      fable_judge.fetch("rows").find { |row| row.fetch("id") == candidate_id }
                  .fetch("reasoning_effort") == "unspecified"
    end)
    assert_equal(
      {
        "v2-ce" => "xhigh",
        "v3-mixed-workflows-three-seed-20260713" => "xhigh",
        "v3-production-review-panels-three-seed-20260723" => "xhigh",
        "v3-deepseek-v4-0813-20260813-r2" => "unspecified",
        "v3-pi-ox-alpha-high-20260825-r3" => "unspecified",
        OX_ALPHA_PI_MAX_CAMPAIGN_ID => "unspecified"
      },
      fable_judge.fetch("reasoning_effort_by_campaign")
    )
    DATA.fetch("primary_judges").each do |judge|
      assert_equal(
        {
          "v2-ce" => 1,
          "v3-mixed-workflows-three-seed-20260713" => 3,
          "v3-production-review-panels-three-seed-20260723" => 3,
          "v3-deepseek-v4-0813-20260813-r2" => 3,
          "v3-pi-ox-alpha-high-20260825-r3" => 3,
          OX_ALPHA_PI_MAX_CAMPAIGN_ID => 3
        },
        judge.fetch("samples_per_cell_by_campaign")
      )
    end
    assert_equal(
      "/bench/patches/v3-production-review-panels-three-seed-20260723/",
      DATA.dig("evidence", "production_review_panel_patches")
    )
    assert_equal true, DATA.dig("evidence", "production_review_panel_patches_published")
    assert_equal "/bench/patches/v3-deepseek-v4-0813-20260813-r2/",
                 DATA.dig("evidence", "deepseek_patches")
    assert_equal true, DATA.dig("evidence", "deepseek_patches_published")
    assert_equal "/bench/patches/v3-pi-ox-alpha-high-20260825-r3/",
                 DATA.dig("evidence", "ox_alpha_pi_patches")
    assert_equal true, DATA.dig("evidence", "ox_alpha_pi_patches_published")
    assert_equal "/bench/patches/#{OX_ALPHA_PI_MAX_CAMPAIGN_ID}/",
                 DATA.dig("evidence", "ox_alpha_pi_max_patches")
    assert_equal true, DATA.dig("evidence", "ox_alpha_pi_max_patches_published")
    FOLLOWUP_IDS.each do |candidate_id|
      candidate = DATA.fetch("candidates").find { |row| row.fetch("id") == candidate_id }
      candidate.fetch("cells").each_value do |cell|
        assert_equal "xhigh", cell.dig("judge_samples", "fable-5", "reasoning_effort")
        assert_equal true, cell.dig("judge_samples", "fable-5", "reasoning_effort_explicit")
      end
    end
    UNSPECIFIED_FABLE_IDS.each do |candidate_id|
      candidate = DATA.fetch("candidates").find { |row| row.fetch("id") == candidate_id }
      candidate.fetch("cells").each_value do |cell|
        assert_equal "unspecified", cell.dig("judge_samples", "fable-5", "reasoning_effort")
        assert_equal false, cell.dig("judge_samples", "fable-5", "reasoning_effort_explicit")
        assert_equal "ultra", cell.dig("judge_samples", "gpt-5.6-sol", "reasoning_effort")
        assert_equal true, cell.dig("judge_samples", "gpt-5.6-sol", "reasoning_effort_explicit")
      end
    end
  end

  def test_followup_rows_render_inside_current_tables_only
    Dir.mktmpdir do |destination|
      env = {"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"), "JEKYLL_ENV" => "test"}
      command = [
        RbConfig.ruby, Gem.bin_path("jekyll", "jekyll"), "build",
        "--source", ROOT, "--destination", destination, "--quiet", "--disable-disk-cache"
      ]
      stdout, stderr, status = Open3.capture3(env, *command)
      assert status.success?, "Jekyll build failed:\n#{stdout}\n#{stderr}"

      html = File.read(File.join(destination, "bench", "index.html"), encoding: Encoding::UTF_8)
      refute_includes html, "bench-followup"
      refute_includes html, "Experimental follow-up"

      about = html[/<section class="bench-intro">.*?<\/section>/m]
      summary = html[/<table class="bench-table bench-summary-table".*?<\/table>/m]
      efficiency = html[/<table class="bench-table bench-matrix bench-responsive-matrix bench-efficiency-matrix">.*?<\/table>/m]
      scores = html[/<table class="bench-table bench-matrix bench-responsive-matrix bench-score-matrix">.*?<\/table>/m]

      refute_nil about
      assert_includes about, "90 generation cells"
      assert_match(/15 candidates\s+&times; 6 tasks/, about)
      assert_match(/Fable ran with reasoning enabled.*?first three campaign records pin <code>xhigh<\/code>.*?DeepSeek and GLM 5.3 Flash \(0x Alpha\) campaigns record it as unspecified/m, about)
      assert_includes about, "Deliberation is not a third judge"
      assert_match(/GLM 5.3 Flash \(0x Alpha\) via Pi high and Pi max have independent paired\s+means of <strong>5\.05<\/strong> and\s+<strong>5\.036<\/strong>.*?finish at\s+<strong>5\.692<\/strong> and\s+<strong>5\.483<\/strong>/m, about)
      assert_match(/production-like Sol plan &rarr; Sol execute &rarr; Sol \+ Grok review setup\s+remains first at <strong>7\.525<\/strong>/m, about)
      assert_match(/DeepSeek configurations\s+finish at <strong>5\.892<\/strong> and\s+<strong>5\.783<\/strong>/m, about)
      assert_match(/Both\s+judgments are family-disjoint/m, about)
      assert_match(/differ by\s+<strong>4\.483<\/strong> points for all-Pro and\s+<strong>2\.994<\/strong>/m, about)
      assert_match(/spread still fell from\s+<strong>2\.082<\/strong> to\s+<strong>1\.251<\/strong>/m, about)
      assert_match(/all-Pro averages \$0\.55\s+across five priced cells.*?Pro\/Flash\/Pro averages\s+\$0\.6 across all\s+six/m, about)
      assert_match(/50\.754M and\s+34\.774M per recorded\s+task/m, about)
      assert_match(/Pi max campaign averages\s+\$6\.94 per task across\s+all six priced cells and 33\.343M\s+normalized tokens per task/m, about)
      assert_match(/wall-time mean is\s+95\.5 minutes across\s+5 recorded cells/m, about)

      [summary, efficiency, scores].each do |table|
        refute_nil table
        assert_equal 15, table[/<tbody>.*?<\/tbody>/m].scan("<tr").length
      end
      summary_labels = summary.scan(/<th scope="row">\s*<code>([^<]+)<\/code>/m).flatten
      candidate_labels = DATA.fetch("candidates").to_h do |candidate|
        [candidate.fetch("id"), candidate.fetch("label")]
      end
      expected_discussion_labels = DATA.dig("discussion_adjusted", "candidates")
                                           .sort_by { |candidate| -candidate.dig("combined", "mean") }
                                           .map { |candidate| candidate_labels.fetch(candidate.fetch("id")) }
      assert_equal expected_discussion_labels, summary_labels
      [efficiency, scores].each do |table|
        labels = table.scan(/<th scope="row">\s*<code>([^<]+)<\/code>/m).flatten
        assert_equal RANKED_LABELS, labels
      end

      assert_equal 9, summary.scan("scores + public diffs").length
      assert_equal 9, summary.scan("3 samples/judge").length
      assert_equal 0, scores.scan("diff not public").length
      assert_equal 54, scores.scan("3 samples/judge").length
      assert_equal 90, scores.scan("discussion final").length
      assert_equal 90, scores.scan(">diff</a>").length

      assert_equal 1, summary.scan(/data-sort-key="discussion"[^>]*>After discussion/).length
      assert_includes summary, 'data-sort-key="discussion"'
      assert_match(/<option value="discussion" selected(?:="")?>After-discussion score<\/option>/,
                   html)
      assert_match(/aria-sort="descending"><button class="bench-sort-button" type="button" data-sort-key="discussion".*?↓/m,
                   summary)
      assert_match(/aria-sort="none"><button class="bench-sort-button" type="button" data-sort-key="combined"/,
                   summary)
      discussion_values = summary.scan(/data-sort-discussion="([0-9.]+)"/).flatten.map(&:to_f)
      assert_equal 15, discussion_values.length
      assert_equal discussion_values.sort.reverse, discussion_values
      assert_equal 0, summary.scan('data-sort-discussion=""').length
      assert_equal 0, summary.scan("not run").length
      assert_includes summary, "Sol ultra/xhigh"
      refute_includes summary, "xhigh / ultra"
      assert_equal 0, summary.scan("discussion final").length

      discussion_note = html[/<p class="bench-meta bench-discussion-note">.*?<\/p>/m]
      refute_nil discussion_note
      assert_includes discussion_note, "one-shot diagnostic"
      assert_match(/six original rows reused their exact published independent\s+verdicts and recovered rationales/,
                   discussion_note)
      assert_match(/nine rows across the five active\s+later three-seed campaigns received fresh round-one re-grades/,
                   discussion_note)
      assert_match(/In all six\s+active campaigns, each judge then saw the other anonymous verdict/,
                   discussion_note)
      assert_match(/All fifteen rows/, discussion_note)
      assert_includes discussion_note, "90 paired cells"
      assert_match(/After discussion is the\s+default table sort/, discussion_note)
      refute_includes discussion_note, "not run"
      refute_includes discussion_note, "uncovered rows"

      RANKED_LABELS.first(3).drop(1).each do |label|
        row = scores[/<tr>\s*<th scope="row"><code>#{Regexp.escape(label)}<\/code>.*?<\/tr>/m]
        refute_nil row
        assert_equal 6, row.scan(">diff</a>").length
      end
      fable_row = scores[/<tr>\s*<th scope="row"><code>Fable plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      refute_nil fable_row
      assert_equal 6, fable_row.scan(">diff</a>").length

      fable_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>Fable plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      refute_nil fable_summary
      assert_includes fable_summary, "9.24M known*"
      refute_includes fable_summary, "6/6 measured · partial"
      refute_includes fable_summary, "Fable plan + Sol review only · Grok telemetry unavailable"
      assert_includes fable_summary, "$7.10 known*"
      refute_includes fable_summary, "6/6 known · partial"

      sol_grok_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>Sol plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      refute_nil sol_grok_summary
      assert_includes sol_grok_summary, "29.123M known*"
      refute_includes sol_grok_summary, "6/6 measured · partial"
      refute_includes sol_grok_summary, "Sol plan/review only · Grok telemetry unavailable"
      assert_includes sol_grok_summary, "$21.35 known*"
      refute_includes sol_grok_summary, "6/6 known · partial"

      flagship_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>Sol plan → Sol execute → Sol \+ Grok review<\/code>.*?<\/tr>/m]
      refute_nil flagship_summary
      assert_includes flagship_summary, "63.156M known*"
      assert_includes flagship_summary, "$42.94 known*"
      assert_includes flagship_summary, "7.525"
      assert_includes flagship_summary, "Fable 7.917 · Sol 7.133"
      assert_includes flagship_summary, "6/6 paired"
      refute_includes flagship_summary, "Sol stages only · Grok reviewer telemetry unavailable"

      terra_grok_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>Sol plan → Terra execute → Grok review<\/code>.*?<\/tr>/m]
      refute_nil terra_grok_summary
      assert_includes terra_grok_summary, "26.229M known*"
      assert_includes terra_grok_summary, "$18.63 known*"
      assert_includes terra_grok_summary, "5.717"
      assert_includes terra_grok_summary, "Fable 6.517 · Sol 4.917"
      assert_includes terra_grok_summary, "6/6 paired"
      refute_includes terra_grok_summary, "Sol plan + Terra execute only · Grok review telemetry unavailable"

      all_deepseek_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>DeepSeek V4 Pro 0813 xhigh<\/code>.*?<\/tr>/m]
      refute_nil all_deepseek_summary
      assert_includes all_deepseek_summary, "5.892"
      assert_includes all_deepseek_summary, "Fable 6.833 · Sol 4.95"
      assert_includes all_deepseek_summary, "$0.55"
      assert_includes all_deepseek_summary, "5/6 priced"
      assert_includes all_deepseek_summary, "50.754M"
      assert_includes all_deepseek_summary, "5/6 timed"
      assert_includes all_deepseek_summary, "5/6 measured"
      refute_includes all_deepseek_summary, "bench-family-badge"

      mixed_deepseek_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>DeepSeek V4 Pro plan → V4 Flash execute → V4 Pro review<\/code>.*?<\/tr>/m]
      refute_nil mixed_deepseek_summary
      assert_includes mixed_deepseek_summary, "5.783"
      assert_includes mixed_deepseek_summary, "Fable 6.75 · Sol 4.817"
      assert_includes mixed_deepseek_summary, "$0.6"
      assert_includes mixed_deepseek_summary, "6/6 priced"
      assert_includes mixed_deepseek_summary, "34.774M"
      assert_includes mixed_deepseek_summary, "6/6 measured"
      refute_includes mixed_deepseek_summary, "bench-family-badge"

      ox_pi_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>GLM 5.3 Flash \(0x Alpha\) via Pi high<\/code>.*?<\/tr>/m]
      refute_nil ox_pi_summary
      assert_includes ox_pi_summary, "5.692"
      assert_includes ox_pi_summary, "Fable 6.333 · Sol 5.05"
      assert_includes ox_pi_summary, "19.838M"
      assert_includes ox_pi_summary, "4/6 timed"
      assert_includes ox_pi_summary, "6/6 measured"
      assert_includes ox_pi_summary, "unknown"
      refute_includes ox_pi_summary, "bench-family-badge"

      ox_pi_max_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>GLM 5.3 Flash \(0x Alpha\) via Pi max<\/code>.*?<\/tr>/m]
      refute_nil ox_pi_max_summary
      assert_includes ox_pi_max_summary, "5.483"
      assert_includes ox_pi_max_summary, "Fable 6.5 · Sol 4.467"
      assert_includes ox_pi_max_summary, "33.343M"
      assert_includes ox_pi_max_summary, "5/6 timed"
      assert_includes ox_pi_max_summary, "6/6 measured"
      assert_includes ox_pi_max_summary, "$6.9381"
      assert_includes ox_pi_max_summary, "6/6 priced"
      refute_includes ox_pi_max_summary, "bench-family-badge"
      refute_includes summary, "GLM 5.3 Flash (0x Alpha) via OpenCode high"

      fable_efficiency = efficiency[/<tr>\s*<th scope="row"><code>Fable plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      sol_grok_efficiency = efficiency[/<tr>\s*<th scope="row"><code>Sol plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      refute_includes fable_efficiency, "Known-provider tokens"
      refute_includes sol_grok_efficiency, "Known-provider tokens"
      refute_includes fable_efficiency, "Sol tokens unavailable"
      assert_equal 6, fable_efficiency.scan(/\$[\d.]+ known\*/).length
      assert_equal 6, sol_grok_efficiency.scan(/\$[\d.]+ known\*/).length
      assert_equal 6, fable_efficiency.scan("known* tokens").length
      assert_equal 6, sol_grok_efficiency.scan("known* tokens").length
      refute_includes fable_efficiency, "known-provider cost · partial"
      refute_includes sol_grok_efficiency, "known-provider cost · partial"
      refute_match(%r{</button></span>\s*</small><br>\s*<small>Fable plan \+ Sol review only},
                   fable_efficiency)
      refute_match(%r{</button></span>\s*</small><br>\s*<small>Sol plan/review only},
                   sol_grok_efficiency)
      assert_equal 6, fable_efficiency.scan("Fable plan + Sol review only · Grok telemetry unavailable · Fresh input").length
      assert_equal 6, sol_grok_efficiency.scan("Sol plan/review only · Grok telemetry unavailable · Fresh input").length

      flagship_efficiency = efficiency[/<tr>\s*<th scope="row"><code>Sol plan → Sol execute → Sol \+ Grok review<\/code>.*?<\/tr>/m]
      terra_grok_efficiency = efficiency[/<tr>\s*<th scope="row"><code>Sol plan → Terra execute → Grok review<\/code>.*?<\/tr>/m]
      refute_nil flagship_efficiency
      refute_nil terra_grok_efficiency
      assert_equal 6, flagship_efficiency.scan(/\$[\d.]+ known\*/).length
      assert_equal 6, terra_grok_efficiency.scan(/\$[\d.]+ known\*/).length
      assert_equal 6, flagship_efficiency.scan("known* tokens").length
      assert_equal 6, terra_grok_efficiency.scan("known* tokens").length
      assert_equal 6, flagship_efficiency.scan("Sol stages only · Grok reviewer telemetry unavailable · Fresh input").length
      assert_equal 6, terra_grok_efficiency.scan("Sol plan + Terra execute only · Grok review telemetry unavailable · Fresh input").length

      all_deepseek_efficiency = efficiency[/<tr>\s*<th scope="row"><code>DeepSeek V4 Pro 0813 xhigh<\/code>.*?<\/tr>/m]
      mixed_deepseek_efficiency = efficiency[/<tr>\s*<th scope="row"><code>DeepSeek V4 Pro plan → V4 Flash execute → V4 Pro review<\/code>.*?<\/tr>/m]
      refute_nil all_deepseek_efficiency
      refute_nil mixed_deepseek_efficiency
      assert_equal 5, all_deepseek_efficiency.scan(/<strong>\$[\d.]+<\/strong>/).length
      assert_equal 1, all_deepseek_efficiency.scan("cost unknown").length
      assert_equal 5, all_deepseek_efficiency.scan(/<strong>[\d.]+M <\/strong>/).length
      assert_equal 1, all_deepseek_efficiency.scan("tokens unknown").length
      assert_equal 6, mixed_deepseek_efficiency.scan(/<strong>\$[\d.]+<\/strong>/).length
      assert_equal 6, mixed_deepseek_efficiency.scan(/<strong>[\d.]+M <\/strong>/).length

      ox_pi_efficiency = efficiency[/<tr>\s*<th scope="row"><code>GLM 5.3 Flash \(0x Alpha\) via Pi high<\/code>.*?<\/tr>/m]
      refute_nil ox_pi_efficiency
      assert_equal 6, ox_pi_efficiency.scan("cost unknown").length
      assert_equal 6, ox_pi_efficiency.scan(/<strong>[\d.]+M <\/strong>/).length
      assert_equal 2, ox_pi_efficiency.scan("time not recorded").length

      ox_pi_max_efficiency = efficiency[/<tr>\s*<th scope="row"><code>GLM 5.3 Flash \(0x Alpha\) via Pi max<\/code>.*?<\/tr>/m]
      refute_nil ox_pi_max_efficiency
      assert_equal 6, ox_pi_max_efficiency.scan(/<strong>\$[\d.]+<\/strong>/).length
      assert_equal 6, ox_pi_max_efficiency.scan(/<strong>[\d.]+M <\/strong>/).length
      assert_equal 1, ox_pi_max_efficiency.scan("time not recorded").length
      refute_includes efficiency, "GLM 5.3 Flash (0x Alpha) via OpenCode high"

      telemetry_note = html[/<p class="bench-meta bench-telemetry-note">.*?<\/p>/m]
      refute_nil telemetry_note
      telemetry_text = telemetry_note.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip
      assert_includes telemetry_text, "Known* values include only providers with preserved telemetry"
      assert_includes telemetry_text, "Grok telemetry is unavailable"
      assert_includes telemetry_text, "DeepSeek's Pi/OpenRouter rows have complete provider scope"
      assert_includes telemetry_text, "GLM 5.3 Flash (0x Alpha) via Pi high preserves complete token telemetry"
      assert_includes telemetry_text, "no published API-equivalent price"
      assert_includes telemetry_text, "Pi max preserves complete token and cost telemetry for all six cells"

      assert_includes sol_grok_summary, "7.383"
      assert_includes sol_grok_summary, "Fable 7.383 · Sol 6.433"
      assert_includes sol_grok_summary, "6/6 paired"
      assert_includes fable_summary, "6.05"
      assert_includes fable_summary, "Fable 6.583 · Sol 5.517"
      assert_includes fable_summary, "6/6 paired"
      assert_equal 6, fable_row.scan("discussion final").length
      assert_match(/discussion final · Fable\s+6\.5 · Sol\s+5\.6/, fable_row)
      refute_includes fable_row, "unavailable"

      all_sol_row = scores[/<tr>\s*<th scope="row"><code>GPT-5.6 Sol xhigh<\/code>.*?<\/tr>/m]
      refute_nil all_sol_row
      assert_equal 6, all_sol_row.scan("discussion final").length
      assert_match(/discussion final · Fable\s+5\.5 · Sol\s+4\.5/, all_sol_row)

      flagship_row = scores[/<tr>\s*<th scope="row"><code>Sol plan → Sol execute → Sol \+ Grok review<\/code>.*?<\/tr>/m]
      refute_nil flagship_row
      assert_equal 6, flagship_row.scan("discussion final").length
      assert_equal 6, flagship_row.scan(">diff</a>").length
      assert_match(/discussion final · Fable\s+9\.0 · Sol\s+9\.2/, flagship_row)
      assert_includes html, "one-shot diagnostic"

      css = File.read(File.join(ROOT, "assets", "css", "landing.scss"), encoding: Encoding::UTF_8)
      assert_match(/\.bench-summary-table thead th,\s*\.bench-sort-button \{ white-space: nowrap; \}/, css)
      assert_includes css, ".bench-summary-table { margin-bottom: 0; min-width: 64rem; }"
      expected_family_badges = DATA.fetch("primary_judges").sum do |judge|
        judge.fetch("rows").count { |row| row.fetch("same_family") }
      end
      family_badges = summary.scan(
        /<span class="bench-prelim bench-family-badge" tabindex="0"\s+data-bench-tooltip="Same-family judge: [^"]+">SF<\/span>/m
      )
      assert_equal expected_family_badges, family_badges.length
      expected_fable_badges = DATA.fetch("primary_judges")
                                  .find { |judge| judge.fetch("id") == "fable-5" }
                                  .fetch("rows")
                                  .count { |row| row.fetch("same_family") }
      expected_sol_badges = DATA.fetch("primary_judges")
                                .find { |judge| judge.fetch("id") == "gpt-5.6-sol" }
                                .fetch("rows")
                                .count { |row| row.fetch("same_family") }
      assert_equal(
        expected_fable_badges,
        summary.scan('data-bench-tooltip="Same-family judge: Fable shares a model family with the candidate."').length
      )
      assert_equal(
        expected_sol_badges,
        summary.scan('data-bench-tooltip="Same-family judge: Sol shares a model family with the candidate."').length
      )
      assert_equal(
        1,
        about.scan('data-bench-tooltip="Same-family judge: this judge shares a model family with the candidate."').length
      )
      assert_match(/\.bench-family-badge\s*\{[^}]*white-space:\s*nowrap;/m, css)
      assert_match(/\.bench-family-badge:focus-visible\s*\{[^}]*outline:/m, css)

      rendered_snapshot = JSON.parse(File.binread(File.join(destination, "bench", "results.json")))
      assert_equal DATA, rendered_snapshot
    end
  end
end
