# frozen_string_literal: true

require_relative "test_helper"

class BoxScriptTest < Minitest::Test
  def test_powershell_advertises_the_configured_bind_address
    script = File.read(File.join(ROOT, "box.ps1"))
    publish_line = script.lines.find { |line| line.include?('docker run -d --name $Name') }
    open_line = script.lines.find { |line| line.include?('Write-Host "  Open:') }

    refute_nil publish_line
    assert_includes publish_line, '"${Bind}:${Port}:4567"'
    refute_nil open_line
    assert_includes open_line, 'http://${Bind}:$Port'
  end
end
