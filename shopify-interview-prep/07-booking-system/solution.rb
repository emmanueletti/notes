Slot = Data.define(:starts_at, :ends_at) do
  def initialize(starts_at:, ends_at:)
    raise ArgumentError, "slot must end after it starts" unless ends_at > starts_at

    super
  end

  # Half-open [start, end): a 10:00-11:00 booking and an 11:00-12:00 booking don't overlap.
  def overlaps?(other, buffer: 0)
    starts_at < other.ends_at + buffer && other.starts_at < ends_at + buffer
  end

  def +(seconds) = with(starts_at: starts_at + seconds, ends_at: ends_at + seconds)
end

Booking = Data.define(:id, :resource, :slot, :owner, :series_id)

Request = Data.define(:resource, :slot, :owner)

class Conflict < StandardError; end
class UnknownBooking < StandardError; end

class BookingSystem
  WEEK = 7 * 24 * 60 * 60

  def initialize(resources:, buffer: 0)
    @bookings = resources.to_h { [_1, []] }
    @buffer = buffer
    @waitlist = []
    @next_id = 0
  end

  def book(resource, slot, owner)
    raise Conflict, "#{resource} is taken for #{slot}" unless available?(resource, slot)

    create(resource, slot, owner, series_id: nil)
  end

  # All or nothing: a recurring booking with one bad week is rejected whole.
  def book_weekly(resource, slot, owner, weeks:)
    slots = (0...weeks).map { slot + _1 * WEEK }
    clash = slots.find { !available?(resource, _1) }
    raise Conflict, "#{resource} is taken for #{clash}" if clash

    series_id = "series-#{@next_id + 1}"
    slots.map { create(resource, _1, owner, series_id:) }
  end

  def cancel(id)
    booking = find(id)
    bookings_for(booking.resource).delete(booking)
    promote_waitlist(booking.resource)
    booking
  end

  def cancel_series(series_id)
    series = @bookings.values.flatten.select { _1.series_id == series_id }
    raise UnknownBooking, series_id if series.empty?

    series.each { cancel(_1.id) }
  end

  def available?(resource, slot)
    bookings_for(resource).none? { _1.slot.overlaps?(slot, buffer: @buffer) }
  end

  def free_slots(resource, window)
    taken = bookings_for(resource).map(&:slot).sort_by(&:starts_at)
    cursor = window.starts_at
    gaps = taken.each_with_object([]) do |slot, acc|
      gap_end = slot.starts_at - @buffer
      acc << Slot.new(starts_at: cursor, ends_at: gap_end) if gap_end > cursor
      cursor = [cursor, slot.ends_at + @buffer].max
    end
    gaps << Slot.new(starts_at: cursor, ends_at: window.ends_at) if window.ends_at > cursor
    gaps
  end

  def join_waitlist(resource, slot, owner)
    bookings_for(resource)
    @waitlist << Request.new(resource:, slot:, owner:)
  end

  def bookings_for(resource) = @bookings.fetch(resource) { raise ArgumentError, "unknown resource #{resource}" }

  private

  def create(resource, slot, owner, series_id:)
    booking = Booking.new(id: @next_id += 1, resource:, slot:, owner:, series_id:)
    bookings_for(resource) << booking
    booking
  end

  def find(id)
    @bookings.each_value { |list| list.each { return _1 if _1.id == id } }
    raise UnknownBooking, id.to_s
  end

  # FIFO, but skip requests that still don't fit so one stuck request can't block the queue.
  def promote_waitlist(resource)
    @waitlist.select { _1.resource == resource }.each do |request|
      next unless available?(resource, request.slot)

      @waitlist.delete(request)
      create(resource, request.slot, request.owner, series_id: nil)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require "minitest/autorun"

  class BookingSystemTest < Minitest::Test
    def setup
      @system = BookingSystem.new(resources: %w[room-a room-b])
    end

    def at(hour, min = 0, day: 18) = Time.utc(2026, 11, day, hour, min)
    def slot(from, to) = Slot.new(starts_at: from, ends_at: to)

    def test_book_and_query
      @system.book("room-a", slot(at(10), at(11)), "ana")
      refute @system.available?("room-a", slot(at(10, 30), at(11, 30)))
      assert @system.available?("room-a", slot(at(11), at(12)))
    end

    def test_overlap_raises_conflict
      @system.book("room-a", slot(at(10), at(11)), "ana")
      assert_raises(Conflict) { @system.book("room-a", slot(at(9), at(12)), "ben") }
    end

    def test_back_to_back_is_allowed
      @system.book("room-a", slot(at(10), at(11)), "ana")
      assert @system.book("room-a", slot(at(11), at(12)), "ben")
    end

    def test_resources_are_independent
      @system.book("room-a", slot(at(10), at(11)), "ana")
      assert @system.book("room-b", slot(at(10), at(11)), "ben")
    end

    def test_cancel_frees_the_slot
      booking = @system.book("room-a", slot(at(10), at(11)), "ana")
      @system.cancel(booking.id)
      assert @system.available?("room-a", slot(at(10), at(11)))
      assert_raises(UnknownBooking) { @system.cancel(booking.id) }
    end

    def test_invalid_slot
      assert_raises(ArgumentError) { slot(at(11), at(10)) }
      assert_raises(ArgumentError) { slot(at(10), at(10)) }
    end

    def test_free_slots_in_a_day
      @system.book("room-a", slot(at(10), at(11)), "ana")
      @system.book("room-a", slot(at(13), at(14)), "ben")
      free = @system.free_slots("room-a", slot(at(9), at(17)))
      assert_equal [slot(at(9), at(10)), slot(at(11), at(13)), slot(at(14), at(17))], free
    end

    def test_weekly_booking_is_all_or_nothing
      @system.book("room-a", slot(at(10, day: 25), at(11, day: 25)), "ben")
      assert_raises(Conflict) { @system.book_weekly("room-a", slot(at(10), at(11)), "ana", weeks: 3) }
      assert_equal 1, @system.bookings_for("room-a").size
    end

    def test_cancel_series
      series = @system.book_weekly("room-a", slot(at(10), at(11)), "ana", weeks: 3)
      @system.cancel_series(series.first.series_id)
      assert_empty @system.bookings_for("room-a")
    end

    def test_buffer_between_bookings
      system = BookingSystem.new(resources: ["room-a"], buffer: 15 * 60)
      system.book("room-a", slot(at(10), at(11)), "ana")
      assert_raises(Conflict) { system.book("room-a", slot(at(11, 10), at(12)), "ben") }
      assert system.book("room-a", slot(at(11, 15), at(12)), "ben")
    end

    def test_waitlist_promoted_on_cancel
      booking = @system.book("room-a", slot(at(10), at(11)), "ana")
      @system.book("room-a", slot(at(11), at(12)), "dee")
      @system.join_waitlist("room-a", slot(at(10), at(12)), "cy")
      @system.join_waitlist("room-a", slot(at(10), at(11)), "ben")
      @system.cancel(booking.id)
      assert_equal %w[dee ben], @system.bookings_for("room-a").map(&:owner)
    end

    def test_time_zones_compare_as_instants
      @system.book("room-a", slot(at(14), at(15)), "ana")
      toronto = Time.new(2026, 11, 18, 9, 30, 0, "-05:00")
      refute @system.available?("room-a", slot(toronto, toronto + 3600))
    end
  end
end
