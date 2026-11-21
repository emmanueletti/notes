require "csv"
require "set"

Participant = Data.define(:name, :email, :exclusions)

class NoValidAssignment < StandardError; end

module ParticipantCsv
  def self.parse(io)
    participants = CSV.new(io).filter_map do |row|
      name, email, exclusions = row.map { |cell| cell&.strip }
      next if name.nil? || name.empty?

      Participant.new(name:, email:, exclusions: (exclusions || "").split(";").map(&:strip).to_set)
    end

    duplicates = participants.map(&:name).tally.select { |_, count| count > 1 }.keys
    raise ArgumentError, "duplicate names: #{duplicates.join(', ')}" if duplicates.any?

    participants
  end
end

class Matcher
  def initialize(random: Random.new)
    @random = random
  end

  def assign(participants)
    raise NoValidAssignment, "need at least 2 participants" if participants.size < 2

    return cycle(participants) if participants.all? { |p| p.exclusions.empty? }

    search(participants)
  end

  private

  # One shuffled cycle can never self-assign, so the no-exclusions case can't fail.
  def cycle(participants)
    shuffled = participants.shuffle(random: @random)
    shuffled.each_with_index.to_h { |giver, i| [giver.name, shuffled[(i + 1) % shuffled.size].name] }
  end

  def search(participants)
    options = participants.to_h do |giver|
      allowed = participants.map(&:name).reject { |name| name == giver.name || giver.exclusions.include?(name) }
      [giver.name, allowed.shuffle(random: @random)]
    end

    # Most constrained first keeps backtracking shallow.
    givers = options.keys.sort_by { |name| options[name].size }
    result = backtrack(givers, options, {}, Set.new)
    raise NoValidAssignment, "exclusions leave no valid assignment" unless result

    result
  end

  def backtrack(givers, options, assigned, taken)
    return assigned.dup if assigned.size == givers.size

    giver = givers[assigned.size]
    options[giver].each do |receiver|
      next if taken.include?(receiver)

      assigned[giver] = receiver
      taken << receiver
      found = backtrack(givers, options, assigned, taken)
      return found if found

      assigned.delete(giver)
      taken.delete(receiver)
    end
    nil
  end
end

if $PROGRAM_NAME == __FILE__
  require "minitest/autorun"

  class SecretSantaTest < Minitest::Test
    def people(csv) = ParticipantCsv.parse(StringIO.new(csv))

    def assert_valid(pairs, participants)
      names = participants.map(&:name)
      assert_equal names.sort, pairs.keys.sort, "everyone gives"
      assert_equal names.sort, pairs.values.sort, "everyone receives"
      pairs.each do |giver, receiver|
        refute_equal giver, receiver
        excluded = participants.find { |p| p.name == giver }.exclusions
        refute_includes excluded, receiver
      end
    end

    def test_basic_assignment_is_valid
      group = people("Alice,a@x.com\nBob,b@x.com\nCara,c@x.com\n")
      20.times { |seed| assert_valid(Matcher.new(random: Random.new(seed)).assign(group), group) }
    end

    def test_single_person_is_impossible
      assert_raises(NoValidAssignment) { Matcher.new.assign(people("Alice,a@x.com\n")) }
    end

    def test_exclusions_are_respected
      group = people("Alice,a@x.com,Bob\nBob,b@x.com,Alice\nCara,c@x.com\nDan,d@x.com\n")
      20.times { |seed| assert_valid(Matcher.new(random: Random.new(seed)).assign(group), group) }
    end

    def test_forced_match
      group = people("Alice,a@x.com,Bob;Dan\nBob,b@x.com\nCara,c@x.com\nDan,d@x.com\n")
      assert_equal "Cara", Matcher.new.assign(group)["Alice"]
    end

    def test_impossible_exclusions_raise_instead_of_hanging
      group = people("Alice,a@x.com,Bob\nBob,b@x.com\n")
      assert_raises(NoValidAssignment) { Matcher.new.assign(group) }
    end

    def test_duplicate_names_rejected
      assert_raises(ArgumentError) { people("Alice,a@x.com\nAlice,b@x.com\n") }
    end
  end
end
