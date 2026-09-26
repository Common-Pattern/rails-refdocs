module RailsRefdocs
  module Topics
    class SolidQueue < Topic
      def name = "solid_queue"
      def title = "Solid Queue"
      def source = "https://github.com/rails/solid_queue (tag, README + UPGRADING + docs/ if present)"
      def lock_gem = "solid_queue"

      def latest(pin)
        Versions.latest_gem("solid_queue", pin)
      end

      def fetch(version, stage, work_dir)
        src = File.join(work_dir, "solid_queue-src")
        log "#{version}: downloading README, UPGRADING and docs/ at v#{version}"
        Github.extract("rails/solid_queue", "refs/tags/v#{version}", src, work_dir) do |path|
          [ "README.md", "UPGRADING.md" ].include?(path) || path.start_with?("docs/")
        end
        FileUtils.cp(File.join(src, "README.md"), File.join(stage, "README.md"))
        Files.copy_if_exists(File.join(src, "UPGRADING.md"), File.join(stage, "UPGRADING.md"))
        Files.copy(File.join(src, "docs"), File.join(stage, "docs"), "*.md") if File.directory?(File.join(src, "docs"))
      end

      def layout
        <<~MD
          - `solid_queue/` Solid Queue (Active Job backend): `README.md` (installation,
            `config/queue.yml` workers/dispatchers, recurring tasks, the Puma plugin,
            concurrency controls, database setup), `UPGRADING.md`, and `docs/` when
            the release has one.
        MD
      end
    end
  end
end
