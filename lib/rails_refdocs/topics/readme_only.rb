module RailsRefdocs
  module Topics
    class ReadmeOnly < Topic
      attr_reader :name, :lock_gem

      def initialize(name:, repo:, summary:)
        @name = name
        @lock_gem = name
        @repo = repo
        @summary = summary
      end

      def source
        "https://github.com/#{@repo} (tag, README)"
      end

      def latest(pin)
        Versions.latest_gem(name, pin)
      end

      def fetch(version, stage, _work_dir)
        log "#{version}: downloading the README"
        Github.raw_file(@repo, "v#{version}", "README.md", File.join(stage, "README.md"))
      end

      def layout
        "- `#{name}/README.md` #{@summary}\n"
      end
    end
  end
end
