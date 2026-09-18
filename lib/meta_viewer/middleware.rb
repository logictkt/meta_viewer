# frozen_string_literal: true

module MetaViewer
  class Middleware
    HTML_CONTENT_TYPE = %r{\Atext/html(?:;|\z)}i

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      return [status, headers, body] unless inject?(env, headers)

      contents = +""
      body.each { |part| contents << part }
      body.close if body.respond_to?(:close)

      return [status, headers, [contents]] unless contents.match?(%r{</body\s*>}i)

      contents.sub!(%r{</body\s*>}i, "#{Panel.html}</body>")
      headers.delete("Content-Length")
      [status, headers, [contents]]
    end

    private

    def inject?(env, headers)
      return false unless MetaViewer.enabled?(environment(env))
      return false unless headers["content-type"] || headers["Content-Type"]
      return false if headers["content-encoding"] || headers["Content-Encoding"]
      return false unless HTML_CONTENT_TYPE.match?(headers["content-type"] || headers["Content-Type"])

      !env["meta_viewer.injected"]
    end

    def environment(env)
      env["meta_viewer.environment"] || (Rails.env if defined?(Rails))
    end
  end
end
