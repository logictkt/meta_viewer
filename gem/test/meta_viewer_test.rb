# frozen_string_literal: true

require_relative "test_helper"

class MetaViewerTest < Minitest::Test
  def setup
    MetaViewer.configuration = MetaViewer::Configuration.new
  end

  def test_is_enabled_only_in_development_by_default
    assert MetaViewer.enabled?("development")
    refute MetaViewer.enabled?("production")
  end

  def test_exposes_the_minor_version_update
    assert_equal "1.0.0", MetaViewer::VERSION
  end

  def test_accepts_an_explicit_environment_allow_list
    MetaViewer.configure { |config| config.environments = %w[development staging] }

    assert MetaViewer.enabled?("staging")
    refute MetaViewer.enabled?("production")
  end

  def test_uses_right_center_for_the_default_button_position
    assert_equal "right_center", MetaViewer.configuration.button_position
    assert_includes MetaViewer::Panel.html, "meta-viewer--right-center"
  end

  def test_accepts_each_requested_button_position
    MetaViewer::Configuration::BUTTON_POSITIONS.each do |position|
      MetaViewer.configuration.button_position = position

      assert_includes MetaViewer::Panel.html, "meta-viewer--#{position.tr('_', '-')}"
    end
  end

  def test_rejects_an_unknown_button_position
    error = assert_raises(ArgumentError) { MetaViewer.configuration.button_position = :bottom_center }

    assert_match "button_position must be one of", error.message
  end

  def test_injects_the_panel_into_an_html_response_in_an_enabled_environment
    app = ->(_env) { [200, { "Content-Type" => "text/html", "Content-Length" => "28" }, ["<html><body>Hello</body></html>"]] }

    _status, headers, body = MetaViewer::Middleware.new(app).call("meta_viewer.environment" => "development")

    assert_includes body.each.to_a.join, "メタチェック"
    refute headers.key?("Content-Length")
  end

  def test_does_not_inject_the_panel_when_environment_is_disabled
    app = ->(_env) { [200, { "Content-Type" => "text/html" }, ["<html><body>Hello</body></html>"]] }

    _status, _headers, body = MetaViewer::Middleware.new(app).call("meta_viewer.environment" => "production")

    refute_includes body.each.to_a.join, "メタチェック"
  end

  def test_does_not_modify_compressed_html
    app = ->(_env) { [200, { "Content-Type" => "text/html", "Content-Encoding" => "gzip" }, ["compressed"]] }

    _status, _headers, body = MetaViewer::Middleware.new(app).call("meta_viewer.environment" => "development")

    assert_equal "compressed", body.each.to_a.join
  end

  def test_panel_includes_the_requested_display_rules
    assert_includes MetaViewer::Panel.css, '.meta-viewer__section{margin:0 0 20px}'
    assert_includes MetaViewer::Panel.css, 'h3::before{content:"■ "'
    assert_includes MetaViewer::Panel.javascript, 'target="_blank"'
    assert_includes MetaViewer::Panel.javascript, 'meta[property="og:image"]'
    assert_includes MetaViewer::Panel.javascript, 'meta[itemprop="image"]'
    assert_includes MetaViewer::Panel.javascript, 'link[rel="image_src"]'
    assert_includes MetaViewer::Panel.javascript, "method: 'HEAD'"
    assert_includes MetaViewer::Panel.javascript, 'ファイル種別:'
    assert_includes MetaViewer::Panel.javascript, 'ファイルサイズ:'
    assert_includes MetaViewer::Panel.javascript, '文字)</span>'
    assert_includes MetaViewer::Panel.javascript, "img.closest('.meta-viewer__image')"
    assert_includes MetaViewer::Panel.javascript, "!root.contains(event.target)"
    assert_includes MetaViewer::Panel.javascript, 'このページは index されません。'
    assert_includes MetaViewer::Panel.javascript, "directives.includes('noindex')"
    assert_includes MetaViewer::Panel.javascript, "if (!noindex && !nofollow && !nosnippet) return '';"
    refute_includes MetaViewer::Panel.javascript, 'このページは index されます。'
    assert_includes MetaViewer::Panel.javascript, "section('見出し構造 (h1〜h6)', headings())"
    assert_includes MetaViewer::Panel.javascript, "!heading.closest('[data-meta-viewer]')"
  end

  def test_centered_button_does_not_transform_the_panel_parent
    assert_includes MetaViewer::Panel.css, ".meta-viewer--right-center{right:0;top:50%;margin-top:-22px}"
    assert_includes MetaViewer::Panel.css, ".meta-viewer--left-center{left:0;top:50%;margin-top:-22px}"
    refute_includes MetaViewer::Panel.css, ".meta-viewer--right-center{right:0;top:50%;transform:translateY(-50%)}"
  end
end
