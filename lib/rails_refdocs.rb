require "fileutils"
require "json"
require "tmpdir"

require "rails_refdocs/version"

module RailsRefdocs
  class Error < StandardError; end

  class << self
    attr_writer :log_io

    def log_io
      @log_io ||= $stderr
    end

    def log(message)
      log_io.puts("==> #{message}")
    end
  end
end

require "rails_refdocs/http"
require "rails_refdocs/archive"
require "rails_refdocs/github"
require "rails_refdocs/versions"
require "rails_refdocs/files"
require "rails_refdocs/lock"
require "rails_refdocs/topics_file"
require "rails_refdocs/manifest"
require "rails_refdocs/rdoc"
require "rails_refdocs/html_markdown"
require "rails_refdocs/topic"
require "rails_refdocs/topics/ruby"
require "rails_refdocs/topics/rails"
require "rails_refdocs/topics/postgres"
require "rails_refdocs/topics/view_component"
require "rails_refdocs/topics/bootstrap"
require "rails_refdocs/topics/hotwire"
require "rails_refdocs/topics/readme_only"
require "rails_refdocs/topics/solid_queue"
require "rails_refdocs/topics"
require "rails_refdocs/checkout"
require "rails_refdocs/reference"
require "rails_refdocs/readme"
require "rails_refdocs/updater"
require "rails_refdocs/linker"
require "rails_refdocs/cli"
require "rails_refdocs/railtie" if defined?(Rails::Railtie)
