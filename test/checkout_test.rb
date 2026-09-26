require "test_helper"

class CheckoutTest < Minitest::Test
  def worktree_layout(dir)
    main = File.join(dir, "main")
    tree = File.join(dir, "trees", "feature")
    FileUtils.mkdir_p(File.join(main, ".git", "worktrees", "feature"))
    write(File.join(main, ".git", "worktrees", "feature", "commondir"), "../..\n")
    write(File.join(tree, ".git"), "gitdir: #{File.join(main, ".git", "worktrees", "feature")}\n")
    [ main, tree ]
  end

  def test_finds_the_main_checkout_of_a_worktree
    in_tmpdir do |dir|
      main, tree = worktree_layout(dir)
      checkout = RailsRefdocs::Checkout.find(File.join(tree, "reference"))
      assert_equal tree, checkout.root
      assert_equal main, checkout.main_root
      assert checkout.worktree?
      refute RailsRefdocs::Checkout.find(main).worktree?
    end
  end

  def test_default_reference_dir_is_at_the_top_of_the_checkout
    in_tmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, ".git"))
      FileUtils.mkdir_p(File.join(dir, "app", "models"))
      assert_equal File.join(dir, "reference"), RailsRefdocs::Reference.default_dir(File.join(dir, "app", "models"))
    end
  end

  def test_link_symlinks_the_main_checkouts_topics
    in_tmpdir do |dir|
      main, tree = worktree_layout(dir)
      FileUtils.mkdir_p(File.join(main, "reference", "rails", "api"))
      FileUtils.mkdir_p(File.join(main, "reference", "ruby"))
      FileUtils.mkdir_p(File.join(tree, "reference", "ruby"))
      err = StringIO.new
      linked = RailsRefdocs::Linker.new(RailsRefdocs::Reference.new(File.join(tree, "reference")), command: "x", err: err).link
      assert_equal [ "rails" ], linked
      assert_equal File.join(main, "reference", "rails"), File.readlink(File.join(tree, "reference", "rails"))
      refute File.symlink?(File.join(tree, "reference", "ruby"))
    end
  end

  def test_link_does_nothing_in_the_main_checkout
    in_tmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, ".git"))
      assert_equal [], RailsRefdocs::Linker.new(RailsRefdocs::Reference.new(File.join(dir, "reference")), command: "x").link
    end
  end
end
