# Mock interview follow-ups

For the friend running the mock. Don't show this to the candidate.

## How to run it

- Pick one problem. Read its prompt.md out loud, just the Prompt section.
- Every 10 to 15 minutes, add a follow-up. Mix ones from prompt.md with the surprise ones below. The surprise ones test whether the design holds up on something they didn't rehearse.
- Once, around the middle, use the "AI gave you a wrong answer" scenario. Say it like a colleague: "I think the AI did X here. Is that right?" See if they check, or just agree.
- Stop at 60 minutes. Fill in the rubric at the bottom.

## 01 Secret Santa

Surprise follow-ups:
1. Someone drops out after everyone got their assignment. Fix it while changing as few pairs as possible.
2. Households: people in the same household can't give to each other. The CSV has a household column.
3. Re-running must give the same result, for an audit. Then: re-running next year must give a different one.
4. Each person has a wishlist link. Include the recipient's wishlist in the output.

AI gave you a subtly wrong answer: the backtracking marks a receiver as used, but doesn't unmark them when it backs up. Simple cases pass. A solvable case with tight exclusions is reported as impossible.

## 02 Mars rover

Surprise follow-ups:
1. Report the full path each rover took, every cell visited, not just where it ended.
2. Undo: a `U` command reverses the last command.
3. Fuel: each move costs 1, each turn costs nothing, and a rover stops when it runs out.
4. Eight headings: add NE, SE, SW, NW, with turns of 45 degrees.

AI gave you a subtly wrong answer: turning right does `ORDER[ORDER.index(h) + 1]` with no modulo. Turning left from N works because Ruby allows index -1. Turning right from W returns nil, and nothing fails until the next move.

## 03 LRU cache

Surprise follow-ups:
1. `peek(key)`: read a value without counting it as use.
2. Change the capacity at runtime. Shrinking must evict right away.
3. Capacity by size: each entry has a byte size, and the limit is total bytes.
4. `fetch(key) { compute }`: compute and store on a miss. Under threads, compute only once per key.

AI gave you a subtly wrong answer: on `get`, the AI writes `@store[key] = @store[key]` to "move it to the end". In Ruby, assigning an existing key keeps its original position, so the order never changes. Tests that only check values pass. The eviction test fails, if they wrote one.

## 04 File system

Surprise follow-ups:
1. Symlinks. Then: a symlink that points to its own parent, and `find` must not loop forever.
2. `ls -l`: show size and modified time. Inject a clock.
3. Append: `add` with an append flag, like `>>`.
4. Globs: `ls /logs/*.txt`.

AI gave you a subtly wrong answer: `mv /a /a/b/c` is allowed. Moving a directory into its own subtree detaches it from the root, and its contents vanish. Nothing raises an error.

## 05 tail

Surprise follow-ups:
1. `-n +5`: print from line 5 to the end.
2. Windows line endings (`\r\n`). Output should not have stray `\r` characters.
3. Follow with a filter: only print new lines that match a pattern.
4. `--pid`: stop following when a given process exits.

AI gave you a subtly wrong answer: for a file smaller than one chunk, the AI seeks to `max(0, pos - chunk_size)` but still reads `chunk_size` bytes. The start of the file gets read twice, and the first line shows up twice. Tests with big files pass.

## 06 Metro fare

Surprise follow-ups:
1. A weekly cap on top of the daily cap.
2. Prices change on January 1. Trips before that date use the old table.
3. Auto top-up: when the balance drops below $5, add $20 from a saved card.
4. Refund a trip after a service outage. Does that reopen room under the daily cap?

AI gave you a subtly wrong answer: the cap uses `Date.today` instead of the trip's time from the injected clock. The tests pass if they happen to run on the same day the fake clock says. Tomorrow they fail.

## 07 Booking system

Surprise follow-ups:
1. Business hours: rooms can only be booked 9:00 to 17:00, Monday to Friday.
2. Reschedule a booking. If the new slot is taken, the old booking must still be there.
3. Capacity: a room with 3 desks allows up to 3 overlapping bookings.
4. "Find me any free room for 6 people, 14:00 to 15:00."

AI gave you a subtly wrong answer: `free_slots` walks the bookings in the order they were made, not sorted by start time. If the test books in time order, it passes. Book 13:00 then 10:00 and the gaps come out wrong.

## 08 Cart discounts

Surprise follow-ups:
1. Discount codes with an expiry date and a usage limit. Inject a clock.
2. "$10 off orders over $50." Is the $50 checked before or after other discounts?
3. Buy X get Y across a collection: buy any 3 mugs, the cheapest one is free.
4. Refund one item from a discounted order. How much money goes back?

AI gave you a subtly wrong answer: buy 2 get 1 free is computed as `quantity / buy * get`. With 3 mugs that's 1 free, which is right. With 7 mugs it gives 3 free instead of 2.

## Scoring rubric

Rate each 1 to 4. 1 = a clear problem, 2 = some of it, 3 = solid, 4 = strong enough to call out.

Driving the AI. Did they decide the design and names, then hand the AI a clear task? Or did they paste the prompt and hope?
Score: __
Notes:

Reviewing out loud. Did they read each diff and say what they kept and changed? Did they catch the planted bug?
Score: __
Notes:

Tests. Did they name edge cases before the AI? Did they run tests after every change?
Score: __
Notes:

Design under change. Did each follow-up land in one or two places, or cause a rewrite?
Score: __
Notes:

Communication. Did they keep talking, ask clarifying questions, and name trade-offs? Any long silences?
Score: __
Notes:

Total: __ / 20. One thing to fix before the real interview:
