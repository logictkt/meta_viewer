require_relative "lib/meta_viewer/version"

Gem::Specification.new do |spec|
  spec.name          = "meta_viewer"
  spec.version       = MetaViewer::VERSION
  spec.authors       = ["Meta Viewer contributors"]
  spec.summary       = "Inspect SEO metadata in a Rails page."
  spec.description   = "A development-first Rails engine that adds an in-browser SEO metadata inspector."
  spec.homepage      = "https://github.com/logictkt/meta_viewer"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,lib}/**/*", "LICENSE.txt", "README.md"]
  end

  spec.add_dependency "railties", ">= 6.1", "< 9.0"
end
