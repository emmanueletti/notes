# Secret Santa

Reported in an Oct 2025 rejection and an Oct 2026 pass, so it's current and common.

## Prompt

You get a CSV of participants: `name,email`. Assign each person someone to buy a gift for. Rules:

- No one gets themselves.
- Everyone gives exactly one gift and receives exactly one gift.

Print the pairs: `Alice -> Bob`. Emailing people is out of scope for now.

## Follow-ups they add

1. Exclusions. A second CSV has a third column listing people someone can't be paired with (spouses, for example). The direction was left unclear in the real interview, so ask: does it mean can't give to, or can't receive from?
2. With enough exclusions, someone may have only one valid match, or none. What do you do when it's impossible?
3. Likely next: no pairs that swap (A gives to B and B gives to A), avoid last year's pairs, actually send the emails.

## Core idea

The base case has a neat trick. Shuffle the list, then each person gives to the next one, and the last gives to the first. That's one big loop, so no one gets themselves and everyone gives and receives once. It runs in O(n) and can't fail.

Exclusions break the trick. Then it's a search: try a recipient for each giver, and back up when you get stuck. To make it fast, handle the most constrained giver first (the one with the fewest valid options). If the search runs out of options, say there's no valid assignment instead of looping forever.

## Design

- `Participant` (name, email, exclusions)
- `ParticipantCsv.parse(io)`: parsing only. Strip whitespace, reject duplicates and blank names.
- `Matcher#assign(participants)`: returns a Hash of giver to receiver, or raises `NoValidAssignment`.
- Output is separate: a `print` method now, a `Notifier` later for email. That's where the email follow-up goes.

## Senior talking points

- Ask about the edge cases: 0 or 1 participants is impossible, and with 2 people the only option is a mutual swap.
- Randomness makes tests flaky. Inject a `Random` with a fixed seed so tests are repeatable.
- Validate the result in tests by checking the rules (no self, a bijection, no exclusions broken), not a specific output.
- Backtracking is exponential in the worst case. That's fine for a party. For thousands of people, it's a bipartite matching problem (Hopcroft-Karp).
- Exclusions with names that aren't in the list: ignore them, warn, or fail? Ask.

## Test cases to name before the AI does

- 3 people: valid, with no one assigned to themselves
- 1 person: error
- An impossible exclusion set: error, no hang
- A forced match: A can only give to C, and the result respects it
- Duplicate names in the CSV
