# frozen_string_literal: true

require "meta_viewer/version"
require "meta_viewer/configuration"
require "meta_viewer/panel"
require "meta_viewer/middleware"
require "meta_viewer/railtie" if defined?(Rails::Railtie)

module MetaViewer
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def enabled?(environment = nil)
      configuration.enabled?(environment || (Rails.env if defined?(Rails)))
    end
  end
end
