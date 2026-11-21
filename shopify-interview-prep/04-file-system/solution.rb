class FsError < StandardError; end
class NotFound < FsError; end
class NotADirectory < FsError; end
class AlreadyExists < FsError; end
class DirectoryNotEmpty < FsError; end

class Node
  attr_accessor :name, :parent

  def initialize(name, parent)
    @name = name
    @parent = parent
  end
end

class Directory < Node
  attr_reader :children

  def initialize(name, parent)
    super
    @children = {}
  end
end

class FileNode < Node
  attr_accessor :content

  def initialize(name, parent, content)
    super(name, parent)
    @content = content
  end
end

class FileSystem
  def initialize
    @root = Directory.new("", nil)
    @cwd = @root
  end

  def pwd
    parts = []
    node = @cwd
    while node.parent
      parts.unshift(node.name)
      node = node.parent
    end
    "/" + parts.join("/")
  end

  def cd(path)
    @cwd = directory!(resolve(path), path)
  end

  def ls(path = ".")
    node = resolve(path)
    node.is_a?(Directory) ? node.children.keys.sort : [node.name]
  end

  def mkdir(path, parents: false)
    return mkdir_p(path) if parents

    dir, name = split_parent(path)
    raise AlreadyExists, path if dir.children.key?(name)

    dir.children[name] = Directory.new(name, dir)
  end

  def add(path, content = "")
    dir, name = split_parent(path)
    raise NotADirectory, path if dir.children[name].is_a?(Directory)

    dir.children[name] = FileNode.new(name, dir, content)
  end

  def cat(path)
    node = resolve(path)
    raise FsError, "#{path} is a directory" if node.is_a?(Directory)

    node.content
  end

  def rm(path, recursive: false)
    node = resolve(path)
    raise FsError, "cannot remove root" if node.equal?(@root)
    raise FsError, "cannot remove current directory or its parent" if ancestor_of_cwd?(node)
    raise DirectoryNotEmpty, path if node.is_a?(Directory) && node.children.any? && !recursive

    node.parent.children.delete(node.name)
  end

  def du(path = ".")
    size_of(resolve(path))
  end

  private

  def resolve(path)
    node = path.start_with?("/") ? @root : @cwd
    path.split("/").reject(&:empty?).each do |part|
      directory!(node, path)
      node =
        case part
        when "." then node
        when ".." then node.parent || @root
        else node.children.fetch(part) { raise NotFound, path }
        end
    end
    node
  end

  def split_parent(path)
    parts = path.split("/").reject(&:empty?)
    raise FsError, "invalid path #{path.inspect}" if parts.empty? || %w[. ..].include?(parts.last)

    parent_path = (path.start_with?("/") ? "/" : "") + parts[0...-1].join("/")
    parent = parent_path.empty? ? @cwd : resolve(parent_path)
    [directory!(parent, path), parts.last]
  end

  def mkdir_p(path)
    node = path.start_with?("/") ? @root : @cwd
    path.split("/").reject(&:empty?).each do |part|
      next node = node.parent || @root if part == ".."
      next if part == "."

      child = node.children[part] ||= Directory.new(part, node)
      node = directory!(child, path)
    end
    node
  end

  def directory!(node, path)
    raise NotADirectory, path unless node.is_a?(Directory)

    node
  end

  def ancestor_of_cwd?(node)
    current = @cwd
    while current
      return true if current.equal?(node)

      current = current.parent
    end
    false
  end

  def size_of(node)
    node.is_a?(FileNode) ? node.content.bytesize : node.children.values.sum { size_of(_1) }
  end
end

if $PROGRAM_NAME == __FILE__
  require "minitest/autorun"

  class FileSystemTest < Minitest::Test
    def setup
      @fs = FileSystem.new
    end

    def test_mkdir_cd_pwd
      @fs.mkdir("/a")
      @fs.cd("a")
      @fs.mkdir("b")
      @fs.cd("b")
      assert_equal "/a/b", @fs.pwd
    end

    def test_dot_dot_and_dot
      @fs.mkdir("/a")
      @fs.cd("/a")
      @fs.cd("./..")
      assert_equal "/", @fs.pwd
      @fs.cd("..")
      assert_equal "/", @fs.pwd
    end

    def test_absolute_path_from_nested_cwd
      @fs.mkdir("/a", parents: true)
      @fs.mkdir("/x/y", parents: true)
      @fs.cd("/a")
      @fs.cd("/x/y")
      assert_equal "/x/y", @fs.pwd
    end

    def test_ls_sorted_with_files_and_dirs
      @fs.mkdir("/b")
      @fs.add("/a.txt", "hi")
      @fs.mkdir("/c")
      assert_equal %w[a.txt b c], @fs.ls("/")
    end

    def test_errors
      @fs.add("/f", "x")
      assert_raises(NotADirectory) { @fs.cd("/f") }
      assert_raises(NotFound) { @fs.cd("/missing") }
      @fs.mkdir("/d")
      assert_raises(AlreadyExists) { @fs.mkdir("/d") }
    end

    def test_mkdir_p
      @fs.mkdir("/a/b/c", parents: true)
      @fs.cd("/a/b/c")
      assert_equal "/a/b/c", @fs.pwd
    end

    def test_rm_rules
      @fs.mkdir("/a/b", parents: true)
      assert_raises(DirectoryNotEmpty) { @fs.rm("/a") }
      @fs.rm("/a", recursive: true)
      assert_equal [], @fs.ls("/")
      assert_raises(FsError) { @fs.rm("/") }
    end

    def test_cat_and_du
      @fs.mkdir("/d")
      @fs.add("/d/one", "abc")
      @fs.add("/d/two", "de")
      assert_equal "abc", @fs.cat("/d/one")
      assert_equal 5, @fs.du("/d")
    end
  end
end
