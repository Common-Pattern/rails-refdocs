module RailsRefdocs
  module Topics
    class ViewComponent < Topic
      def name = "view_component"
      def title = "ViewComponent"
      def source = "https://github.com/ViewComponent/view_component (tag, docs/)"
      def lock_gem = "view_component"

      def latest(pin)
        Versions.latest_gem("view_component", pin)
      end

      def fetch(version, stage, work_dir)
        src = File.join(work_dir, "view_component-src")
        log "#{version}: downloading docs at v#{version}"
        Github.extract("ViewComponent/view_component", "refs/tags/v#{version}", src, work_dir) do |path|
          path == "README.md" || path.start_with?("docs/")
        end
        Files.copy(File.join(src, "docs"), File.join(stage, "docs"), "*.md")
        FileUtils.cp(File.join(src, "README.md"), File.join(stage, "README.md"))
      end

      def layout
        <<~MD
          - `view_component/` ViewComponent: `docs/guide/*.md` (slots, previews,
            testing, collections, helpers, turbo_streams, ...), `docs/api.md` (full
            API), `docs/CHANGELOG.md`, `README.md`.
        MD
      end
    end
  end
end
