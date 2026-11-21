module Tail
  NEWLINE = "\n".b

  # Reads backwards from EOF so memory stays O(chunk + output) regardless of file size.
  def self.last_lines(io, n, chunk_size: 4096)
    return [] if n <= 0

    io.seek(0, IO::SEEK_END)
    pos = io.pos
    buffer = "".b
    # A trailing "\n" terminates the last line rather than starting an empty one, so we need n+1.
    while pos.positive? && buffer.count(NEWLINE) <= n
      read = [chunk_size, pos].min
      pos -= read
      io.seek(pos)
      buffer.prepend(io.read(read).b)
    end

    lines = buffer.split(NEWLINE, -1)
    lines.pop if lines.last == ""
    lines.last(n).map { |line| line.force_encoding(Encoding::UTF_8) }
  end

  def self.follow(io, output, poll: 0.5, stop: -> { false })
    io.seek(0, IO::SEEK_END)
    offset = io.pos
    until stop.call
      size = io.size
      offset = 0 if size < offset
      if size > offset
        io.seek(offset)
        output.write(io.read(size - offset))
        offset = size
      end
      sleep poll
    end
  end
end

# With file args it's a CLI; with no args it runs the tests.
if $PROGRAM_NAME == __FILE__ && ARGV.any?
  require "optparse"
  lines = 10
  OptionParser.new { |o| o.on("-n N", Integer) { lines = _1 } }.parse!
  ARGV.each do |path|
    puts "==> #{path} <==" if ARGV.size > 1
    File.open(path, "rb") { |f| puts Tail.last_lines(f, lines) }
  end
end

if $PROGRAM_NAME == __FILE__ && ARGV.empty?
  require "minitest/autorun"
  require "stringio"
  require "tempfile"

  class TailTest < Minitest::Test
    def tail(text, n, chunk_size: 4096) = Tail.last_lines(StringIO.new(text), n, chunk_size:)

    def test_last_two_lines
      assert_equal %w[b c], tail("a\nb\nc\n", 2)
    end

    def test_n_larger_than_file
      assert_equal %w[a b], tail("a\nb\n", 10)
    end

    def test_no_trailing_newline
      assert_equal %w[b c], tail("a\nb\nc", 2)
    end

    def test_empty_file_and_zero
      assert_equal [], tail("", 5)
      assert_equal [], tail("a\n", 0)
    end

    def test_lines_crossing_chunk_boundaries
      text = "first line\nsecond line\nthird line\n"
      [1, 3, 7].each { |size| assert_equal ["second line", "third line"], tail(text, 2, chunk_size: size) }
    end

    def test_multibyte_split_across_chunks
      assert_equal ["café", "naïve"], tail("x\ncafé\nnaïve\n", 2, chunk_size: 3)
    end

    def test_follow_prints_appended_lines
      Tempfile.create("tail") do |file|
        file.write("old\n")
        file.flush
        output = StringIO.new
        checks = 0
        stop = lambda do
          checks += 1
          if checks == 2
            file.write("new\n")
            file.flush
          end
          checks > 3
        end
        Tail.follow(File.open(file.path, "rb"), output, poll: 0, stop:)
        assert_equal "new\n", output.string
      end
    end
  end
end
