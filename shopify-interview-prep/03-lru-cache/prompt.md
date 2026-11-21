# LRU cache

Reported at an Apr 2026 onsite and in the HelloInterview write-up. It sounds scary but it's small. The whole idea fits in one sentence.

## Prompt

Build a cache with a fixed capacity.

- `get(key)`: returns the value, or nil if missing.
- `put(key, value)`: stores it. If the cache is full, evict the least recently used entry first.
- Both `get` and `put` count as "using" a key.

Example with capacity 2: `put a`, `put b`, `get a` (a is now the most recent), then `put c`. That evicts b, not a.

## The whole idea

You need two things fast: look up a key, and know which key is oldest. Keep entries in order of use. On every access, move the key to the "newest" end. When full, drop from the "oldest" end.

In Ruby this is easy, because a Hash keeps insertion order:
- On access: `value = @store.delete(key)`, then `@store[key] = value` re-inserts it at the newest end.
- To evict: `@store.shift` removes the oldest. All of this is O(1).

Say this out loud in the interview: "Ruby's Hash is ordered, so delete-and-reinsert gives me O(1) LRU. In a language without an ordered hash, I'd pair a hash map with a doubly linked list. The hash points to list nodes, and I move nodes to the head on access and pop the tail on evict." Knowing the linked-list version exists is the senior signal. You probably won't have to build it, but if asked, it's about 30 lines and the AI can draft it while you review the pointer updates.

## Follow-ups they add

1. Configurable capacity, with a guard against 0 or negative.
2. Pluggable storage backend (in-memory now, Redis later). Separate the eviction policy from where data lives.
3. TTL: entries expire after N seconds. Inject a clock so you can test it without sleeping.
4. Stats: hits, misses, evictions.
5. Thread safety: wrap get and put in a `Mutex`. Be ready to explain why get also needs the lock: it changes the order.
6. An eviction callback (`on_evict`), for example to write to disk.
7. A different policy, such as LFU. If the policy is its own object, swapping it is easy.

## Design that takes the follow-ups

- `LruCache.new(capacity:, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }, ttl: nil)`
- Keep `get`/`put` as the public API. Keep the private `touch(key)` and `evict!` small, so TTL and stats land in one place.

## Senior talking points

- `put` on an existing key updates the value AND counts as use. It must never evict anything.
- What should `get` return for a stored nil? Ask, or use `fetch` with a sentinel.
- Use a monotonic clock for TTL, not wall-clock time.
- Memory: capacity counts entries, not bytes. Mention a size-in-bytes variant as a possible follow-up.

## Test cases

- The example above, where b is evicted
- Updating an existing key doesn't evict anything
- Capacity 1
- A TTL entry expires with a fake clock
- Hit/miss stats
