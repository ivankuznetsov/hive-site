# frozen_string_literal: true

require_relative "test_helper"
require "open3"

class BenchmarkDataTest < Minitest::Test
  DATA = JSON.parse(File.read(File.join(ROOT, "_data", "bench.json")))
  FOLLOWUP_IDS = [
    "fable-plan->grok-exec-sol-review",
    "sol-plan->grok-exec-sol-review",
    "sol-plan->terra-exec-sol-review"
  ].freeze
  RANKED_LABELS = [
    "GPT-5.6 Sol xhigh",
    "Sol plan → Grok execute → Sol review",
    "Sol plan → Terra execute → Sol review",
    "Opus plan → Codex 5.5 xhigh",
    "Fable plan → Grok execute → Sol review",
    "Grok 4.5 xhigh",
    "Opus 4.8",
    "Codex 5.5 xhigh",
    "GLM 5.2"
  ].freeze

  def test_completed_followup_expands_the_existing_board
    assert_equal 7, DATA.fetch("schema_version")
    assert_equal 54, DATA.dig("coverage", "cells")
    assert_equal 54, DATA.dig("coverage", "expected_cells")
    assert_equal 9, DATA.dig("coverage", "candidates")
    assert_equal 9, DATA.fetch("candidates").length

    DATA.fetch("primary_judges").each do |judge|
      assert_equal 9, judge.fetch("rows").length
    end

    FOLLOWUP_IDS.each do |candidate_id|
      candidate = DATA.fetch("candidates").find { |row| row.fetch("id") == candidate_id }

      refute_nil candidate
      assert_equal "v3-mixed-workflows-three-seed-20260713", candidate.fetch("campaign_id")
      assert_equal 3, candidate.fetch("samples_per_cell")
      assert_equal 6, candidate.fetch("completed")
      assert_equal 6, candidate.fetch("cells").length
      assert_equal false, candidate.fetch("raw_evidence_published")

      candidate.fetch("cells").each_value do |cell|
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
        assert_nil cell["patch_url"]
      end
    end

    fable_candidate = DATA.fetch("candidates").find do |candidate|
      candidate.fetch("id") == "fable-plan->grok-exec-sol-review"
    end
    assert_nil fable_candidate.fetch("cost_per_task_usd")
    assert_nil fable_candidate.fetch("cost_total_usd")
    assert_equal 0, fable_candidate.fetch("cost_sample")
    assert fable_candidate.fetch("efficiency_by_task").values.all? { |task| task["cost_usd"].nil? }
    assert_equal 18.026, fable_candidate.fetch("normalized_mtokens_per_task")
    assert_equal 2, fable_candidate.fetch("token_sample")
    assert_equal "Sol review only · Fable plan excluded · Grok telemetry unavailable",
                 fable_candidate.fetch("token_scope")
    assert_equal %w[add-i-key fix-review], fable_candidate.fetch("efficiency_by_task").filter_map { |task, stat|
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
    assert sol_grok_candidate.fetch("efficiency_by_task").values.all? { |task| task["tokens"] }

    [fable_candidate, sol_grok_candidate].each do |candidate|
      measured = candidate.fetch("efficiency_by_task").values.select { |task| task["tokens"] }
      %w[input output cache_read cache_write].each do |bucket|
        assert_equal measured.sum { |task| task.dig("tokens", bucket) }, candidate.dig("token_totals", bucket)
      end
      mean = measured.sum { |task| task.fetch("normalized_mtokens") } / measured.length
      assert_in_delta mean, candidate.fetch("normalized_mtokens_per_task"), 0.001
    end

    discussion = DATA.fetch("discussion_adjusted")
    assert_equal "diagnostic", discussion.fetch("status")
    assert_equal 18, discussion.dig("coverage", "cells")
    assert_equal 18, discussion.dig("coverage", "expected_cells")
    assert_equal 36, discussion.dig("coverage", "judge_decisions")
    assert_equal 36, discussion.dig("coverage", "expected_judge_decisions")
    assert_equal 18, discussion.dig("coverage", "fully_adjusted_cells")
    assert_empty discussion.dig("coverage", "missing")
    assert_equal(-0.778, discussion.dig("summary", "mean_revision_by_judge", "fable-5"))
    assert_equal(-0.061, discussion.dig("summary", "mean_revision_by_judge", "gpt-5.6-sol"))
    assert_equal 2.044, discussion.dig("summary", "mean_spread_before")
    assert_equal 1.328, discussion.dig("summary", "mean_spread_after")

    discussion_candidates = discussion.fetch("candidates").to_h { |candidate| [candidate.fetch("id"), candidate] }
    assert_equal [6.583, 6, 6], discussion_candidates.dig("fable-plan->grok-exec-sol-review", "fable").values_at("mean", "sample", "total")
    assert_equal [5.517, 6, 6], discussion_candidates.dig("fable-plan->grok-exec-sol-review", "sol").values_at("mean", "sample", "total")
    assert_equal [6.05, 6, 6], discussion_candidates.dig("fable-plan->grok-exec-sol-review", "combined").values_at("mean", "sample", "total")
    assert_equal [7.383, 6, 6], discussion_candidates.dig("sol-plan->grok-exec-sol-review", "fable").values_at("mean", "sample", "total")
    assert_equal [6.433, 6, 6], discussion_candidates.dig("sol-plan->grok-exec-sol-review", "sol").values_at("mean", "sample", "total")
    assert_equal [6.908, 6, 6], discussion_candidates.dig("sol-plan->grok-exec-sol-review", "combined").values_at("mean", "sample", "total")
    assert_equal [7.45, 6, 6], discussion_candidates.dig("sol-plan->terra-exec-sol-review", "fable").values_at("mean", "sample", "total")
    assert_equal [5.483, 6, 6], discussion_candidates.dig("sol-plan->terra-exec-sol-review", "sol").values_at("mean", "sample", "total")
    assert_equal [6.467, 6, 6], discussion_candidates.dig("sol-plan->terra-exec-sol-review", "combined").values_at("mean", "sample", "total")
    assert_equal 5.6, discussion_candidates.dig("fable-plan->grok-exec-sol-review", "cells", "daemon", "sol", "final")
    assert_equal 6.5, discussion_candidates.dig("fable-plan->grok-exec-sol-review", "cells", "daemon", "fable", "final")

    terra_candidate = DATA.fetch("candidates").find do |candidate|
      candidate.fetch("id") == "sol-plan->terra-exec-sol-review"
    end
    assert_equal 26.12, terra_candidate.fetch("cost_per_task_usd")
    assert_equal 5, terra_candidate.fetch("cost_sample")
    assert_equal 34.807, terra_candidate.fetch("normalized_mtokens_per_task")
    assert_equal 5, terra_candidate.fetch("token_sample")
    assert_nil terra_candidate.dig("efficiency_by_task", "fix-review", "cost_usd")
    assert_nil terra_candidate.dig("efficiency_by_task", "fix-review", "tokens")
    assert_equal 35, DATA.dig("efficiency_accounting", "priced_cells")
    assert_equal 5, DATA.dig("efficiency_accounting", "followup_priced_cells")

    DATA.fetch("primary_judges").each do |judge|
      FOLLOWUP_IDS.each do |candidate_id|
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

      summary = html[/<table class="bench-table bench-summary-table".*?<\/table>/m]
      efficiency = html[/<table class="bench-table bench-matrix bench-responsive-matrix bench-efficiency-matrix">.*?<\/table>/m]
      scores = html[/<table class="bench-table bench-matrix bench-responsive-matrix bench-score-matrix">.*?<\/table>/m]

      [summary, efficiency, scores].each do |table|
        refute_nil table
        assert_equal 9, table[/<tbody>.*?<\/tbody>/m].scan("<tr").length
        labels = table.scan(/<th scope="row">\s*<code>([^<]+)<\/code>/m).flatten
        assert_equal RANKED_LABELS, labels
      end

      assert_equal 3, summary.scan("site snapshot evidence").length
      assert_equal 3, summary.scan("3 samples/judge").length
      assert_equal 18, scores.scan("diff not public").length
      assert_equal 18, scores.scan("3 samples/judge").length
      assert_equal 18, scores.scan("discussion final").length
      assert_equal 36, scores.scan(">diff</a>").length

      RANKED_LABELS.first(3).drop(1).each do |label|
        row = scores[/<tr>\s*<th scope="row"><code>#{Regexp.escape(label)}<\/code>.*?<\/tr>/m]
        refute_nil row
        refute_includes row, ">diff</a>"
      end
      fable_row = scores[/<tr>\s*<th scope="row"><code>Fable plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      refute_nil fable_row
      refute_includes fable_row, ">diff</a>"

      fable_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>Fable plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      refute_nil fable_summary
      assert_includes fable_summary, "18.026M"
      assert_includes fable_summary, "2/6 measured · partial"
      assert_includes fable_summary, "Sol review only · Fable plan excluded · Grok telemetry unavailable"

      sol_grok_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>Sol plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      refute_nil sol_grok_summary
      assert_includes sol_grok_summary, "29.123M"
      assert_includes sol_grok_summary, "6/6 measured · partial"
      assert_includes sol_grok_summary, "Sol plan/review only · Grok telemetry unavailable"

      fable_efficiency = efficiency[/<tr>\s*<th scope="row"><code>Fable plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      sol_grok_efficiency = efficiency[/<tr>\s*<th scope="row"><code>Sol plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      assert_equal 2, fable_efficiency.scan("Sol-only tokens").length
      assert_equal 6, sol_grok_efficiency.scan("Sol-only tokens").length
      assert_includes fable_efficiency, "Grok telemetry unavailable"
      assert_includes sol_grok_efficiency, "Grok telemetry unavailable"

      assert_includes sol_grok_summary, "discussion final 7.383 · 6/6"
      assert_includes sol_grok_summary, "discussion final 6.433 · 6/6"
      assert_includes sol_grok_summary, "discussion final 6.908 · 6/6 paired"
      assert_includes fable_summary, "discussion final 6.583 · 6/6"
      assert_includes fable_summary, "discussion final 5.517 · 6/6"
      assert_includes fable_summary, "discussion final 6.05 · 6/6 paired"
      assert_equal 6, fable_row.scan("discussion final").length
      assert_includes fable_row, "6.5 /"
      assert_includes fable_row, "5.6"
      refute_includes fable_row, "unavailable"
      assert_includes html, "a separate one-shot diagnostic"

      rendered_snapshot = JSON.parse(File.binread(File.join(destination, "bench", "results.json")))
      assert_equal DATA, rendered_snapshot
    end
  end
end
