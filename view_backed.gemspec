$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "view_backed/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "view_backed"
  s.version     = ViewBacked::VERSION
  s.authors     = ["Kevin Finn"]
  s.email       = ["kevin@relevant.healthcare"]
  s.homepage    = "https://github.com/relevant-healthcare/filter_builder"
  s.summary     = "Create view backed models with Rails"
  s.description = "Create view backed models with Rails"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 4.2.7"

  s.add_development_dependency "pg", "~> 0.18.2"
  s.add_development_dependency "appraisal"
  s.add_development_dependency "rails", "~> 5.0.7"
  s.add_development_dependency "rspec-rails"
end
