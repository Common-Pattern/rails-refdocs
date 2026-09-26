namespace :refdocs do
  run = lambda do |*args|
    command = ENV["REFDOCS_COMMAND"] || (Rails.root.join("bin/refdocs").exist? ? "bin/refdocs" : "rails-refdocs")
    status = RailsRefdocs::CLI.start([ "--dir", Rails.root.join("reference").to_s, *args ], command: command)
    exit status unless status.zero?
  end

  desc "Fetch every reference/TOPICS topic that is behind (topics as arguments, FORCE=1 to refetch)"
  task :update do |_task, args|
    run.call("update", *(ENV["FORCE"] ? [ "--force" ] : []), *args.extras)
  end

  desc "Print recorded and resolved reference doc versions; fail if any topic is behind"
  task :check do |_task, args|
    run.call("check", *args.extras)
  end

  desc "Offline: fail if reference/VERSIONS is behind Gemfile.lock or .ruby-version"
  task :locked do |_task, args|
    run.call("check", "--locked", *args.extras)
  end

  desc "In a git worktree, symlink the main checkout's reference topics into this one"
  task :link do
    run.call("link")
  end
end
