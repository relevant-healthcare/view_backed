$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "view_backed/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "view_backed"
  s.version     = ViewBacked::VERSION
  s.authors     = ["Kevin Finn"]
  s.email       = ["kevin@relevant.healthcare"]
  s.homepage    = "http://relevant.healthcare"
  s.summary     = "ActiveRecord models backed by views"
  s.description = "Allows users to define models backed by DB views, rather than tables."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 4.2.8"

  s.add_development_dependency "fabrication"
  s.add_development_dependency "pg"
  s.add_development_dependency "rspec-rails"
end
