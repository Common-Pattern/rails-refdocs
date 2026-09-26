module RailsRefdocs
  module Topics
    class Postgres < Topic
      HTML_DIR = "doc/src/sgml/html/"

      def name = "postgres"
      def title = "PostgreSQL"
      def source = "https://ftp.postgresql.org/pub/source/ (docs tarball, HTML to Markdown)"

      def latest(pin)
        Versions.latest_postgres(pin)
      end

      def fetch(version, stage, work_dir)
        tarball = File.join(work_dir, "postgresql-#{version}-docs.tar.gz")
        src = File.join(work_dir, "postgres-src")
        html = File.join(src, HTML_DIR)
        docs = File.join(stage, "docs")
        log "#{version}: downloading the HTML docs tarball"
        Http.download("https://ftp.postgresql.org/pub/source/v#{version}/postgresql-#{version}-docs.tar.gz", tarball)
        Archive.extract(tarball, src) { |path| path.start_with?(HTML_DIR) && path.end_with?(".html") }
        log "#{version}: converting the manual to Markdown"
        FileUtils.mkdir_p(docs)
        titles = Dir.glob("*.html", base: html).sort.map do |page|
          markdown = HtmlMarkdown.convert(File.read(File.join(html, page), encoding: "UTF-8"))
          File.write(File.join(docs, page.sub(/\.html\z/, ".md")), markdown)
          [ page.delete_suffix(".html"), markdown[/^\#{1,6} (.*)$/, 1].to_s ]
        end
        File.write(File.join(stage, "TITLES.tsv"), titles.sort.map { |row| row.join("\t") + "\n" }.join)
      end

      def layout
        <<~MD
          - `postgres/` PostgreSQL, the full manual converted from the release's HTML
            docs, one file per page; tables are flattened into lists (one item per
            row, cells in order).
            - `docs/sql-*.md` SQL commands (`sql-createtable.md`,
              `sql-createindex.md`, `sql-select.md`, ...).
            - `docs/datatype-*.md` data types (`datatype-datetime.md`,
              `datatype-uuid.md`, `datatype-json.md`, ...).
            - `docs/functions-*.md` functions and operators (`functions-uuid.md`,
              `functions-datetime.md`, `functions-json.md`, ...).
            - `docs/ddl-*.md` (constraints, partitioning, row security),
              `docs/indexes-*.md`, `docs/mvcc*.md` and `docs/transaction-iso.md`
              (concurrency, locking), `docs/performance-tips.md`, `docs/using-explain.md`,
              `docs/runtime-config-*.md` (server settings), `docs/release-*.md`.
            - `docs/index.md` the table of contents, `docs/bookindex.md` the index.
            - `TITLES.tsv` page name to heading.
        MD
      end
    end
  end
end
