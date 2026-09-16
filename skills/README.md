# Studio Skills

Portable AI agent roles for the studio. Each skill is self-contained — copy the directory anywhere (Claude Code `~/.claude/skills/`, project `.claude/skills/`, or load into a Claude project) and it works.

## The roles

| Skill | Role | When to invoke |
|---|---|---|
| [critic](./critic/) | Pressure-tests proposals against the north star | Before shipping anything user-facing or making a non-trivial call |
| [synth](./synth/) | Turns raw inputs (user calls, feedback) into patterns | After a batch of user conversations or research |
| [scribe](./scribe/) | Drafts in your voice (outbound, posts, decision docs) | When you need a first draft you'll then edit |
| [strategist](./strategist/) | Strategic sounding board for bigger calls | Before quarterly direction-setting or major decisions |
| [review](./review/) | Runs weekly and quarterly review rituals | Friday PMs, end of quarter |

## Design principles

- **Skills augment judgment, they do not replace it.** Every output is a draft, a critique, or a synthesis — never a final decision.
- **Skills know the north star.** They reference `~/notes/studio/` and operate from those principles.
- **Skills are honest.** They push back, name tradeoffs, refuse to flatter. A yes-man skill is worse than no skill.
- **Skills are voice-aware but never voice-final.** Public writing always passes through a human.

## Install

Copy any skill directory to wherever Claude can load skills. The skill is one `SKILL.md` file plus optional supporting context.

For Claude Code: `cp -r critic ~/.claude/skills/`

For a Claude project: paste the SKILL.md into the project instructions.

## Updating

Skills evolve as the studio learns. When you find yourself correcting a skill in conversation, update its SKILL.md so the lesson sticks.
