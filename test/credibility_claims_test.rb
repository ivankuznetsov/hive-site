# frozen_string_literal: true

require_relative "test_helper"

class CredibilityClaimsTest < Minitest::Test
  def test_public_templates_have_a_privacy_minimal_baseline
    paths = Dir.glob(File.join(ROOT, "{_includes,_layouts,assets/js}", "**", "*"))
               .select { |path| File.file?(path) }
    text = paths.map { |path| File.binread(path) }.join("\n")

    refute_match(/googletagmanager|google-analytics|plausible\.io|posthog|segment\.com/i, text)
  end
end
