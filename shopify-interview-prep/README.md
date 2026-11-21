# Shopify AI pair programming prep

Problems candidates have reported in 2025-2026: Secret Santa, Mars rover, LRU cache, file system, tail, metro fare (from Blind), and booking system. Cart discounts (08) is not candidate-reported. It's plausible Shopify-flavored practice. Each folder has:

- prompt.md: the problem the way an interviewer would give it, the follow-ups they add, the core idea, and what a senior answer looks like
- solution.rb: a reference solution with tests. Run it with `ruby solution.rb`. Don't open it until you've tried the problem.

mock-followups.md has surprise follow-ups, a planted AI bug for each problem, and a scoring rubric. Give it to the friend running your mock, and don't read it yourself.

## What the round actually is

- About 60 to 75 minutes on Google Meet, sharing your screen, in your own editor with your own AI tools.
- Usually starts from an empty repo or a README. You push to a branch at the end.
- The interviewer gives a small prompt, then adds requirements every 10 to 15 minutes. The follow-ups are the real test: does your design take a new requirement without a rewrite?
- Problems are easy algorithmically. They grade how you work, not whether you know a trick.

## What they grade

1. You drive, the AI types. You decide the classes, names, and edge cases. The AI implements.
2. You review out loud. Read every diff before accepting it. The rejected candidates in the reports pasted without reviewing.
3. You test as you go. Run tests after every generation. Name edge cases before the AI does.
4. Clean code. Fix magic numbers, vague names, and dead code even when it works.
5. You talk the whole time. Silence while an agent runs is the worst signal.

## The loop for every requirement

1. Restate the requirement and ask one clarifying question.
2. Say the design change in one sentence: "I'll add an Obstacle check in Grid, Rover stays the same."
3. Prompt the AI with that design and the test cases you want.
4. Read the diff out loud. Say what you're keeping and what you're changing.
5. Run the tests. Commit.

## Senior signals

- Ask about the input contract first: format, size, invalid data, and what to do on error.
- Separate parsing, domain logic, and output (CLI, printing). That way follow-ups land in one place.
- Name trade-offs as you go: "Hash is fine at this size; at a million entries I'd stream it."
- Suggest the next follow-up before they do: "Next you'll probably want obstacles. I've kept the move check in one method for that."
- Say when the AI is wrong and why, calmly. Interviewers watch for this.

## Practice plan (about 2 weeks)

- Day 1: Read every prompt.md. Don't code yet.
- Days 2-9: One problem a day, 60-minute timer, Claude Code, empty folder, talking out loud. Record yourself if you can. Then compare with solution.rb.
- Days 10-12: Repeat the two that felt worst (probably LRU and file system), without looking at notes.
- Days 13-14: Mocks with a friend using mock-followups.md, so the follow-ups are ones you haven't seen.

## Setup before the interview

- Claude Code in the terminal plus a browser Claude tab as a fallback if the agent gets stuck.
- Keep effort at medium. One candidate waited so long at max effort they had to make small talk.
- Have a blank Ruby project template ready: Gemfile with minitest, a `test/` folder, and `ruby -Itest` working.
- Test your screen share with a big font. Turn off notifications.

## Questions to ask the recruiter

- Which rounds are in the senior loop, and is there an online assessment?
- Can I use Claude Code, or my own tool, in the pair programming rounds?
- Is there a technical deep dive on a past project?
