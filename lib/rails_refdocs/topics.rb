module RailsRefdocs
  module Topics
    ALL = [
      Ruby.new,
      Rails.new,
      Postgres.new,
      ViewComponent.new,
      Bootstrap.new,
      Hotwire.new(name: "turbo", title: "Turbo", npm: "@hotwired/turbo", rails_gem: "turbo-rails", layout: <<~MD),
        - `turbo/` Turbo: `handbook/` (Drive, page refreshes, Frames, Streams,
          native), `reference/` (attributes, drive, events, frames, streams),
          `turbo-rails-README.md` (Rails helpers), `turbo-js-README.md`.
      MD
      Hotwire.new(name: "stimulus", title: "Stimulus", npm: "@hotwired/stimulus", rails_gem: "stimulus-rails", layout: <<~MD),
        - `stimulus/` Stimulus: `handbook/`, `reference/` (controllers, actions,
          targets, values, outlets, css classes, lifecycle callbacks, TypeScript),
          `stimulus-rails-README.md`, `stimulus-js-README.md`.
      MD
      ReadmeOnly.new(name: "importmap-rails", repo: "rails/importmap-rails",
        summary: "importmap-rails (JavaScript without a bundler)."),
      ReadmeOnly.new(name: "dartsass-rails", repo: "rails/dartsass-rails",
        summary: "dartsass-rails (Sass builds through Dart Sass)."),
      SolidQueue.new,
      ReadmeOnly.new(name: "letter_opener_web", repo: "fgrehm/letter_opener_web",
        summary: "letter_opener_web (browse sent mail in\n  development).")
    ].freeze

    module_function

    def names
      ALL.map(&:name)
    end

    def fetch(name, &missing)
      ALL.find { |topic| topic.name == name } || (missing ? missing.call : raise(Error, "unknown topic: #{name}"))
    end
  end
end
