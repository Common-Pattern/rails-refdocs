module RailsRefdocs
  module Topics
    class Rails < Topic
      COMPONENTS = %w[
        activesupport activerecord activemodel actionpack actionview actionmailer
        activejob actioncable activestorage actionmailbox actiontext railties
      ].freeze
      API_EXCLUDE = %r{/templates/|action_view/vendor/|lib/rails/test_unit/|lib/rails/api/generator\.rb|/app/(javascript|assets)/}

      def name = "rails"
      def title = "Rails"
      def source = "https://github.com/rails/rails (tag, guides/source + rdoc)"

      def locked(lock)
        lock.gem("rails") || lock.gem("railties")
      end

      def latest(pin)
        Versions.latest_gem("rails", pin)
      end

      def fetch(version, stage, work_dir)
        src = File.join(work_dir, "rails-src")
        log "#{version}: downloading rails/rails at v#{version}"
        Github.extract("rails/rails", "refs/tags/v#{version}", src, work_dir)
        guides = File.join(stage, "guides")
        Files.copy(File.join(src, "guides/source"), guides, "*.md", "*.yaml")
        FileUtils.rm_f(Dir.glob(File.join(guides, "[2-6]_*_release_notes.md")))
        log "#{version}: generating API markdown with rdoc (about 30s)"
        Rdoc.generate(src, stage, api_files(src))
      end

      def api_files(src)
        files = [ "railties/RDOC_MAIN.md" ]
        COMPONENTS.each do |component|
          [ "README.*", "lib/**/*.rb", "app/**/*.rb" ].each do |pattern|
            files.concat(Dir.glob("#{component}/#{pattern}", base: src).sort)
          end
        end
        files.reject { |file| file.match?(API_EXCLUDE) }
      end

      def layout
        <<~MD
          - `rails/` Ruby on Rails.
            - `guides/` the Rails Guides sources (`active_record_querying.md`,
              `routing.md`, `form_helpers.md`, `action_controller_overview.md`,
              `testing.md`, `configuring.md`, `upgrading_ruby_on_rails.md`, release
              notes from 7.0 on). `documents.yaml` is the guides table of contents.
            - `api/` one file per class/module across all Rails frameworks, generated
              by rdoc with the same file set as api.rubyonrails.org.
            - `pages/` each framework's README.
            - `CLASSES.tsv`, `METHODS.tsv` indexes.
        MD
      end
    end
  end
end
