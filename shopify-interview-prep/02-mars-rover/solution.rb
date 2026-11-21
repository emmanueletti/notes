require "set"

Position = Data.define(:x, :y) do
  def +(other) = with(x: x + other.x, y: y + other.y)
  def to_s = "#{x} #{y}"
end

module Heading
  ORDER = %w[N E S W].freeze
  STEPS = {
    "N" => Position.new(x: 0, y: 1),
    "E" => Position.new(x: 1, y: 0),
    "S" => Position.new(x: 0, y: -1),
    "W" => Position.new(x: -1, y: 0)
  }.freeze

  def self.left(heading) = ORDER[(ORDER.index(heading) - 1) % ORDER.size]
  def self.right(heading) = ORDER[(ORDER.index(heading) + 1) % ORDER.size]
  def self.step(heading) = STEPS.fetch(heading)
end

Rover = Data.define(:position, :heading) do
  def turn_left = with(heading: Heading.left(heading))
  def turn_right = with(heading: Heading.right(heading))
  def ahead = position + Heading.step(heading)
  def behind = position + Heading.step(Heading.right(Heading.right(heading)))
  def to_s = "#{position} #{heading}"
end

class Grid
  def initialize(max_x:, max_y:, obstacles: [])
    @max_x = max_x
    @max_y = max_y
    @obstacles = obstacles.to_set
    @occupied = Set.new
  end

  def inside?(pos) = pos.x.between?(0, @max_x) && pos.y.between?(0, @max_y)

  def allowed?(pos) = inside?(pos) && !@obstacles.include?(pos) && !@occupied.include?(pos)

  def park(pos) = @occupied << pos
end

class InvalidCommand < StandardError; end

class Controller
  TURNS = { "L" => :turn_left, "R" => :turn_right }.freeze
  MOVES = { "M" => :ahead, "B" => :behind }.freeze

  def initialize(grid)
    @grid = grid
  end

  # Blocked moves are skipped and the rover keeps going (the behavior agreed with the interviewer).
  def run(rover, commands)
    raise ArgumentError, "rover starts on a blocked cell" unless @grid.allowed?(rover.position)

    final = commands.each_char.reduce(rover) do |current, command|
      if TURNS.key?(command)
        current.public_send(TURNS[command])
      elsif MOVES.key?(command)
        target = current.public_send(MOVES[command])
        @grid.allowed?(target) ? current.with(position: target) : current
      else
        raise InvalidCommand, "unknown command #{command.inspect}"
      end
    end
    @grid.park(final.position)
    final
  end
end

module MissionParser
  def self.run(input)
    lines = input.lines.map(&:strip).reject(&:empty?)
    max_x, max_y = lines.shift.split.map { Integer(_1) }
    controller = Controller.new(Grid.new(max_x:, max_y:))

    lines.each_slice(2).map do |start, commands|
      x, y, heading = start.split
      rover = Rover.new(position: Position.new(x: Integer(x), y: Integer(y)), heading:)
      controller.run(rover, commands.to_s).to_s
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require "minitest/autorun"

  class MarsRoverTest < Minitest::Test
    def rover(x, y, h) = Rover.new(position: Position.new(x:, y:), heading: h)

    def test_classic_input
      input = "5 5\n1 2 N\nLMLMLMLMM\n3 3 E\nMMRMMRMRRM\n"
      assert_equal ["1 3 N", "5 1 E"], MissionParser.run(input)
    end

    def test_cannot_leave_grid
      result = Controller.new(Grid.new(max_x: 2, max_y: 2)).run(rover(0, 2, "N"), "MM")
      assert_equal "0 2 N", result.to_s
    end

    def test_obstacle_blocks_move
      grid = Grid.new(max_x: 5, max_y: 5, obstacles: [Position.new(x: 1, y: 3)])
      assert_equal "1 2 N", Controller.new(grid).run(rover(1, 2, "N"), "M").to_s
    end

    def test_rovers_block_each_other
      controller = Controller.new(Grid.new(max_x: 5, max_y: 5))
      controller.run(rover(1, 1, "N"), "M")
      assert_equal "1 1 N", controller.run(rover(1, 1, "N"), "M").to_s
    end

    def test_backward_command
      assert_equal "2 1 N", Controller.new(Grid.new(max_x: 5, max_y: 5)).run(rover(2, 2, "N"), "B").to_s
    end

    def test_unknown_command
      assert_raises(InvalidCommand) { Controller.new(Grid.new(max_x: 5, max_y: 5)).run(rover(0, 0, "N"), "X") }
    end
  end
end
