# Customer messages: engine, domain model and storage

Date: 2026-11-17. Stage 1 of the customer messages rework. The research is in workbench-customer-messages-research.md, and flows and UI come after this.

## Learnings from the current code

### Storage

- `customer_notifications` doesn't store who a message went to (the email address or phone number at send time), or the provider's id (the Resend email id or the Twilio message id). We can't tell a client which address we used, or match a bounce back to a message.
- `job_item_id` is ignored by the model but still a column. `JobItem has_many :customer_notifications, dependent: :destroy` still joins on it, so deleting a job item deletes nothing (0 rows use it in dev). This is a latent bug, and the column can be dropped.
- `template_snapshot_updated_at` and `customer_notification_template_id` are written but never read.
- `customer_notification_templates.previous_subject` and `previous_body` are written on update and never read. Soft-deleted rows build up as an unused history.
- `delivered_at` actually means "handed to the provider", not delivered.

### Two records for one fact

- `job_tickets.intake_summary_emailed_at` duplicates the intake summary message. It's set when the email is queued, not when it's sent, so a failed send still disables the "Send summary" button for good. Dev already disagrees with itself: there's 1 intake summary message but 0 tickets with the timestamp.
- The email confirmation is tracked by a CONFIRMATION_SENT consent event, which is also used to stop it from being sent twice. That's fine for consent records, but the client's message history never shows it.

### Content

- Status update messages store plain text with the placeholders filled in. Intake summaries store the full mailer HTML, and the job then builds the mail again from the mailer instead of using what was stored.
- Text messages are sent from a `body:` argument on the job, not from the record.
- The sign-in link creates no record at all.
- The intake summary mailer has no text part.

### Behaviour spread around

- The email job switches on the type to pick the mailer, and again to skip the consent check for intake summaries.
- Default templates come from a hand-written table of 8 YAML file paths.
- Placeholders are a constant hash of lambdas. Every placeholder is offered in every template, whether or not it makes sense there.
- The type value `jobs_ticket_intake_summary` has a typo.

## Proposed model

### One table, one class per kind (STI)

`customer_messages`, with `type` holding the kind:

- `CustomerMessage::StatusUpdate`
- `CustomerMessage::IntakeSummary`
- `CustomerMessage::SignInLink`
- `CustomerMessage::EmailConfirmation`

Single-table inheritance (STI) puts each kind's rules on the record itself, so there's no separate kind object and no lookup code. A subclass says:

- `channels`: which channels it can use (only StatusUpdate can go by text)
- `requires_consent?`: true for StatusUpdate and EmailConfirmation, false for the required messages (sign-in link, intake summary)
- `editable?`: true when the shop can change the wording (StatusUpdate)
- `placeholders`: the placeholders its templates may use, if editable
- `compose(...)`: a class method that builds an unsaved message with the subject and text filled in

The preview and the sent message are the same object. The preview is `compose` before saving, and sending saves it and calls `deliver_later`.

```ruby
message = CustomerMessage::StatusUpdate.compose(job_item:, channel: "email", sent_by: current_user)
message.save!
message.deliver_later
```

### Columns

| Column | Notes |
|---|---|
| repair_shop_id, customer_id | not null |
| type | the STI kind |
| channel | email or sms |
| about_type, about_id | polymorphic and nullable: a JobItem, a JobTicket, or nothing for a sign-in link |
| to | the email address or phone number at send time |
| subject | email only |
| body | the text the client read, for every kind: the SMS text or the email's plain-text version, saved when the message is composed |
| html | email only: the exact HTML handed to Resend, saved at delivery. The sign-in link is replaced with a placeholder |
| locale, tone | renamed from language_code and language_formality |
| status | pending, sent or failed |
| sent_at, failed_at | replace delivered_at |
| provider_id | the Resend email id or Twilio message id |
| sent_by_id | renamed from created_by_id. Null for system sends |
| status_key, status_names | StatusUpdate only: the status at send time, kept because statuses can be renamed |

These columns are dropped: `customer_notification_template_id`, `template_snapshot_updated_at`, `job_item_id`.

### Delivery

- There's one job, `CustomerMessage::DeliveryJob`, and `message.deliver` does a `case` on the channel.
  - Email goes through one `CustomerMessageMailer`, with a view per kind: `status_update`, `intake_summary`, `sign_in_link`, `email_confirmation`.
  - SMS goes through `SmsDeliveryService` with `message.body`.
- The consent check runs at send time and reads `requires_consent?`, so no kind gets a special case.
- The sign-in token is generated inside the delivery and never stored. The preview uses a dummy link.
- The retry and transient-error handling in today's `CustomerNotificationDelivery` concern moves over unchanged, along with the Twilio permanent errors that revoke consent.

### Templates

- `customer_message_templates` has one row per shop, kind, channel, locale and tone, holding a subject and body. Reverting to the default deletes the row, so there's no soft delete or previous-version history.
- Defaults move from the YAML files into the locale files, so i18n-tasks and the translation process cover them. French tone becomes the key (`body_formal`, `body_casual`).
- The placeholders become a small object that both checks a template and fills it in, built from the kind's `placeholders`.

### What stays the same

- Consent columns on customers, and `customer_consent_events`. Consent is legal proof, so it's kept apart from messages.
- The job item timeline, which still turns sent messages into Event objects in memory.

## Storage change and backfills

Create a new table rather than renaming the old one. The new container runs its migrations while the old one is still serving requests, so a rename would break the old code during the deploy. Creating a table also lets the shape change cleanly.

1. **Deploy 1.** Migrations create `customer_messages` and `customer_message_templates`. Code writes and reads only the new tables. Pending messages in the old table get sent by the old jobs, which still exist in this deploy.
2. **Backfill** (`lib/tasks/backfills.rake`, tested in `test/tasks/`):
   - Each `customer_notifications` row becomes a `customer_messages` row, mapping the type (the `jobs_ticket_intake_summary` typo becomes IntakeSummary). Intake summary rows keep their stored HTML in `html`.
   - Each active `customer_notification_templates` row becomes a `customer_message_templates` row. Soft-deleted rows are skipped.
   - The sign-in link and email confirmation have no history to bring over.
   - History is missing until the backfill runs, a few minutes after the deploy. That's acceptable at our volume (to be confirmed with production counts).
3. **Deploy 2.** Drop `customer_notifications`, `customer_notification_templates`, the old jobs and `job_tickets.intake_summary_emailed_at`. Before dropping it, the code reads "summary sent" from `job_ticket.messages`, and tickets with the timestamp but no message get backfilled.

## Open decisions

- STI with a class per kind (recommended), or one class with a kind column and plain objects for the rules.
- Status snapshot: two explicit columns (recommended), or one `details` jsonb column.
- Production counts needed before backfilling (read-only):
  - customer_notifications grouped by type and status
  - active templates
  - tickets with intake_summary_emailed_at and no intake summary message

## Agreed Messages settings UI (from the other session, 2026-11-17)

Source: the user's prototype https://claude.ai/artifact/QKDjB8atiFCeWY1v4a6bJk, Messages page, option B. This belongs to stage 2 (flows), built on the new model, in Uniform only with no Tailwind.

- The page opens on the message as the client sees it, with an Edit button.
- Edit shows:
  - Email and Text tabs
  - a language select, only when a client prefers French
  - subject and message fields
  - an Insert menu of fill-in details, each listed by its plain name
  - the preview
  - Reset to default, Cancel and Save
- Nothing autosaves.

What this means for the engine: each kind's placeholders need a plain-language label in every locale, for the Insert menu. The preview renders a composed but unsaved message using sample data.

## Decision: save what was sent, for every kind (2026-11-17)

Every message stores exactly what the client received, including the fixed-copy kinds. The reasons:
- Shops edit their templates, so today's template isn't what an older message said.
- Fixed copy changes too, with every deploy and every translation fix.
- An intake summary is built from the ticket's items and details, which change after it's sent.
- When a client says "you told me X", support needs the exact words.

Storage: `body` holds the plain text for every kind, saved when the message is composed. `html` holds the final email HTML, saved at delivery. The sign-in link's token is never stored: the link is swapped for a placeholder before saving. The size is small at our volume, so we keep no rule for deleting old messages yet.
