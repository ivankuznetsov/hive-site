# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
SOURCE_SHA = "a" * 40

module CatalogFixtures
  module_function

  def catalog(entries = [])
    {"schema" => "honeycomb-catalog/v2", "entries" => entries}
  end

  def entry(name: "example", version: "1.0.0", tier: "community", risk: "moderate",
            state: "listed", community_reviews: nil, description: "A useful honeycomb")
    head_sha = "b" * 40
    release_sha = "c" * 64
    reviewer_count = risk == "high" ? 2 : 1
    reviewers = Array.new(reviewer_count) { |index| "maintainer-#{index + 1}" }
    reviews = reviewers.each_with_index.map do |reviewer, index|
      {
        "reviewer" => reviewer,
        "reviewed_at" => "2026-07-17T12:0#{index}:00Z",
        "review_url" => "https://github.com/ivankuznetsov/honeycomb/pull/#{index + 10}#pullrequestreview-#{index + 100}",
        "evidence_digest" => ((index + 1).to_s * 64)[0, 64]
      }
    end
    permissions = if risk == "high"
                    {
                      "risk" => "high",
                      "capabilities" => %w[filesystem-read filesystem-write network shell],
                      "network_hosts" => ["*"],
                      "filesystem_read" => ["*"],
                      "filesystem_write" => ["*"],
                      "secrets" => ["*"]
                    }
                  else
                    {
                      "risk" => risk,
                      "capabilities" => %w[filesystem-read filesystem-write],
                      "network_hosts" => [],
                      "filesystem_read" => ["repository"],
                      "filesystem_write" => ["task/state.json"],
                      "secrets" => []
                    }
                  end
    advisories = if state == "revoked"
                   [{
                     "id" => "HC-2026-001",
                     "title" => "Revoked release",
                     "severity" => "high",
                     "url" => "https://github.com/ivankuznetsov/honeycomb/security/advisories/GHSA-test",
                     "published_at" => "2026-07-17T14:00:00Z"
                   }]
                 else
                   []
                 end

    {
      "name" => name,
      "version" => version,
      "latest_version" => state == "listed" ? version : nil,
      "description" => description,
      "release_tier" => tier,
      "current_tier" => tier,
      "permission_risk" => risk,
      "state" => state,
      "discoverable" => state == "listed",
      "exact_resolution" => state == "revoked" ? "blocked" : "allowed",
      "verification" => tier == "verified" ? verification : nil,
      "history" => lifecycle_history(state),
      "advisories" => advisories,
      "author" => {"name" => "Example Author", "url" => "https://example.test/author"},
      "license" => "MIT",
      "hive_min_version" => "0.4.3",
      "permissions" => permissions,
      "install_command" => "hive workflow install honeycomb/#{name}",
      "package_url" => "https://github.com/ivankuznetsov/honeycomb/tree/main/packages/#{name}/#{version}",
      "reviews_url" => reviews.first.fetch("review_url"),
      "community_reviews_url" => community_reviews,
      "source_sha" => "d" * 40,
      "listing_approval" => {
        "release_sha256" => release_sha,
        "head_sha" => head_sha,
        "lint_checked_at" => "2026-07-17T11:00:00Z",
        "approved_by" => reviewers,
        "approved_at" => reviews.last.fetch("reviewed_at"),
        "reviews" => reviews
      }
    }
  end

  def lifecycle_history(state)
    return [] if state == "listed"

    [{
      "kind" => "state", "from" => "listed", "to" => state,
      "changed_at" => "2026-07-17T13:00:00Z", "actor" => "registry-maintainer",
      "reason" => "Lifecycle fixture",
      "url" => "https://github.com/ivankuznetsov/honeycomb/issues/1"
    }]
  end

  def verification
    workflow = "ivankuznetsov/honeycomb/.github/workflows/release.yml@refs/tags/v1.0.0"
    {
      "archive_sha256" => "e" * 64,
      "signature" => {
        "identity" => "https://github.com/#{workflow}",
        "issuer" => "https://token.actions.githubusercontent.com",
        "url" => "https://search.sigstore.dev/entry/123"
      },
      "attestation" => {
        "repository" => "ivankuznetsov/honeycomb", "workflow" => workflow,
        "url" => "https://github.com/ivankuznetsov/honeycomb/attestations/123"
      },
      "verified_at" => "2026-07-17T10:00:00Z"
    }
  end

  def write_catalog(directory, document, raw: nil)
    path = File.join(directory, "catalog.json")
    File.binwrite(path, raw || JSON.pretty_generate(document) + "\n")
    path
  end

  def deep_copy(value)
    Marshal.load(Marshal.dump(value))
  end
end
