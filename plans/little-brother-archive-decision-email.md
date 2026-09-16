# little-brother: email the host to decide archive vs keep

## Goal

Once a meeting is processed, ask its host (must resolve to an existing `User`
with a brother email address) whether to archive it. Email-first (per prior
decision) — Slack DM is a later addition, same decision-recording backend.

## Why the dashboard, not raw email links

Corporate email scanners and some mail clients pre-fetch every link in an email
body (Outlook Safe Links, image-proxying, security scanners). A GET request that
itself archives/keeps the meeting would get silently triggered before the human
ever opens the email. So the email link only takes the host to a page — a GET,
no side effects — and the actual decision is a button click on that page (a
POST), which a scanner bot doesn't do.

Landing that page inside `dashboard/` (session-gated, already built) rather than
a new signed-token public page:

- Zero new auth/signing code — reuses the existing passwordless login
  (`AuthCode`, `Session`, `Authentication` concern) and its
  `return_to_after_authenticating` redirect, which already handles "log in, then
  land on the page you originally wanted."
- The host must already be a `User` in this app (email-domain gated) for this
  feature to apply at all, so requiring login isn't extra friction — they're
  already a user of the system.
- Ownership check (only the actual host can decide) is a simple `current_user`
  scope, no token-forgery surface to worry about.

## Data model changes

Add to `meetings` (same migration-in-place approach as before, if not yet
shared):

- `host_email` (string) — raw `recorded_by.email` from the Fathom payload, kept
  regardless of whether it resolves to a `User`. Audit trail / lets us later
  report "N meetings had no matching brother host."
- `host_id` (bigint, FK to `users`, nullable) — resolved at processing time.
  `belongs_to :host, class_name: "User", optional: true`.
- `archive_decision` (integer enum) — `undecided: 0, keep: 1, archived: 2`.
  Default `undecided`.

`FathomAdapter#ingest` gains one line mapping
`payload.dig("recorded_by", "email")` into `host_email`. Nothing else about
ingest changes.

## Where host resolution + email-sending happens

Extending `MeetingProcessingJob` (currently just flips `status` to `processed`)
rather than adding a new job:

```
perform(meeting_id)
  find meeting (existing not-found handling stays)
  no-op if already processed (existing guard stays)
  mark processed
  host = User.find_by(email_address: meeting.host_email)
  if host
    meeting.update!(host: host)
    MeetingMailer.archive_decision(meeting).deliver_later
  else
    log_info "no matching host for meeting" (host_email present, no User)
  end
```

Open question: is "notify the host" really the same responsibility as "mark
processed," or should it be its own job the processing job enqueues? Leaning
towards keeping it inline for now — one job, one place to read the whole "what
happens after ingest" story — and splitting only if processing grows a second,
unrelated concern later.

## Mailer

`app/mailers/meeting_mailer.rb`, `archive_decision(meeting)`:

- To: `meeting.host.email_address`
- Body: meeting title/time, one link to `dashboard_meeting_path(meeting)` (or
  similar — see routes below)
- No decision buttons/links in the email itself (see rationale above)

Style: matches existing `AuthMailer` conventions (`app/views/auth_mailer/`,
`mailer_helper.rb`, premailer-rails for inlined CSS).

## Dashboard routes/controller

`Dashboard::MeetingsController` (new):

- `show` — GET, renders the meeting with Keep/Archive buttons as two forms (each
  a POST). Safe, side-effect-free, fine for a scanner to hit.
- `keep` / `archive` — POST (or a single `update` action taking a `decision`
  param) — sets `archive_decision`, scoped to `current_user.meetings_as_host`
  (i.e. `Meeting.where(host: current_user)`) so a logged-in host can't act on
  someone else's meeting by guessing an id.

Routes:

```ruby
namespace :dashboard do
  resources :meetings, only: [:show] do
    member do
      post :keep
      post :archive
    end
  end
end
```

Per house convention: new dashboard routes need auth tests (logged-out →
redirect to login; logged-in as a different user → not found/no access).

## View

Follows the house page layout: `dashboard/page_header` topbar, outer container
`mx-auto w-full max-w-5xl space-y-6`, hero header + two-column grid. Two
`confirm_button_to`-style buttons for Keep/Archive (destructive styling on
Archive, per the danger-zone convention). Will run this past the
`modernize-page`/design conventions when built rather than freehand it here.

## Testing

- Model: `Meeting` `archive_decision` enum default, `host` association.
- `FathomAdapter#ingest`: `host_email` gets populated from payload.
- `MeetingProcessingJob`: host resolved + mailer enqueued when a matching `User`
  exists; `log_info` and no mail when it doesn't; existing
  processed-guard/not-found tests untouched.
- `MeetingMailer`: renders with the right recipient/link (standard Rails mailer
  test, assert on `deliver_later` args/body).
- `Dashboard::MeetingsController`: auth-gated (logged out → redirect),
  ownership-gated (wrong user → can't act), keep/archive sets `archive_decision`
  correctly, `show` has no side effects.

## Open questions for you

1. `archive_decision` values — `undecided/keep/archived` fine, or did you have
   different states in mind (e.g. an explicit "expired, host never responded"
   state, needing a timeout)?
2. What does "archived" actually _do_ once decided — is there follow-up work
   (e.g. delete transcript, move to cold storage) or is the enum column itself
   the whole feature for now?
3. No response from host — do we need a reminder email / expiry after N days, or
   is "sits as undecided forever until they log in" acceptable for v1?
4. Confirm `dashboard_meeting_path` (nested under
   `Dashboard::MeetingsController`) is the right home, vs. some other page (e.g.
   an overview list of meetings awaiting decision) — this plan assumes a single
   meeting's own page has the buttons.
