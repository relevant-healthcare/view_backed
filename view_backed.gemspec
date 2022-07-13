$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "view_backed/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "view_backed"
  s.version     = ViewBacked::VERSION
  s.authors     = ["Relevant Healthcare"]
  s.email       = ["dev@relevant.healthcare"]
  s.homepage    = "https://github.com/relevant-healthcare/view_backed"
  s.summary     = "Create view backed models with Rails"
  s.description = "Create view backed models with Rails"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 4.2.7", "< 6.2"
  s.add_dependency "pg"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "fabrication"
  s.add_development_dependency "rspec_junit_formatter"
end
