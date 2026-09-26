module RailsRefdocs
  module Topics
    class Hotwire < Topic
      attr_reader :name, :title, :layout

      def initialize(name:, title:, npm:, rails_gem:, layout:)
        @name = name
        @title = title
        @npm = npm
        @rails_gem = rails_gem
        @layout = layout
      end

      def source
        "https://github.com/hotwired/#{name}-site (main) + hotwired/#{@rails_gem}, hotwired/#{name} READMEs (tags)"
      end

      def pinnable?
        false
      end

      def lock_gem
        @rails_gem
      end

      def locked_part(recorded_version)
        Versions.component(recorded_version, @rails_gem)
      end

      def resolve(_pin, lock)
        locked = locked(lock)
        rails_version = locked ? locked.version : Versions.latest_gem(@rails_gem)
        version = "#{name}-#{Versions.latest_npm(@npm)}+#{@rails_gem}-#{rails_version}+site-#{Github.head_sha("hotwired/#{name}-site")[0, 12]}"
        Resolution.new(version, locked ? "#{locked.source} (#{@rails_gem})" : "latest")
      end

      def fetch(version, stage, work_dir)
        site = "hotwired/#{name}-site"
        src = File.join(work_dir, "#{name}-site-src")
        log "#{version}: downloading the #{name}-site handbook and reference, and READMEs"
        Github.extract(site, Versions.component(version, "site"), src, work_dir) do |path|
          path.start_with?("_source/handbook/", "_source/reference/")
        end
        Files.copy(File.join(src, "_source/handbook"), File.join(stage, "handbook"), "*.md")
        Files.copy(File.join(src, "_source/reference"), File.join(stage, "reference"), "*.md")
        Github.raw_file("hotwired/#{@rails_gem}", "v#{Versions.component(version, @rails_gem)}", "README.md",
          File.join(stage, "#{@rails_gem}-README.md"))
        Github.raw_file("hotwired/#{name}", "v#{Versions.component(version, name)}", "README.md",
          File.join(stage, "#{name}-js-README.md"))
      end
    end
  end
end
