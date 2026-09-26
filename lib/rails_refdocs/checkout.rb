module RailsRefdocs
  class Checkout
    attr_reader :root

    def self.find(start)
      dir = File.expand_path(start)
      loop do
        return new(dir) if File.exist?(File.join(dir, ".git"))
        parent = File.dirname(dir)
        return nil if parent == dir
        dir = parent
      end
    end

    def initialize(root)
      @root = root
    end

    def main_root
      dot_git = File.join(root, ".git")
      return root if File.directory?(dot_git)
      git_dir = File.read(dot_git)[/\Agitdir: (.+)$/, 1]
      return root unless git_dir
      git_dir = File.expand_path(git_dir.strip, root)
      common_file = File.join(git_dir, "commondir")
      return root unless File.file?(common_file)
      File.dirname(File.expand_path(File.read(common_file).strip, git_dir))
    end

    def worktree?
      main_root != root
    end
  end
end
