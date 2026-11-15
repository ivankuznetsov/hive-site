# frozen_string_literal: true

require "open3"
require_relative "test_helper"

# The Hivebox installers are archived but still served for existing installs.
class BoxScriptTest < Minitest::Test
  def test_dotted_container_name_is_matched_literally
    execution = run_box(name: "hive.box", existing_names: ["hiveXbox"])

    assert_predicate execution.fetch(:status), :success?, execution.fetch(:stderr)
    assert execution.fetch(:calls).any? { |call| call.start_with?("run -d --name hive.box ") }
  end

  def test_exact_container_name_collision_is_still_detected
    execution = run_box(name: "hive.box", existing_names: ["hive.box"])

    assert_equal 1, execution.fetch(:status).exitstatus
    assert_includes execution.fetch(:stderr), "a container named hive.box already exists"
    refute execution.fetch(:calls).any? { |call| call.start_with?("pull ", "run ") }
  end

  def test_relative_data_override_is_mounted_as_an_absolute_path
    execution = run_box(name: "hivebox", existing_names: [], data: "relative-data")
    run_call = execution.fetch(:calls).find { |call| call.start_with?("run ") }

    assert_predicate execution.fetch(:status), :success?, execution.fetch(:stderr)
    assert_match(%r{ -v /\S*/relative-data:/data }, run_call)
  end

  def test_open_url_uses_a_reachable_host
    assert_includes run_box(name: "hivebox", existing_names: [], bind: "0.0.0.0").fetch(:stdout),
                    "http://localhost:4567"
    assert_includes run_box(name: "hivebox", existing_names: [], bind: "192.0.2.10").fetch(:stdout),
                    "http://192.0.2.10:4567"
  end

  def test_powershell_resolves_data_and_advertises_the_bind_host
    script = File.read(File.join(ROOT, "box.ps1"))
    create = script.index("New-Item -ItemType Directory -Force -Path $Data")
    resolve = script.index("$Data = (Resolve-Path -LiteralPath $Data).Path")
    mount = script.index("docker run -d --name $Name")

    assert_operator create, :<, resolve
    assert_operator resolve, :<, mount
    assert_includes script, '$OpenHost = if ($Bind -eq "0.0.0.0") { "localhost" } else { $Bind }'
    assert_includes script, 'http://${OpenHost}:$Port'
  end

  private

  def run_box(name:, existing_names:, data: "data", bind: nil)
    Dir.mktmpdir do |directory|
      log_path = File.join(directory, "docker.log")
      File.write(File.join(directory, "docker"), <<~SH)
        #!/bin/sh
        printf '%s\\n' "$*" >> "$FAKE_DOCKER_LOG"
        case "$1" in
          ps) printf '%s\\n' "$FAKE_DOCKER_NAMES" ;;
          info|pull|run) ;;
          *) exit 1 ;;
        esac
      SH
      FileUtils.chmod(0o755, File.join(directory, "docker"))
      env = {
        "PATH" => "#{directory}:#{ENV.fetch('PATH')}",
        "FAKE_DOCKER_LOG" => log_path,
        "FAKE_DOCKER_NAMES" => existing_names.join("\n"),
        "HIVEBOX_NAME" => name,
        "HIVEBOX_DATA" => data
      }
      env["HIVEBOX_BIND"] = bind if bind
      stdout, stderr, status = Open3.capture3(env, "sh", File.join(ROOT, "box.sh"), chdir: directory)
      calls = File.exist?(log_path) ? File.readlines(log_path, chomp: true) : []
      { stdout: stdout, stderr: stderr, status: status, calls: calls }
    end
  end
end
