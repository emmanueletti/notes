# Booking system

A room or appointment booking system. It's a common pair programming prompt, and it fits the "small start, many follow-ups" format well. The core is one overlap check. Everything else is bookkeeping around it.

## Prompt

Build a booking system for a single meeting room.

- `book(slot, owner)`: reserve a time slot. Fail if it overlaps an existing booking.
- `cancel(id)`: remove a booking.
- `available?(slot)`: is this slot free?

A slot has a start and an end time.

## Follow-ups they add

1. Multiple resources: several rooms, or several stylists. Each has its own calendar.
2. List the free slots for a resource within a day.
3. Recurring bookings: every Tuesday 10:00-11:00 for 8 weeks. Ask: if one week clashes, reject the whole series or book the rest?
4. Buffers: 15 minutes between bookings for cleaning or travel.
5. A waitlist: when someone cancels, give the slot to the first person waiting.
6. Time zones: a user in Toronto books a room in London.

## Core idea

Two slots overlap when each one starts before the other ends: `a.start < b.end && b.start < a.end`. That's it. Use half-open intervals, `[start, end)`, so 10:00-11:00 and 11:00-12:00 don't clash.

Say the rule out loud and write the back-to-back test first. It's the edge case the AI most often gets wrong (`<=` instead of `<`).

A buffer is the same check with the end pushed out: `a.start < b.end + buffer && b.start < a.end + buffer`.

## Design that takes the follow-ups

- `Slot`: starts_at, ends_at. A value object that rejects end <= start. Owns `overlaps?(other, buffer:)`. Every new overlap rule goes here.
- `Booking`: id, resource, slot, owner, series_id.
- `BookingSystem`: a Hash of resource to its bookings. `book`, `cancel`, `available?`, `free_slots`.
- Recurring: build all the slots first, check all of them, then create them. Give them a shared series_id so `cancel_series` works.
- Waitlist: a list of requests. After each cancel, walk it in order and book any request that now fits.

## Senior talking points

- Store times as instants (UTC). Convert to local time only for display. Ruby compares Time objects with different offsets correctly.
- Recurring plus time zones is the trap. Adding `7 * 86400` seconds drifts by an hour across a DST change. "Every Tuesday at 10:00 Toronto time" needs calendar math in the user's zone. Name it even if you don't build it.
- A linear scan is fine for one room's calendar. At scale, keep bookings sorted by start and binary search, or use an interval tree. In a database, it's an exclusion constraint (Postgres `tstzrange` with `&&`).
- Concurrency: two people book the same slot at the same moment. Check and insert must be atomic: a mutex here, a unique or exclusion constraint in a real system.
- Waitlist fairness: strict FIFO can let one request that never fits block everyone. Skip requests that still don't fit.

## Test cases to name before the AI does

- Overlap raises a conflict
- Back-to-back bookings are allowed
- A slot fully inside another, and one fully containing another
- Two rooms at the same time are fine
- Cancel frees the slot, and cancelling twice raises an error
- End before or equal to start is rejected
- Free slots for a day with two bookings
- A weekly series with one clashing week is rejected whole
- A buffer blocks a booking 10 minutes after another, allows one 15 minutes after
- The waitlist promotes the first request that fits
- 9:30 in Toronto clashes with 14:30 UTC
