module RailsRefdocs
  module Topics
    class Bootstrap < Topic
      DOCS_DIRS = [ "site/src/content/docs", "site/content/docs" ].freeze

      def name = "bootstrap"
      def title = "Bootstrap"
      def source = "https://github.com/twbs/bootstrap (tag, site docs + scss/)"

      def locked(lock)
        locked = lock.gem("bootstrap")
        locked && Lock::Locked.new(locked.version.split(".").first(3).join("."), locked.source)
      end

      def latest(pin)
        Versions.latest_npm("bootstrap", pin)
      end

      def fetch(version, stage, work_dir)
        src = File.join(work_dir, "bootstrap-src")
        log "#{version}: downloading docs and scss at v#{version}"
        Github.extract("twbs/bootstrap", "refs/tags/v#{version}", src, work_dir) do |path|
          path.start_with?("scss/", *DOCS_DIRS.map { |dir| "#{dir}/" })
        end
        docs = DOCS_DIRS.map { |dir| File.join(src, dir) }.find { |dir| File.directory?(dir) }
        raise Error, "bootstrap #{version}: no docs directory found" unless docs
        Files.copy(docs, File.join(stage, "docs"), "*.md", "*.mdx")
        Files.copy(File.join(src, "scss"), File.join(stage, "scss"), "*.scss")
        FileUtils.rm_rf(File.join(stage, "scss/tests"))
      end

      def layout
        <<~MD
          - `bootstrap/` Bootstrap.
            - `docs/` the documentation site sources (`.mdx`): `components/`,
              `forms/`, `layout/`, `utilities/`, `helpers/`, `content/`,
              `customize/` (Sass variables, color modes, CSS variables).
            - `scss/` the Sass source; `_variables.scss`, `_maps.scss` and
              `_utilities.scss` are the customisation points.
        MD
      end
    end
  end
end
