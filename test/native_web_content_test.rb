# frozen_string_literal: true

require_relative "test_helper"

class NativeWebContentTest < Minitest::Test
  ORDINARY_PAGES = %w[
    index.md
    _includes/landing/hero.html
    _includes/landing/install.html
    _includes/landing/fit.html
    _includes/landing/cards.html
    _includes/landing/cta.html
    docs/index.md
    docs/getting-started.md
    docs/configuration.md
    docs/operating.md
    docs/commands/index.md
    docs/commands/setup.md
    docs/commands/web.md
  ].freeze

  CANONICAL_WEB_ENV = %w[
    HIVE_WEB_APP_DIR
    HIVE_WEB_ORIGIN
    HIVE_WEB_STORAGE_DIR
    HIVE_WEB_LOCAL_LOOPBACK
    HIVE_WEB_DIFF_TIMEOUT_SEC
    HIVE_WEB_CLONE_TIMEOUT_SEC
  ].freeze

  LEGACY_WEB_ENV = %w[
    HIVEBOX_WEB_APP_DIR
    HIVEBOX_ORIGIN
    HIVEBOX_STORAGE_DIR
    HIVEBOX_LOCAL_LOOPBACK
    HIVEBOX_DIFF_TIMEOUT_SEC
    HIVEBOX_CLONE_TIMEOUT_SEC
  ].freeze

  def test_ordinary_install_and_getting_started_lead_with_native_setup
    install = read("_includes/landing/install.html")
    getting_started = read("docs/getting-started.md")

    [install, getting_started].each do |text|
      assert_includes text, "hive setup"
      assert_includes text, "http://127.0.0.1:4567"
      assert_includes text, "hive setup --no-service"
      assert_includes text, "hive setup --no-bootstrap"
      assert_includes text, "hive web"
      assert_includes text, "Hivebox"
    end
  end

  def test_command_pages_publish_versioned_state_contracts
    setup = read("docs/commands/setup.md")
    web = read("docs/commands/web.md")

    assert_includes setup, "hive-setup.v1"
    assert_includes web, "hive-web-status.v1"
    assert_includes web, "hive-web-install.v1"

    %w[installed enabled running ready].each do |state|
      assert_includes setup, state
      assert_includes web, state
    end

    assert_includes web, "read-only"
    assert_includes web, "hive web install --force"
  end

  def test_configuration_names_canonical_and_migrating_environment_variables
    configuration = read("docs/configuration.md")

    (CANONICAL_WEB_ENV + LEGACY_WEB_ENV).each do |name|
      assert_includes configuration, name
    end

    assert_includes configuration, "HIVE_WEB_BUNDLE_URL"
    assert_includes configuration, "HIVE_WEB_BUNDLE_SHA256"
    assert_includes configuration, "canonical value wins"
  end

  def test_ordinary_pages_do_not_restore_tui_only_or_docker_first_positioning
    content = ORDINARY_PAGES.map { |path| read(path) }.join("\n")

    refute_includes content, "Hive is a local TUI and daemon"
    refute_includes content, "TUI-first Hive"
    refute_includes content, "Need a hosted web app or a managed service"
    assert_includes content, "native Hive web"
    assert_includes content, "loopback"
  end

  def test_hivebox_keeps_both_installers_and_has_a_native_web_chooser
    box_install = read("_includes/box/install.html")
    ordinary_install = read("_includes/landing/install.html")

    assert_includes box_install, "https://hivecli.sh/box.sh"
    assert_includes box_install, "https://hivecli.sh/box.ps1"
    assert_includes ordinary_install, "container isolation"
    assert_includes ordinary_install, "multiple local instances"
    assert_includes ordinary_install, "untrusted agents"
    assert_includes ordinary_install, "server/NAS"
  end

  private

  def read(path)
    File.read(File.join(ROOT, path), encoding: "UTF-8")
  end
end
