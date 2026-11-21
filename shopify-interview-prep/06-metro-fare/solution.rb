require "date"

Station = Data.define(:name, :zone)

Concession = Data.define(:name, :percent_off) do
  def apply(cents) = (cents * (100 - percent_off) / 100r).round
end

ADULT = Concession.new(name: "adult", percent_off: 0)

Trip = Data.define(:origin, :destination, :started_at, :ended_at, :fare, :transfer) do
  def service_day = started_at.to_date
end

class FareTable
  PEAK_WINDOWS = [(7 * 60)...(9 * 60 + 30), (16 * 60)...(18 * 60 + 30)].freeze

  def initialize(base:, per_extra_zone:, peak_surcharge:)
    @base = base
    @per_extra_zone = per_extra_zone
    @peak_surcharge = peak_surcharge
  end

  attr_reader :base

  def fare(origin, destination, at)
    zones_crossed = (origin.zone - destination.zone).abs
    @base + zones_crossed * @per_extra_zone + (peak?(at) ? @peak_surcharge : 0)
  end

  def peak?(at)
    return false if at.saturday? || at.sunday?

    minute = at.hour * 60 + at.min
    PEAK_WINDOWS.any? { _1.cover?(minute) }
  end
end

class InsufficientBalance < StandardError; end
class NotTappedIn < StandardError; end
class AlreadyTappedIn < StandardError; end

class Card
  attr_reader :id, :concession, :balance, :trips

  def initialize(id:, concession: ADULT, balance: 0)
    @id = id
    @concession = concession
    @balance = balance
    @trips = []
  end

  def top_up(cents)
    raise ArgumentError, "top-up must be positive" unless cents.positive?

    @balance += cents
  end

  def record(trip)
    @balance -= trip.fare
    @trips << trip
  end

  def spent_on(day) = trips.select { _1.service_day == day }.sum(&:fare)
end

class FareSystem
  def initialize(stations:, fare_table:, daily_cap:, transfer_window: 30 * 60, clock: -> { Time.now })
    @stations = stations.to_h { [_1.name, _1] }
    @fare_table = fare_table
    @daily_cap = daily_cap
    @transfer_window = transfer_window
    @clock = clock
    @open_taps = {}
  end

  def tap_in(card, station_name)
    raise AlreadyTappedIn, card.id if @open_taps.key?(card.id)
    # Minimum balance of one base fare; the real fare is only known at tap-out.
    raise InsufficientBalance, card.id if card.balance < @fare_table.base

    @open_taps[card.id] = [station(station_name), @clock.call]
  end

  def tap_out(card, station_name)
    origin, started_at = @open_taps.delete(card.id) { raise NotTappedIn, card.id }
    destination = station(station_name)
    transfer = transfer?(card, started_at)
    fare = transfer ? 0 : capped(card, started_at, raw_fare(card, origin, destination, started_at))

    Trip.new(origin:, destination:, started_at:, ended_at: @clock.call, fare:, transfer:)
      .tap { card.record(_1) }
  end

  private

  def station(name) = @stations.fetch(name) { raise ArgumentError, "unknown station #{name}" }

  def raw_fare(card, origin, destination, at)
    card.concession.apply(@fare_table.fare(origin, destination, at))
  end

  # One free transfer per paid trip, so chaining short hops can't ride free all day.
  def transfer?(card, started_at)
    last = card.trips.last
    last && !last.transfer && started_at - last.ended_at <= @transfer_window
  end

  def capped(card, at, fare)
    cap = card.concession.apply(@daily_cap)
    [fare, cap - card.spent_on(at.to_date)].min.clamp(0, nil)
  end
end

if $PROGRAM_NAME == __FILE__
  require "minitest/autorun"

  class MetroFareTest < Minitest::Test
    STATIONS = [
      Station.new(name: "Union", zone: 1),
      Station.new(name: "King", zone: 1),
      Station.new(name: "Eglinton", zone: 2),
      Station.new(name: "Finch", zone: 3)
    ].freeze

    def setup
      @now = Time.new(2026, 11, 18, 11, 0, 0) # a Wednesday, off-peak
      @system = FareSystem.new(
        stations: STATIONS,
        fare_table: FareTable.new(base: 250, per_extra_zone: 75, peak_surcharge: 50),
        daily_cap: 1000,
        clock: -> { @now }
      )
      @card = Card.new(id: "c1", balance: 5000)
    end

    def ride(from, to, card: @card, minutes: 20)
      @system.tap_in(card, from)
      @now += minutes * 60
      @system.tap_out(card, to)
    end

    def wait(minutes) = @now += minutes * 60

    def test_same_zone_off_peak_is_base_fare
      assert_equal 250, ride("Union", "King").fare
      assert_equal 4750, @card.balance
    end

    def test_each_zone_crossed_adds_to_fare
      assert_equal 400, ride("Union", "Finch").fare
    end

    def test_peak_surcharge_uses_tap_in_time
      @now = Time.new(2026, 11, 18, 8, 0, 0)
      assert_equal 300, ride("Union", "King").fare
    end

    def test_weekend_is_never_peak
      @now = Time.new(2026, 11, 21, 8, 0, 0)
      assert_equal 250, ride("Union", "King").fare
    end

    def test_daily_cap_limits_spend
      fares = 4.times.map { ride("Union", "Finch").fare.tap { wait(60) } }
      assert_equal [400, 400, 200, 0], fares
    end

    def test_cap_resets_next_day
      3.times { ride("Union", "Finch"); wait(60) }
      @now = Time.new(2026, 11, 19, 11, 0, 0)
      assert_equal 400, ride("Union", "Finch").fare
    end

    def test_transfer_within_window_is_free_once
      ride("Union", "King")
      wait(10)
      assert_predicate ride("King", "Eglinton"), :transfer
      wait(10)
      assert_equal 325, ride("Eglinton", "Finch").fare
    end

    def test_trip_after_window_is_charged
      ride("Union", "King")
      wait(31)
      assert_equal 250, ride("King", "Union").fare
    end

    def test_low_balance_blocks_tap_in_until_top_up
      card = Card.new(id: "c2", balance: 100)
      assert_raises(InsufficientBalance) { @system.tap_in(card, "Union") }
      card.top_up(500)
      assert_equal 250, ride("Union", "King", card:).fare
    end

    def test_concession_discounts_fare_and_cap
      senior = Card.new(id: "s1", concession: Concession.new(name: "senior", percent_off: 50), balance: 5000)
      fares = 3.times.map { ride("Union", "Finch", card: senior).fare.tap { wait(60) } }
      assert_equal [200, 200, 100], fares
    end

    def test_tap_out_without_tap_in
      assert_raises(NotTappedIn) { @system.tap_out(@card, "Union") }
    end

    def test_double_tap_in
      @system.tap_in(@card, "Union")
      assert_raises(AlreadyTappedIn) { @system.tap_in(@card, "King") }
    end
  end
end
