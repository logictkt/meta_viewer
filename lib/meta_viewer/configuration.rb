# frozen_string_literal: true

module MetaViewer
  class Configuration
    BUTTON_POSITIONS = %w[right_top right_bottom right_center left_top left_bottom left_center].freeze

    # `nil` means "only in development". Set this to true to use the viewer in
    # every environment, or use `environments` for an explicit allow-list.
    attr_accessor :enabled, :environments
    attr_reader :button_position

    def initialize
      @enabled = nil
      @environments = ["development"]
      @button_position = "right_center"
    end

    def enabled?(environment)
      return enabled.call(environment) if enabled.respond_to?(:call)
      return enabled unless enabled.nil?

      environments.map(&:to_s).include?(environment.to_s)
    end

    def button_position=(position)
      value = position.to_s
      return @button_position = value if BUTTON_POSITIONS.include?(value)

      raise ArgumentError, "button_position must be one of: #{BUTTON_POSITIONS.join(', ')}"
    end
  end
end
