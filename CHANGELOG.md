# Changelog

## 0.2.0

- Packaged as a Ruby gem with a Rails integration; the Bash script is
  retired (still at the `v0.1.0` tag).
- Runs in the app's Ruby with no external tools: downloads through
  `Net::HTTP`, archives through RubyGems' tar reader, rdoc in-process,
  and the PostgreSQL manual converted with Nokogiri instead of pandoc.
- A topic without a pin in `TOPICS` takes its version from `Gemfile.lock`
  (Ruby from `.ruby-version`).
- `check --locked` fails offline when `VERSIONS` is behind the lockfile;
  `check` exits 1 when a topic is behind.
- Rake tasks `refdocs:update`, `refdocs:check`, `refdocs:locked`,
  `refdocs:link`, and the `rails_refdocs:install` generator.
- Requires rdoc 8.
- Installed from the git tag (`github: "Common-Pattern/rails-refdocs",
  tag: "v0.2.0"`); not published to rubygems.org.

## 0.1.0

- The Bash script.
