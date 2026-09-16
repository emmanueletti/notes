# Projects feature — data model design (ADR)

Status: accepted (supersedes the `custom-projects` prototype)
Date: 2026-06-14
Scope: the opinionated custom-piece "Projects" flow. Distinct from the repair
JobTicket/JobItem flow.

## Context

We are bringing the learnings from the `custom-projects` prototype into a real
feature and rethinking the data model first. A Project is a folder of work for a
single custom piece made for a customer: it houses everything relevant to making
that piece. It is presented as a kanban board where each card is a project moving
through a fixed sequence of stages (inquiry → delivery).

The prototype modeled stages as a `stages` table and seeded 7 rows per project on
create, while also locking those stages to a global enum and keeping a separate
`current_stage_key` string on the project. That is the cost of a flexible schema
with none of the flexibility, plus two sources of truth for "where is this
project." It also reinvented, more weakly, the per-tenant configurable pipeline we
already have in `JobTicketStatus`.

Three product forks were settled before designing:

1. **Stage spine is fixed** for MVP (same stages, same order, every shop).
2. **A Project is one custom piece** (a folder of work), not a container of many
   pieces. `piece_type` stays singular on the project.
3. **Projects are a distinct aggregate** from JobTicket/JobItem. JobTicket =
   repair work; Project = the opinionated custom-piece flow. We follow the *shape*
   of the existing pipeline machinery (single pointer, events log, positioning)
   but do not reuse the JobTicket tables.

## Decision

### 1. Project is a lean aggregate root (the kanban card)

```
projects
  belongs_to :repair_shop
  belongs_to :customer
  belongs_to :assigned_team_member, optional: true   # TeamMember

  include TenantSequenced          # per-shop project number
  include SoftDeletable
  positioned on: [:repair_shop_id, :current_stage]    # persists intra-column order

  status        enum  active | cancelled | completed     # lifecycle
  current_stage enum  inquiry … delivery                 # workflow position (single source of truth)
  name, target_date
  budget_range, occasion, piece_type, recipient          # vertical typed enums
  position, tenant_sequence, deleted_at, timestamps

  has_many :notes,  as: :noteable    # reuse existing polymorphic Note
  has_many :events, as: :owner       # reuse existing polymorphic Event (stage timeline)
```

### 2. No `stages` table

The spine is fixed, so materializing stage rows buys nothing. The enum is the
spine. Specifically:

- `current_stage` (enum) is the only "where is this" pointer. No `stages` rows, no
  `current_stage_key` string.
- **Lifecycle is separate from workflow position.** `status` carries terminal
  outcomes (cancelled / completed); `current_stage` carries position on the spine.
  The board shows `active` projects grouped by `current_stage`.
- **Stage category** (planning / in_progress / completion) is a derived property
  of the stage, defined once as a frozen map and used only for board tinting. It
  is not stored, and it does not live in three places like the prototype had it.

### 3. Stage transitions are events, not columns

`move_to_stage!` updates `current_stage` and writes an `Event`
(`topic: "stage_changed"`, `metadata: { from:, to:, by: }`). The event log gives
us the full timeline, per-stage entry/exit timestamps, and "who moved it" for
free. This replaces the prototype's per-stage `completed_at` columns (those are
now derived from the timeline).

### 4. Intra-column order is persisted

The prototype's drag-and-drop did not save order within a column. We persist it
with the `positioned` gem (the app's standard, used by `JobTicketStatus` and
`FormFieldDefinition`), scoped to `[:repair_shop_id, :current_stage]` so a card
re-ranks within its column when moved.

### 5. Stage-specific data is composed, never bolted onto Project

This is the rule that keeps Project from becoming a god table. Three kinds of
data, three homes:

| If the data… | …lives on | Example |
|---|---|---|
| describes the **piece or commission** (true the whole life) | a `projects` column | `piece_type`, `target_date`, `recipient` |
| is the **work product of a stage** and clusters with related fields | its **own concern table** (`has_one`/`has_many`) | quote amount + deposit + sent_at → `ProjectQuote` |
| is freeform commentary or "what happened when" | the polymorphic `notes` / `events` | a sourcing note, a stage-changed event |

When the Quote stage needs structured data, add a record, not nullable columns:

```ruby
class Project < ApplicationRecord
  has_one  :quote,     class_name: "ProjectQuote"     # quote stage
  has_many :materials, class_name: "ProjectMaterial"  # sourcing stage
  has_one  :qa_review                                  # QA stage
  has_one  :spec                                       # design stage
end
```

Each concern owns its fields, validations, and lifecycle. `ProjectQuote` validates
`amount > 0`; Project never carries a nullable `quote_amount`. These are real
domain objects (a quote has its own lifecycle: drafted, sent, approved, expired),
not the empty spine rows we rejected.

**Do not pre-create these concern tables.** Add each one when its stage's UI is
built. The durable discipline: structured stage data becomes a concern table; it
never widens Project.

### 6. The only per-stage conditional is a presentation map

There is one legitimate map from stage to UI. It is presentation, not business
logic, and it does not branch on a wide Project row:

```ruby
STAGE_PANELS = {
  inquiry:           [:brief],
  design:            [:spec, :design_refs],
  quote:             [:quote],
  sourcing:          [:materials],
  production:        [:work_log, :photos],
  quality_assurance: [:qa_review, :photos],
  delivery:          [:handoff, :photos]
}
```

Each panel is a partial backed by a concern record. Stage gating ("can't leave
Quote without an approved quote") is a small policy that asks the relevant concern
(`project.quote&.approved?`), not a method branching on a god object. This mirrors
how Linear/Jira keep the card lean and push richness into related entities and
workflow rules.

## Alternatives considered

- **Per-project Stage rows (the prototype).** Rejected: materializes a fixed enum
  as rows, duplicates the current-stage pointer, stores `category` three times,
  needs a `repair_shop_matches_project` validator, and never persists card order.
- **Shop-configurable stages, modeled like `JobTicketStatus`.** Rejected for MVP
  per fork 1. The spine is fixed, so configurability is speculative complexity. If
  shops later need different pipelines, promote `current_stage` to a `stage_id` FK
  pointing at tenant-level rows shaped like `JobTicketStatus` (color, icon,
  position, category, `positioned`). The migration path is clean.
- **Reuse JobTicket/JobItem for projects.** Rejected per fork 3. They are distinct
  domains (repair vs custom piece). We reuse the *patterns*, not the tables.
- **EAV / custom-field engine for piece attributes.** Rejected. This is a focused
  vertical; typed enums (`piece_type`, `occasion`, `budget_range`, `recipient`)
  are the right call and avoid a custom-field engine we do not need.
- **JSON blob for stage data.** Rejected for structured data. Freeform notes can
  use `notes`; structured stage output gets real concern tables.

## Consequences

What changes relative to the prototype currently in the working tree:

- **Drop** the `stages` table, `Stage` model, `Enums::Projects::StageCategories`
  stored column, and the `CATEGORY_BY_PUBLIC_KEY` map on `Stage`.
- **Remove** from `Project`: `seed_stages` (after_create), `current_stage_key`
  string. **Add**: `current_stage` enum, `positioned`, the `notes`/`events`
  associations, and the `Event`-writing `move_to_stage!`.
- **Keep** what the prototype got right: `TenantSequenced`, `SoftDeletable`, the
  vertical typed enums, and the lifecycle-vs-position split.
- The board query becomes `active projects grouped by current_stage`, ordered by
  `position`. The category map drives column tinting only.
- Net: removes a table, a model, three callbacks, and a validator; fixes the
  silent drag-reorder bug; eliminates the dual source of truth; reuses two
  battle-tested polymorphic models.

## Open questions

- **Per-stage notes.** The prototype let you pin a note to a stage. MVP is
  project-level notes only. If "notes pinned to the sourcing stage" becomes a
  requirement, add a `stage` enum column to `notes` rather than resurrecting a
  Stage table.
- **Photos.** Design refs and progress photos likely reuse the existing `photos`
  mechanism; confirm polymorphic ownership when building the production/QA panels.

## Build order (TDD)

1. Migration: `create_projects` (revised, no `stages` table).
2. `Project` model + enums (`Statuses`, `Stages`, `BudgetRanges`, `Occasions`,
   `PieceTypes`, `Recipients`) + `STAGE_CATEGORY` frozen map.
3. `move_to_stage!` writing an `Event`; derive timeline from events.
4. Controller + board view (group by `current_stage`, `positioned` order). Cover
   new dashboard routes with auth tests (per CLAUDE.md).
5. Add concern tables (`ProjectQuote` first) only when each stage's UI is built.

## Appendix: the domain-modeling principle behind this

The prototype's mistake was modeling the screen instead of the business: the
kanban shows columns, so columns became a table. Three things got conflated that
model differently:

| What it really was | Prototype turned it into | Where it belongs |
|---|---|---|
| **State** (where the project is) | an entity (`Stage` rows) | an attribute (`current_stage` enum) |
| **Process** (moving through steps) | rows with `completed_at` | events (append-only log) |
| **View** (the board) | the `stages` table | nothing; `group_by(:current_stage)` |

Test a candidate table before creating it. If it fails these, it is a state, an
event, or a view, not an entity:

1. **Identity** — does the business point at one and call it a thing they own?
   (They count projects and quotes; nobody counts "stages.")
2. **Independent lifecycle** — does it change on its own schedule, apart from its
   parent? (A quote does; a stage does not.)
3. **Listable on its own** — would you query it without its parent? (You search
   quotes across projects; never "stages.")
4. **Not just a label** — if its whole job is to name a position or category, it is
   an enum, not a table.

A quote passes all four; a stage fails all four. When in doubt, model the domain
as if there were no UI, and start from the verbs of the business
("we send a quote", "we order stones") rather than the nouns in a mockup.
