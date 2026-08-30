# frozen_string_literal: true

require "open3"
require_relative "test_helper"

class BoxScriptTest < Minitest::Test
  def test_dotted_container_name_does_not_match_a_similar_name_as_a_regular_expression
    execution = run_box(name: "hive.box", existing_names: ["hiveXbox"])

    assert_predicate execution.fetch(:status), :success?, execution.fetch(:stderr)
    assert_includes execution.fetch(:stdout), "hivebox is running."
    assert_includes execution.fetch(:calls), "pull ghcr.io/ivankuznetsov/hivebox:latest"
    assert execution.fetch(:calls).any? { |call| call.start_with?("run -d --name hive.box ") }
  end

  def test_dotted_container_name_still_detects_an_exact_collision
    execution = run_box(name: "hive.box", existing_names: ["hive.box"])

    assert_equal 1, execution.fetch(:status).exitstatus
    assert_includes execution.fetch(:stderr), "a container named hive.box already exists"
    refute execution.fetch(:calls).any? { |call| call.start_with?("pull ", "run ") }
  end

  private

  def run_box(name:, existing_names:)
    Dir.mktmpdir do |directory|
      docker_path = File.join(directory, "docker")
      log_path = File.join(directory, "docker.log")
      File.write(docker_path, <<~SH)
        #!/bin/sh
        printf '%s\n' "$*" >> "$FAKE_DOCKER_LOG"
        case "$1" in
          info) ;;
          ps) printf '%s\n' "$FAKE_DOCKER_NAMES" ;;
          pull) ;;
          run) printf '%s\n' fake-container-id ;;
          *) exit 1 ;;
        esac
      SH
      FileUtils.chmod(0o755, docker_path)

      env = {
        "FAKE_DOCKER_LOG" => log_path,
        "FAKE_DOCKER_NAMES" => existing_names.join("\n"),
        "HIVEBOX_DATA" => File.join(directory, "data"),
        "HIVEBOX_NAME" => name,
        "HOME" => directory,
        "PATH" => [directory, ENV.fetch("PATH")].join(File::PATH_SEPARATOR)
      }
      stdout, stderr, status = Open3.capture3(env, "sh", File.join(ROOT, "box.sh"))

      {
        stdout: stdout,
        stderr: stderr,
        status: status,
        calls: File.readlines(log_path, chomp: true)
      }
    end
  end
end
