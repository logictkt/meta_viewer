# frozen_string_literal: true

module MetaViewer
  class Railtie < Rails::Railtie
    initializer "meta_viewer.middleware" do |app|
      app.middleware.use MetaViewer::Middleware
    end
  end
end
