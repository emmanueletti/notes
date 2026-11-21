# Item 42: replace polymorphic associations with real foreign keys

2026-11-07. Five polymorphic belongs_to in server/app/models. Each owner type is a fixed, small set, so each becomes plain FK columns with real foreign keys, cascades and indexes. No type strings, no constantize, Postgres enforces tenant-safe joins.

## Today

| Table | Association | Owner types in code | Readers |
|---|---|---|---|
| events | owner | JobItem (Eventable callbacks), JobTicket (customer_notification_sent) | job item timeline (item events + ticket events), analytics `subject` |
| customer_notifications | notifiable | JobTicket (intake), JobItem | events, sending service. Already has an ignored `job_item_id` column, and JobItem `has_many :customer_notifications`, which reads that ignored column |
| notes | noteable | Customer (customer page), JobItem (item timeline), JobTicket (has_many, no UI) | customer show, item timeline |
| shared_links | shareable | JobTicket only | portal share link |
| customer_terms_signature_events | signable | JobTicket only (has_one, unique index) | terms signature |

## Target

Prod 2026-11-07: events JobItem 165,951 / JobTicket 5 / Project 55; notes JobItem 2,402 / Project 4; notifications JobItem 2,806 / JobTicket 490; shared_links JobTicket 2,044; signatures JobTicket 305.

- One nullable FK column per owner type, the same mapping the polymorphic pair holds today, plus `CHECK (num_nonnulls(...) = 1)` where there are two owners. Not "ticket required plus optional item": a job item can move to another ticket (assign_to_new_job), so a ticket id on item events would go stale and its cascade would delete the wrong rows.
- events: `job_item_id`, `job_ticket_id`, exactly one set.
- customer_notifications: `job_item_id` (existing column, today ignored and stale), `job_ticket_id`, exactly one set.
- notes: `job_item_id` NOT NULL. Customer and JobTicket `has_many :notes` go away (no rows, no UI; the customer page box is `customers.additional_notes`).
- shared_links, customer_terms_signature_events: `job_ticket_id` NOT NULL, unique.
- FKs `on_delete: :cascade` to the owner.
- Eventable's callbacks move into JobItem, the concern goes.

## Rollout, 2 deploys

1. Migrations add the new columns nullable, indexes concurrently, FKs validate: false then validate. Models copy the polymorphic owner into the new column on create. Backfill task fills the new columns where the owner row exists (orphans would break the FK) and clears the stale customer_notifications.job_item_id on ticket notifications. Run after deploy.
2. Before it: delete Project-owned events and notes and any orphans left unfilled (counts from the backfill output). Then models read only the new associations; migration adds NOT NULL / exactly-one checks and drops the polymorphic columns.

The user accepted about a minute of errors on deploys, so deploy 2 can drop the old columns directly, with no separate ignored_columns deploy.

## Check in prod before starting

```ruby
{events: Event.group(:owner_type).count, notes: Note.group(:noteable_type).count, notifications: CustomerNotification.group(:notifiable_type).count, shared_links: SharedLink.group(:shareable_type).count, signatures: CustomerTermsSignatureEvent.group(:signable_type).count}
```

Any type not in the table above (for example leftover `Project` notes or events) needs handling first. The parked custom projects cleanup deletes Project events and notes.

## Open

- Are there JobTicket notes in prod? If not, notes drop the job_ticket owner.
- Order: start with shared_links and signature events (one owner each, smallest), then events and notifications together, then notes.
