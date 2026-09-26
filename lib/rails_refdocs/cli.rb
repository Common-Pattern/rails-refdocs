module RailsRefdocs
  class CLI
    def self.start(argv, command: ENV.fetch("REFDOCS_COMMAND", "rails-refdocs"), out: $stdout, err: $stderr)
      new(command: command, out: out, err: err).run(argv.dup)
    end

    def initialize(command:, out:, err:)
      @command = command
      @out = out
      @err = err
    end

    def run(argv)
      dir = nil
      root = nil
      until argv.empty?
        arg = argv.shift
        case arg
        when "-h", "--help", "help" then return usage(@out, 0)
        when "--dir" then dir = argv.shift or raise Error, "--dir needs a value"
        when /\A--dir=(.+)\z/ then dir = $1
        when "--root" then root = argv.shift or raise Error, "--root needs a value"
        when /\A--root=(.+)\z/ then root = $1
        when /\A-/
          usage(@err, 1)
          raise Error, "unknown option: #{arg}"
        else return dispatch(arg, argv, Reference.new(dir || Reference.default_dir, root: root))
        end
      end
      usage(@err, 1)
    rescue Error => e
      @err.puts("error: #{e.message}")
      1
    end

    private

    def dispatch(command, args, reference)
      case command
      when "update"
        force = !args.delete("--force").nil?
        reject_options(args)
        Updater.new(reference, command: @command, out: @out).update(args, force: force)
        0
      when "check"
        locked = !args.delete("--locked").nil?
        reject_options(args)
        updater = Updater.new(reference, command: @command, out: @out)
        (locked ? updater.check_locked(args) : updater.check(args)) ? 0 : 1
      when "link"
        Linker.new(reference, command: @command, err: @err).link
        0
      when "topics"
        @out.puts(Topics.names)
        0
      else
        usage(@err, 1)
        raise Error, "unknown command: #{command}"
      end
    end

    def reject_options(args)
      option = args.find { |arg| arg.start_with?("-") }
      return unless option
      usage(@err, 1)
      raise Error, "unknown option: #{option}"
    end

    def usage(io, status)
      io.puts(<<~USAGE)
        Usage: #{@command} [--dir DIR] [--root DIR] <command> [options]

        Keeps local, greppable Markdown copies of the API references and guides for
        a Ruby on Rails app's stack in DIR (default: reference/ at the top of the
        current git checkout).

        Commands:
          update [--force] [topic ...]  fetch every configured topic whose recorded
                                        version differs from the version it resolves
                                        to (--force: fetch anyway)
          check [topic ...]             print recorded and resolved versions, fetch
                                        nothing; exit 1 if any topic is behind
          check --locked [topic ...]    offline: exit 1 if a topic whose version
                                        comes from Gemfile.lock or .ruby-version is
                                        recorded at another version
          link                          in a git worktree, symlink each topic folder
                                        of the main checkout's DIR into this one
          topics                        list the topics rails-refdocs knows

        DIR/TOPICS configures a checkout: one topic per line, optionally followed by
        a version pin. A pin is a version prefix: "rails 8.1" resolves to the latest
        8.1.x release, "postgres 18" to the latest 18.x, "bootstrap 5.3.8" to
        exactly that. A topic without a pin takes the version locked in the app's
        Gemfile.lock (ruby: .ruby-version, then the lockfile's RUBY VERSION), and
        the latest release when nothing locks it. turbo and stimulus take no pin;
        their Rails gem version comes from Gemfile.lock. Blank lines and lines
        starting with # are ignored.

        The app root holding Gemfile.lock and .ruby-version is the parent of DIR
        unless --root names it.

        Topics: #{Topics.names.join(" ")}

        REFDOCS_COMMAND names the command in the generated README and messages
        (default: rails-refdocs).
      USAGE
      status
    end
  end
end
