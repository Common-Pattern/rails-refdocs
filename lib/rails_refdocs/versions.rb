module RailsRefdocs
  module Versions
    RELEASE = /\A\d+(?:\.\d+)*\z/

    module_function

    def pick(candidates, pin = nil)
      candidates
        .grep(RELEASE)
        .select { |version| pin.nil? || version == pin || version.start_with?("#{pin}.") }
        .max_by { |version| Gem::Version.new(version) }
    end

    def latest_gem(name, pin = nil)
      versions = JSON.parse(Http.get("https://rubygems.org/api/v1/versions/#{name}.json"))
      pick(versions.map { |row| row["number"] }, pin)
    end

    def latest_npm(name, pin = nil)
      pick(JSON.parse(Http.get("https://registry.npmjs.org/#{name}")).fetch("versions").keys, pin)
    end

    def latest_ruby(pin = nil)
      names = Http.get("https://cache.ruby-lang.org/pub/ruby/index.txt").lines.map { |line| line.split.first.to_s }
      pick(names.filter_map { |name| name[/\Aruby-(\d+\.\d+\.\d+)\z/, 1] }, pin)
    end

    def latest_postgres(pin = nil)
      pick(Http.get("https://ftp.postgresql.org/pub/source/").scan(%r{v(\d[\d.]*)/}).flatten.uniq, pin)
    end

    def component(version, name)
      version.split("+").each do |part|
        match = part.match(/\A#{Regexp.escape(name)}-([0-9a-f][^-]*)\z/)
        return match[1] if match
      end
      nil
    end
  end
end
