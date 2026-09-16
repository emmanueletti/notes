# Custom projects feature

## Vision

Repairs are a cost center for jewelry brands. They are not excited about it. it is a service they have to provide to their customers and thus buying software to optimize it is not what they are excited about.

Custom projects is a massive revenue center for them and is a question that most people ask us when we reach out. "Can i track my custom work with this?".

Jewelry brands are charging thousands of dollars for custom work and using tools glued together to keep it all together.

Workbench has the opportunity to be the bespoke tool that impresses customers during this high value purcahse and makes he lives of the jewlry brand much easier.

## Questions

- what is the most intuitive ux for custom projects
- what set of features / workflow would remove all the toil from custom projects
- what set of features would would make the customers these jewlery brands go "wow" during one of their most expensive purchases
- what is the quickest set of features to launch an mvp to start getting feedback

---

## Architectural framing

Projects is a **separate domain** from Jobs. Repairs (Jobs) stay as-is, Custom Projects gets its own clean slate so the feature can be priced, packaged, modeled, and designed without dragging repair-ticket baggage.

The only things that cross the boundary are primitives, not domain models.

| Reuse (primitives) | Don't reuse (domain) |
|---|---|
| `Customer`, `RepairShop` (tenancy) | `JobTicket`, `JobItem`, `JobTicketStatus` |
| ActiveStorage / photo plumbing | Job-flavored portal layout & notifications |
| Customer portal session / magic-link auth | `JobItemAssignment` (wrong granularity) |
| Stripe integration code | `FormTemplate` / `FormFieldDefinition` |
| `Event` audit pattern | The "ticket" mental model entirely |

A customer can have both repair tickets and projects, the systems just don't know about each other. If a unified "customer history" view is ever needed, it's a read-model concern, not a coupling.

---

## Stage behavior: handler objects, not STI or concerns

Each stage has its own concerns (required artifacts, advance rules, view partials, mailers eventually). Three ways to host that code; the choice has real consequences as the feature grows.

**Reject STI.** Needs a `type` column as discriminator, which either replaces or shadows the clean `kind` enum (`"InquiryStage"` in the DB instead of `"inquiry"`). 8 subclass files mostly to dispatch methods, hard to migrate away from once committed, and queries get fuzzy.

**Reject concerns.** Concerns pile every stage's methods onto the base `Stage` class, so every instance carries methods like `.approve_sketch!`, `.reserve_stone!`, etc., with internal `return unless design?` guards. Worst of both worlds: global namespace plus conditional logic. Concerns are for cross-cutting behavior (`SoftDeletable`), not for "different behavior per kind."

**Pick: handler per stage.** A `Stages::*Handler` PORO per kind, dispatched from `Stage#handler`.

```ruby
class Stage < ApplicationRecord
  enum :public_key, Enums::Projects::Stages.values.index_by(&:itself)

  def handler
    @handler ||= "Stages::#{public_key.camelize}Handler".constantize.new(self)
  end
end

module Stages
  class BaseHandler
    attr_reader :stage
    def initialize(stage) = @stage = stage
    def project = stage.project
    def display_name = self.class.name.demodulize.sub(/Handler\z/, "").titleize
    def view_partial = "projects/stages/#{stage.public_key}"
    def can_advance? = true
  end

  class InquiryHandler < BaseHandler
    def can_advance? = project.inquiry_notes.present?
  end

  class DesignHandler < BaseHandler
    # def can_advance? = approved_sketch?
  end
end
```

Usage:

```erb
<%= render partial: stage.handler.view_partial, locals: { stage: stage } %>
<% if stage.handler.can_advance? %>
  <%= button_to "Advance to #{next_stage.handler.display_name}", ... %>
<% end %>
```

**Why this scales.** One class per stage, single responsibility, fast unit tests with no DB. Schema stays boring (`public_key` is the canonical string). When per-stage form objects, mailers, or notification templates land, they slot under the same `Stages::` namespace (`Stages::DesignFormObject`, `Stages::QuoteMailer`). If one handler later needs its own columns, introduce a `stage_details` polymorphic table; the handler API stays put.

**Cost.** One extra `.handler.` indirection at call sites (`stage.handler.can_advance?` instead of `stage.can_advance?`). Worth it.

Scaffold the `BaseHandler` and the eight subclass files lazily, only as real stage-specific behavior appears. Until then, `Stage` works fine on its own.

---

## Most intuitive UX

A Project is not a ticket. It's a multi-week engagement with artifacts, money, and a client who is emotionally invested. The right metaphor is a **project workspace** (deal room, Notion page, Linear project), not a row in a queue.

### Internal project view

Top to bottom:

1. **Header**: hero image of latest render or WIP photo, client name, stage badge, days-in-stage, total quoted, paid-to-date.
2. **Stage timeline** (the spine): vertical list of stages with the artifacts, approvals, and payments attached to each. Click a stage to expand its workbench.
3. **Quote panel** (sticky right rail): current version, line items, margin, approval status.
4. **Activity feed**: events, comments, client portal views.

### Client portal view

Same timeline, filtered. Hero image is bigger. Quote becomes "Your design," payments become "Reserve your sapphire." Tone is gallery, not garage.

### Stage spine

| Stage | Internal artifact | Client sees |
|---|---|---|
| Inquiry | Brief, references, budget range | Confirmation, intake form |
| Design | Sketches, CAD, renders | Approve sketch → Approve CAD/render |
| Quote | Materials, stones, labor, margin | Itemized quote → Deposit |
| Sourcing | Stones, metal, vendor POs | "We've sourced your sapphire" update |
| Production | Wax, cast, set, polish | Behind-the-scenes photos at each step |
| QA & delivery | Final inspection, certificate | Reveal photos, pickup/shipping, care card |

### UX bets worth making early

- **First-class stages, not statuses.** Stages have a name, order, owner role (designer / setter / etc.), expected duration, and required artifacts before advancing. The flow is the product.
- **Artifacts have versions.** Sketch v1/v2/v3. Render v1/v2. Client approves a specific version, not the project. Kills the "which one did you mean?" thread permanently.
- **One inbox per project, not a chat.** Comments attach to artifacts or stages. No free-floating DMs. Forces structured back-and-forth.

---

## Features that remove the toil

Ranked by the pain they displace:

1. **Inquiry pipeline upstream of projects.** `Inquiry` is a lightweight model: source, budget range, notes, references, assigned designer. Converts to a `Project` when the discovery call closes. Keeps tire-kickers out of the pipeline view without losing the lead.
2. **Stages as first-class records.** A `Stage` per project, ordered, with an enum-backed `kind` (or per-shop template later). Per-stage assignment, SLA, required artifacts.
3. **Versioned quote.** `Quote` has many `QuoteVersion`, each with `LineItem` rows (metal / stone / labor / vendor / fee). Versions are immutable snapshots. Approval is an event on a version. Replaces the spreadsheet.
4. **Stone & material sourcing.** `SourcingItem` per project: spec, vendor, PO number, cost, cert attachment, ETA, status. Rolls up into the quote automatically.
5. **Approvals.** `Approval` polymorphic to an artifact or stage. Captures who, when, IP, signature blob. Some approvals require a payment to clear.
6. **Milestone payments.** `Payment` belongs_to project, optionally tied to an `Approval` or stage. Stripe-backed. Deposit, progress, balance.
7. **Margin & cost roll-up.** Materials cost (sourcing + line items) vs. quoted price vs. labor hours logged. One number per project: "are we making money on this."
8. **Per-stage assignment.** Designer owns Design, setter owns Production, etc. Not one assignee per project.

---

## Wow moments for the client

The client is spending thousands and currently gets emailed JPEGs. Bar is on the floor. Ranked by build cost vs. impact:

| Feature | Build cost | Wow per dollar |
|---|---|---|
| Branded private project page with hero image | Low | High |
| Behind-the-scenes WIP photos pushed at each stage | Low (photo storage already exists) | High |
| Co-edited inspiration board during discovery | Medium | High |
| Provenance card ("your sapphire from X, cast on Y") | Low (derives from sourcing data) | High |
| Digital certificate at delivery, service log lives on | Medium | High (locks in LTV) |
| 3D CAD render embed (model-viewer or Sketchfab) | Low | Very high |
| Anniversary / cleaning reminders post-delivery | Low | Medium |

Unifying idea: the client wants to **witness the making**. Most of the wow is just making visible the work the jeweler already does. You're not asking them to add work, you're capturing it.

The private project page also doubles as free marketing. Clients send it to fiancés and family. Branded, owned, with a clear "made by [shop]" identity.

---

## MVP

Smallest standalone Projects product that earns revenue and feedback. New section of the dashboard at its own URL space: `/dashboard/projects`, `/portal/projects/:token`.

### Ship

1. `Project` belongs_to customer + repair_shop. Has title, hero image, status (active / completed / cancelled).
2. `Stage` belongs_to project, ordered, with kind + name + completed_at. Seed with a fixed default set (Inquiry, Design, Quote, Production, Ready). No per-shop customization in v1.
3. `Quote` + `QuoteVersion` + `LineItem`. One active version, plus history.
4. `ProjectMedia` (or `Photo` polymorphically). Tagged to a stage.
5. `Approval` for quote + final piece. Reuses the signature primitive but stands alone.
6. One `Payment` per project (deposit) via Stripe.
7. Client portal page: hero, stage timeline, current quote, approve + pay button, latest photos.
8. Internal project page: stage timeline, quote builder, media upload, advance-stage button.

### Defer

- 3D renders, provenance card, certificate of authenticity
- Inquiry pipeline (start projects directly for v1, capture leads in a notes field)
- Configurable stages per shop
- Sourcing tracker (use line items + notes for now)
- Margin analytics dashboard
- Per-stage assignment (single project owner for v1)
- Threaded comments on artifacts
- Multi-payment milestones

### Sizing

Estimated 2-4 weeks given the existing primitives (auth, photos, Stripe, signatures). Any more and you'll have shipped before getting the feedback that should shape it.

---

## Questions worth answering before code

1. **Inquiry vs. Project boundary.** Where does the funnel start? Skipping inquiry now risks regret in 6 months when shops ask "show me what's in discovery."
2. **Per-shop stage templates.** Fixed (faster, opinionated) or configurable (sells to higher-end shops)? Opinionated probably wins for MVP, but the data model should not foreclose configurability.
3. **Pricing model.** Per-project fee, tiered add-on, or unlimited inside a higher SKU? Custom projects are 10-100x repair revenue per job, leave money on the table if it's flat-rated.
4. **Cross-domain reads.** When is a unified customer history view (repairs + projects) needed? That's the only place the two domains meet, and it should be a read-model, not a foreign key.
5. **Designer-as-user.** Are designers internal staff (existing `team_member`) or do some shops use freelancers / contractors? Affects permissions and seat pricing.
6. **Ownership of design IP.** If the client doesn't proceed, does the shop keep the CAD? Encode in a policy template, the way repair terms work today.
7. **Insurance / piece-in-custody.** Custom often involves client-supplied heirloom stones. Custody logs and intake photos matter more than for repairs.
8. **After-sales hook.** Decide now whether the certificate + service log is in scope long-term, because it's the LTV lever and it shapes the data collected during production.
9. **Differentiation.** Gemist, CustomGem, generic CRMs already exist. The wedge is that Workbench already owns the shop's repair workflow, so custom is the upsell, not a standalone product.
10. **Analytics shape.** Popular stones, average margin, time-to-delivery by stage. Decide on the shape before shipping. Painful to retrofit.

---

## Next step

Sketch the migration / model shape for the MVP (Project, Stage, Quote, QuoteVersion, LineItem, ProjectMedia, Approval, Payment) so names and relationships can be argued before any code lands.
