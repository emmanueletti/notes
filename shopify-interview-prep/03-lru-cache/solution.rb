class LruCache
  Entry = Data.define(:value, :expires_at)

  attr_reader :hits, :misses, :evictions

  def initialize(capacity:, ttl: nil, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }, on_evict: nil)
    raise ArgumentError, "capacity must be positive" unless capacity.is_a?(Integer) && capacity.positive?

    @capacity = capacity
    @ttl = ttl
    @clock = clock
    @on_evict = on_evict
    @store = {}
    @lock = Mutex.new
    @hits = @misses = @evictions = 0
  end

  # get mutates recency order, so it needs the lock too.
  def get(key)
    @lock.synchronize do
      entry = @store.delete(key)
      if entry.nil? || expired?(entry)
        @misses += 1
        return nil
      end

      @hits += 1
      @store[key] = entry
      entry.value
    end
  end

  def put(key, value)
    @lock.synchronize do
      @store.delete(key)
      evict_oldest while @store.size >= @capacity
      @store[key] = Entry.new(value:, expires_at: @ttl && @clock.call + @ttl)
      value
    end
  end

  def size = @store.size

  private

  def expired?(entry) = entry.expires_at && @clock.call >= entry.expires_at

  # Ruby hashes keep insertion order, so the first key is the least recently used.
  def evict_oldest
    key, entry = @store.shift
    @evictions += 1
    @on_evict&.call(key, entry.value)
  end
end

if $PROGRAM_NAME == __FILE__
  require "minitest/autorun"

  class LruCacheTest < Minitest::Test
    def test_evicts_least_recently_used
      cache = LruCache.new(capacity: 2)
      cache.put(:a, 1)
      cache.put(:b, 2)
      cache.get(:a)
      cache.put(:c, 3)
      assert_nil cache.get(:b)
      assert_equal 1, cache.get(:a)
      assert_equal 3, cache.get(:c)
    end

    def test_updating_existing_key_does_not_evict
      cache = LruCache.new(capacity: 2)
      cache.put(:a, 1)
      cache.put(:b, 2)
      cache.put(:a, 10)
      assert_equal 10, cache.get(:a)
      assert_equal 2, cache.get(:b)
      assert_equal 0, cache.evictions
    end

    def test_capacity_one
      cache = LruCache.new(capacity: 1)
      cache.put(:a, 1)
      cache.put(:b, 2)
      assert_nil cache.get(:a)
      assert_equal 2, cache.get(:b)
    end

    def test_invalid_capacity
      assert_raises(ArgumentError) { LruCache.new(capacity: 0) }
    end

    def test_ttl_with_fake_clock
      now = 100.0
      cache = LruCache.new(capacity: 2, ttl: 10, clock: -> { now })
      cache.put(:a, 1)
      now = 109.0
      assert_equal 1, cache.get(:a)
      now = 111.0
      assert_nil cache.get(:a)
    end

    def test_stats_and_eviction_callback
      evicted = []
      cache = LruCache.new(capacity: 1, on_evict: ->(k, v) { evicted << [k, v] })
      cache.put(:a, 1)
      cache.get(:a)
      cache.get(:missing)
      cache.put(:b, 2)
      assert_equal [1, 1, 1], [cache.hits, cache.misses, cache.evictions]
      assert_equal [[:a, 1]], evicted
    end
  end
end
