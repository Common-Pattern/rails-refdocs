require "rails/generators"
require "rails_refdocs"

module RailsRefdocs
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Adds reference/TOPICS from Gemfile.lock, the .gitignore entries and bin/refdocs"

      GITIGNORE = <<~IGNORE.freeze
        /reference/*
        !/reference/README.md
        !/reference/TOPICS
        !/reference/VERSIONS
      IGNORE

      GEM_TOPICS = {
        "pg" => "postgres",
        "view_component" => "view_component",
        "bootstrap" => "bootstrap",
        "turbo-rails" => "turbo",
        "stimulus-rails" => "stimulus",
        "importmap-rails" => "importmap-rails",
        "dartsass-rails" => "dartsass-rails",
        "solid_queue" => "solid_queue",
        "letter_opener_web" => "letter_opener_web"
      }.freeze

      def create_topics
        create_file "reference/TOPICS", topics.join("\n") + "\n", skip: true
      end

      def ignore_generated_docs
        gitignore = File.join(destination_root, ".gitignore")
        return if File.file?(gitignore) && File.read(gitignore).include?("/reference/*")
        append_to_file ".gitignore", "\n#{GITIGNORE}"
      end

      def create_binstub
        template "refdocs", "bin/refdocs"
        chmod "bin/refdocs", 0o755
      end

      def next_steps
        say "Pin postgres to your server's major version in reference/TOPICS (\"postgres 18\")." if topics.include?("postgres")
        say "Run bin/refdocs update to fetch the docs."
      end

      private

      def topics
        @topics ||= begin
          lock = Lock.load(destination_root)
          locked = GEM_TOPICS.select { |gem, _topic| lock.gem(gem) }.values
          Topics.names & ([ "ruby", "rails" ] + locked)
        end
      end
    end
  end
end
