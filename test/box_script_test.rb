# frozen_string_literal: true

require_relative "test_helper"

class BoxScriptTest < Minitest::Test
  def test_powershell_publishes_on_the_configured_bind_address
    script = File.read(File.join(ROOT, "box.ps1"))
    publish_line = script.lines.find { |line| line.include?('docker run -d --name $Name') }

    refute_nil publish_line
    assert_includes publish_line, '"${Bind}:${Port}:4567"'
  end

  def test_powershell_advertises_localhost_for_a_wildcard_bind
    script = File.read(File.join(ROOT, "box.ps1"))
    display_host_line = script.lines.find { |line| line.start_with?("$OpenHost =") }
    open_line = script.lines.find { |line| line.include?('Write-Host "  Open:') }

    refute_nil display_host_line
    assert_includes display_host_line, '$Bind -eq "0.0.0.0"'
    assert_includes display_host_line, '{ "localhost" }'
    refute_nil open_line
    assert_includes open_line, 'http://${OpenHost}:$Port'
  end

  def test_powershell_advertises_a_concrete_bind_address
    script = File.read(File.join(ROOT, "box.ps1"))
    display_host_line = script.lines.find { |line| line.start_with?("$OpenHost =") }
    open_line = script.lines.find { |line| line.include?('Write-Host "  Open:') }

    refute_nil display_host_line
    assert_includes display_host_line, 'else { $Bind }'
    refute_nil open_line
    assert_includes open_line, 'http://${OpenHost}:$Port'
  end
end
