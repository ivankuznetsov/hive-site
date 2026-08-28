# frozen_string_literal: true

require "open3"
require_relative "test_helper"

class BoxScriptTest < Minitest::Test
  def test_relative_data_override_is_mounted_as_an_absolute_bind_path
    Dir.mktmpdir do |directory|
      bin_dir = File.join(directory, "bin")
      work_dir = File.join(directory, "work")
      args_path = File.join(directory, "docker-run-args")
      FileUtils.mkdir_p([bin_dir, work_dir])

      docker_path = File.join(bin_dir, "docker")
      File.write(docker_path, <<~'SH')
        #!/bin/sh
        set -eu

        command="$1"
        shift
        case "$command" in
          info|ps|pull)
            exit 0
            ;;
          run)
            printf '%s\n' "$@" > "$DOCKER_ARGS_FILE"
            ;;
          *)
            exit 1
            ;;
        esac
      SH
      FileUtils.chmod(0o755, docker_path)

      env = {
        "DOCKER_ARGS_FILE" => args_path,
        "HIVEBOX_DATA" => "hivebox-state",
        "HIVEBOX_IMAGE" => "example.invalid/hivebox:test",
        "PATH" => "#{bin_dir}:#{ENV.fetch("PATH")}"
      }
      stdout, stderr, status = Open3.capture3(env, "sh", File.join(ROOT, "box.sh"), chdir: work_dir)

      assert status.success?, stderr
      created_data_path = File.join(work_dir, "hivebox-state")
      assert Dir.exist?(created_data_path)
      resolved_data_path = File.realpath(created_data_path)
      run_args = File.readlines(args_path, chomp: true)
      volume_index = run_args.index("-v")
      refute_nil volume_index
      assert_equal "#{resolved_data_path}:/data", run_args.fetch(volume_index + 1)
      assert_includes stdout, "Data:  #{resolved_data_path}"
    end
  end
end
