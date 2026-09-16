# little-brother: meeting recording webhook ingestion

## Goal

Ingest webhooks from meeting recording providers (Fathom first) behind a
per-provider adapter, so adding a second provider later means writing an
adapter, not touching the endpoint.

No internal event enum for now. With one provider and one event
(`new-meeting-content-ready`), a mapped "internal code" has nothing to
dispatch across — it'd just be a rename. The adapter owns the full path:
decide if an incoming event is one it cares about, and if so, ingest it into
the brother agency schema directly. Revisit an internal event vocabulary only
when either (a) a second provider needs to trigger the *same* downstream
action from a differently-shaped event, or (b) one provider needs more than
one distinct downstream action. Until then it's speculative.

## Request flow

1. Provider POSTs to `POST /webhooks/meeting_ingestion/:provider_id` (e.g.
   `/webhooks/meeting_ingestion/fathom`) — own top-level `webhooks` namespace in
   `routes.rb`, not riding on `public`. `webhooks` is the registry for all
   inbound webhook endpoints; `meeting_ingestion` is the first sub-namespace
   under it, scoped to meeting-recording-provider webhooks specifically. Other
   webhook categories (unrelated to meetings) would get their own sibling
   sub-namespace later, not crowd into this one.
2. One controller handles every provider in this namespace:
   `Webhooks::MeetingIngestion::BaseController < Webhooks::BaseController`.
   `Webhooks::BaseController` skips session/CSRF (external caller) and holds
   what's shared across *all* webhook categories (raw body access helpers,
   common persistence/enqueue pattern). It runs a `before_action` that calls
   `authorized?` and renders `401` on `false`; `authorized?` itself
   `raise NotImplementedError` in the base class — every concrete webhook
   controller (currently just `MeetingIngestion::BaseController`, future
   ones for other categories) is forced to define its own, so a new webhook
   category can't accidentally ship without an auth check. No per-provider
   controller class — `:provider_id` is just a param, not a route segment tied
   to a controller. Adding a provider means adding an adapter and pointing that
   provider's dashboard at the new `provider_id` in the URL; no new route or
   controller.
3. Controller reads `params[:provider_id]`, resolves the adapter class via
   `Webhooks::MeetingIngestion::ProviderRegistry`, hands it the raw request
   body + headers. Unknown `provider_id` → `404`, nothing persisted.

Routes:

```ruby
namespace :webhooks do
  namespace :meeting_ingestion do
    post ":provider_id", to: "base#create"
  end
end
```
4. `MeetingIngestion::BaseController#authorized?` resolves the adapter via
   the registry and delegates: `adapter.authorized?(raw_body, headers)`. Each
   adapter answers this for its own provider — Fathom: HMAC-SHA256,
   base64-decoded secret, constant-time compare against the raw body, before
   any JSON parsing. Returns `false` (not raise) on mismatch → base controller
   renders `401`, nothing persisted.
5. Controller asks the adapter `relevant?(event_name)` — cheap, no I/O, just a
   name check, so it belongs in the request cycle rather than a job. Persists
   the raw inbound webhook either way (see Persistence), with `status: skipped`
   if not relevant. Only enqueues the processing job when relevant — no point
   putting things we've already decided to ignore on the queue. Controller
   returns `200` fast.
6. Job loads the row and calls the adapter's `ingest!(payload)`: parse
   transcript/summary/action items, write into the brother agency
   message-ingestion schema. Idempotency check happens before `ingest!` runs
   (see Idempotency).

## Code layout

- `app/controllers/webhooks/base_controller.rb` — shared across all webhook
  categories: skip session/CSRF, `before_action` gating on `authorized?`,
  common persist/enqueue helpers. Defines `authorized?` as
  `raise NotImplementedError` — subclasses must override.
- `app/controllers/webhooks/meeting_ingestion/base_controller.rb`
  (`< Webhooks::BaseController`) — single entry point for every
  meeting-recording provider; implements `authorized?` by resolving the
  adapter from `params[:provider_id]` via the registry and delegating to
  `adapter.authorized?`.
- `app/webhooks/meeting_ingestion/fathom_adapter.rb` (or
  `app/services/webhooks/meeting_ingestion/fathom_adapter.rb` — pick one
  convention, we don't have a `services/` dir yet) — everything Fathom-specific:
  signature verification, deciding which events matter, and ingesting a
  relevant payload into the brother agency schema.
- `app/webhooks/meeting_ingestion/provider_registry.rb` — `provider_id ->
  adapter class` lookup (e.g. a frozen `Hash` constant with a `.fetch` that
  raises/returns nil on miss for the controller to turn into a `404`).
- `app/jobs/process_webhook_event_job.rb` — loads the persisted row, does the
  idempotency check, calls `adapter.ingest!`, updates status. Never runs for
  rows the controller already marked `skipped` — those aren't enqueued.

Adapter interface (rough):

```ruby
class FathomAdapter
  def self.authorized?(raw_body, headers) # bool, HMAC check
  def self.relevant?(event_name) # true only for "new-meeting-content-ready"
  def self.ingest!(payload) # parses + writes into brother agency schema
end
```

Registry (rough):

```ruby
module Webhooks
  module MeetingIngestion
    module ProviderRegistry
      ADAPTERS = {
        "fathom" => FathomAdapter
      }.freeze

      def self.fetch(provider_id)
        ADAPTERS.fetch(provider_id) { raise ActionController::RoutingError, provider_id }
      end
    end
  end
end
```

## Persistence

- New table, e.g. `webhook_events`: `provider`, `event_name` (raw string from
  the provider, e.g. `new-meeting-content-ready`), `external_event_id`
  (nullable if provider doesn't give one), `dedupe_key`, `raw_payload` (jsonb),
  `status` (pending/skipped/processed/failed), `processed_at`, timestamps.
- Store the raw payload even for events we skip — cheap insurance, lets us
  replay if we add handling for that event later.
- Migration via `bin/rails g migration`, not hand-written.

## Idempotency

Providers can and do redeliver. Dedupe key = `provider + external_event_id` if
Fathom gives a stable id per delivery, otherwise
`provider + meeting_id + event_name`. Unique index on `dedupe_key`;
job/controller does find-or-create and skips reprocessing on conflict.

## Testing

- Controller test: valid signature + known event → 200, row persisted, job
  enqueued. Bad signature → 401, nothing persisted. Unrecognized event type →
  200, row persisted as `skipped`.
- Adapter unit test: Fathom payload fixture → `ingest!` writes the expected
  rows into the brother agency schema. `relevant?` false for other event
  names. Bad HMAC → `authorized?` returns `false`.
- No system test needed here — this is an API endpoint, not a browser flow.

## Open questions for you

1. Table/column naming above are placeholders — want `webhook_events` or
   something more specific like `incoming_meeting_webhooks`?
2. Confirm `app/webhooks/` as the new top-level dir for this, vs
   `app/services/webhooks/` — no existing `app/services/` in this repo yet, so
   this sets precedent.
3. Fathom webhook secret — where's it going to live? Rails credentials vs
   `config/app.yml`? (Not touching this myself per the no-`op`/no-secrets rule —
   just flagging it needs a decision.)
