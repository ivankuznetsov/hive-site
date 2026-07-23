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
    }
  }.freeze
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
    assert_equal 8, DATA.fetch("schema_version")
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
        assert_match %r{\A/bench/patches/v3-mixed-workflows-three-seed-20260713/[^/]+/#{task_key}\.patch\z},
                     cell.fetch("patch_url")
        assert_path_exists File.join(ROOT, cell.fetch("patch_url").delete_prefix("/"))
      end
    end

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
    assert_equal %w[v2-ce v3-mixed-workflows-three-seed-20260713],
                 discussion.fetch("source_campaign_ids")
    assert_equal 54, discussion.dig("coverage", "cells")
    assert_equal 54, discussion.dig("coverage", "expected_cells")
    assert_equal 108, discussion.dig("coverage", "judge_decisions")
    assert_equal 108, discussion.dig("coverage", "expected_judge_decisions")
    assert_equal 54, discussion.dig("coverage", "fully_adjusted_cells")
    assert_empty discussion.dig("coverage", "missing")

    summary = discussion.fetch("summary")
    discussion_cells = discussion.fetch("candidates").flat_map do |candidate|
      candidate.fetch("cells").values
    end
    assert_equal 54, discussion_cells.length
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

    assert_in_delta(-0.763, summary.dig("mean_revision_by_judge", "fable-5"), 0.001)
    assert_in_delta(-0.156, summary.dig("mean_revision_by_judge", "gpt-5.6-sol"), 0.001)
    assert_in_delta 0.781, summary.dig("mean_abs_revision_by_judge", "fable-5"), 0.001
    assert_in_delta 0.281, summary.dig("mean_abs_revision_by_judge", "gpt-5.6-sol"), 0.001
    assert_in_delta 1.702, summary.fetch("mean_spread_before"), 0.001
    assert_in_delta 0.998, summary.fetch("mean_spread_after"), 0.001

    discussion_candidates = discussion.fetch("candidates").to_h { |candidate| [candidate.fetch("id"), candidate] }
    assert_equal 9, discussion_candidates.length
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
    assert_equal 54, fixture_cells.length
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

      assert_equal 3, summary.scan("scores + public diffs").length
      assert_equal 3, summary.scan("3 samples/judge").length
      assert_equal 0, scores.scan("diff not public").length
      assert_equal 18, scores.scan("3 samples/judge").length
      assert_equal 54, scores.scan("discussion final").length
      assert_equal 54, scores.scan(">diff</a>").length

      assert_equal 1, summary.scan(/data-sort-key="discussion"[^>]*>After discussion/).length
      assert_includes summary, 'data-sort-key="discussion"'
      assert_includes html, '<option value="discussion">After-discussion score</option>'
      assert_equal 9, summary.scan(/data-sort-discussion="[0-9]/).length
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
      assert_match(/three mixed-workflow rows received\s+fresh round-one re-grades/, discussion_note)
      assert_match(/In both campaigns, each judge then saw the other\s+anonymous verdict/, discussion_note)
      assert_match(/All\s+nine rows/, discussion_note)
      assert_includes discussion_note, "54 paired cells"
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
      assert_includes fable_summary, "9.24M"
      assert_includes fable_summary, "6/6 measured · partial"
      assert_includes fable_summary, "Fable plan + Sol review only · Grok telemetry unavailable"
      assert_includes fable_summary, "$7.10 known"
      assert_includes fable_summary, "6/6 known · partial"

      sol_grok_summary = summary[/<tr[^>]*>\s*<th scope="row">\s*<code>Sol plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      refute_nil sol_grok_summary
      assert_includes sol_grok_summary, "29.123M"
      assert_includes sol_grok_summary, "6/6 measured · partial"
      assert_includes sol_grok_summary, "Sol plan/review only · Grok telemetry unavailable"
      assert_includes sol_grok_summary, "$21.35 known"

      fable_efficiency = efficiency[/<tr>\s*<th scope="row"><code>Fable plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      sol_grok_efficiency = efficiency[/<tr>\s*<th scope="row"><code>Sol plan → Grok execute → Sol review<\/code>.*?<\/tr>/m]
      assert_equal 6, fable_efficiency.scan("Known-provider tokens").length
      assert_equal 6, sol_grok_efficiency.scan("Known-provider tokens").length
      refute_includes fable_efficiency, "Sol tokens unavailable"
      assert_includes fable_efficiency, "Grok telemetry unavailable"
      assert_includes sol_grok_efficiency, "Grok telemetry unavailable"

      assert_includes sol_grok_summary, "7.383"
      assert_includes sol_grok_summary, "Fable 7.383 · Sol 6.433"
      assert_includes sol_grok_summary, "6/6 paired"
      assert_includes fable_summary, "6.05"
      assert_includes fable_summary, "Fable 6.583 · Sol 5.517"
      assert_includes fable_summary, "6/6 paired"
      assert_equal 6, fable_row.scan("discussion final").length
      assert_match(/discussion final · Fable\s+6\.5 · Sol\s+5\.6/, fable_row)
      refute_includes fable_row, "unavailable"

      flagship_row = scores[/<tr>\s*<th scope="row"><code>GPT-5.6 Sol xhigh<\/code>.*?<\/tr>/m]
      refute_nil flagship_row
      assert_equal 6, flagship_row.scan("discussion final").length
      assert_match(/discussion final · Fable\s+5\.5 · Sol\s+4\.5/, flagship_row)
      assert_includes html, "one-shot diagnostic"

      css = File.read(File.join(ROOT, "assets", "css", "landing.scss"), encoding: Encoding::UTF_8)
      assert_match(/\.bench-summary-table thead th,\s*\.bench-sort-button \{ white-space: nowrap; \}/, css)
      assert_includes css, ".bench-summary-table { margin-bottom: 0; min-width: 64rem; }"

      rendered_snapshot = JSON.parse(File.binread(File.join(destination, "bench", "results.json")))
      assert_equal DATA, rendered_snapshot
    end
  end
end
