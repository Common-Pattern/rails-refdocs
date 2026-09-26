require_relative "lib/rails_refdocs/version"

Gem::Specification.new do |spec|
  spec.name = "rails-refdocs"
  spec.version = RailsRefdocs::VERSION
  spec.authors = [ "Sudhir Jonathan" ]
  spec.summary = "Local, greppable reference docs for a Rails app's stack, at the versions it uses"
  spec.description = "Fetches the guides and API references for Ruby, Rails, PostgreSQL, Hotwire, " \
    "ViewComponent, Bootstrap and the Rails gems around them into the app's reference/ folder as " \
    "Markdown, pinned to the versions in Gemfile.lock."
  spec.homepage = "https://github.com/Common-Pattern/rails-refdocs"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*", "exe/*", "LICENSE", "README.md"]
  spec.bindir = "exe"
  spec.executables = [ "rails-refdocs" ]

  spec.add_dependency "nokogiri", ">= 1.15"
  spec.add_dependency "rdoc", ">= 6.6"
end
