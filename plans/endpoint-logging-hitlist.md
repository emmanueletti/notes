# Endpoint logging hitlist

Close the observability gaps where a user-facing failure renders a 422 (or returns an error) with no signal, so future "customer papercuts" surface the way the original `JobTicketsController#create` "Customer must exist" bug did.

## Background

We caught "Customer must exist" through **AppSignal Logs**, not exception tracking and not endpoint return codes. The path:

`Monitoring::Logging.log_error` → SemanticLogger → `AppsignalStructuredAppender` → `Appsignal::Logger` → AppSignal Logs

`JobTicketsController#create` never raises and returns a 422 the user sees as a flash. The `log_error(self, "Job ticket was not created", properties: { errors:, params: })` line (added 2026-03-30, commit `c19c45b8`) is what carried `errors: "Customer must exist"` into AppSignal. Endpoints that fail without that line are invisible to us.

## The pattern to apply

Mirror the established shape: log immediately before rendering the error.

```ruby
errors = record.errors.full_messages.to_sentence

Monitoring::Logging.log_error(self, "<Thing> was not <created|updated>", properties: {
  errors: errors,
  # ids that scope the failure: job_ticket_id, customer_id, etc.
})

flash.now[:alert] = errors
render :show, status: :unprocessable_content
```

Notes:
- Strongest example in the codebase: `public/signups` pairs `log_warn` with a `Monitoring::Events.increment_counter("sign_up_failures", ...)`. Consider a counter for high-volume create paths so you get a metric, not just searchable logs.
- For the Shopify API endpoint, log on every error branch and include the error key already in the JSON response.
- TDD per CLAUDE.md: assert the log call (Mocha `expects` on `Monitoring::Logging`) in each controller test. No code comments.

## Hitlist

### High priority

- [x] **1. `intake/additional_items_steps#create`** — done. `log_error(self, "Additional item was not added", properties: {job_ticket_id:, errors:})` on `@job_item.save` failure. Test: "#create logs an error when the new item is invalid".
- [x] **2. `intake/summary_emails#create`** — done. `log_error(self, "Intake summary email was not sent", properties: {job_ticket_id:, customer_id:, errors:})` on service failure. Test: "#create logs an error when the summary cannot be sent".
- [x] **4. `shopify/api/job_tickets#create`** — done. Added a `render_validation_failed` helper (shared by the `save`-false and `RecordInvalid` branches, `log_error` "Shopify job ticket was not created"), plus per-branch logs: `ShopifyCustomerNotFound` → `log_error` "Shopify job ticket create failed", `IntegrationNotConnected` → `log_warn` "...blocked: integration not connected", `MissingParam` → `log_warn` "...rejected a bad request". Tests cover missing-param, not-found, validation_failed (real `RecordInvalid` via a bad imported email), and integration-not-connected. Used structured logs, not `Monitoring::Errors.report`, to keep error tracking low-noise; revisit if these need backtraces.

### Already covered (dropped after reading the runtime path)

- ~~**3. `intake/photos_steps#update`**~~ and ~~**5. `JobItemImageAttachable#apply_image_changes`**~~ — NOT silent. `JobItemImageManager#attach` (`app/models/job_item_image_manager.rb:37-46`) already `log_error`s **and** `Monitoring::Errors.report`s on S3 connection timeouts, and re-raises everything else (so non-timeout failures surface as 500s in AppSignal error tracking). `apply_image_changes` returns `false` only on that already-logged S3 timeout. Adding a log in the concern would just double-log the same event. The file-level grep missed this because the concern file itself has no `Monitoring` call; the signal lives one layer down in the manager. No change made.

### Medium priority

- [x] **6. `intake/details_steps#update`** — done. `log_error` "Intake job ticket was not updated" `{job_ticket_id, errors}` on `SaveDetailsService` failure, mirroring `#create`. Test: "#update logs an error when the update is invalid".
- [x] **7. `settings/form_templates#update`** — done. `log_error` "Form template was not saved" `{repair_shop_id, errors}` in the controller `else` (covers the validation/blank-label failures the service returns silently; the service still logs the rare `ActiveRecordError` DB path itself, so that one path double-signals, acceptable). The empty-fields guard stays unlogged (benign UX nudge). Test: "#update logs an error when the change is rejected".
- [x] **8. `settings/notifications#update`** — done. `log_error` "Notification template was not saved" `{repair_shop_id, notification_type, channel, locale, errors}` on invalid template. Test: "#update logs an error on an invalid template".
- [x] **10. `public/team_member_invitation_acceptances#create`** — done. `log_warn` "Team member invitation acceptance failed" `{team_member_id, errors}` on `accept_invitation` failure (errors array is empty in the opaque `failure_fallback` case, which is exactly what we want to see). Test: "#create logs a warning when invitation acceptance fails".

### Dropped (defensive / unreachable, same class as 3 and 5)

- ~~**9. `settings/policies#update`**~~ — NOT reachable with real data. `PolicyTranslation` validates only `locale` (presence + inclusion + uniqueness scoped to policy), and the controller already guards blank/unsupported locale before saving; `content` (`has_rich_text`) has no validations. So `@translation.save` in the `else` can't return false in practice. Logging it would require stubbing a path that can't happen. No change made. If a validation is ever added to `PolicyTranslation`, revisit.

### Low priority

- [x] **11. `public/passwords#update`** — done. `log_warn` "Password reset failed" `{team_member_id, errors}` on weak/mismatched/breached-password failure (errors empty in the opaque fallback). Test: "#update logs a warning when the reset fails". (Note: the gap is in `#update`, not `#edit` as originally written.)
- [x] **12. Houston staff tools** — done (partial, by design). `extend_trial_end_date` now `log_warn`s "Trial end date update failed" `{repair_shop_id, errors}`. The "Demo data reset failed" path was **already logged** (`reset_demo_data` rescue, `repair_shops_controller.rb:88`), so no change there. The remaining Houston alerts ("This shop has no owner", "Invalid trial end date...", plan-conversion guards) are input/routing guards, not failures, so left unlogged.

## Out of scope (intentionally quiet)

The ~25 `redirect ... alert: "...not found"` sites (missing job ticket / job item / note / customer). These fire on stale links and bots; logging each adds noise without signal. Leave them as-is.

## Already solid (reference implementations)

Failure path already logs: `job_tickets#create`, `job_items#create`/`#update`, `customers#create`, `customers/addresses#update`, `customers/contacts#update`, `intake/details_steps#create`, `terms_signatures`, `public/signups` (logs + counter).

## Verification

- [x] Confirmed (manually, by Emmanuel): the original "Customer must exist" finding sat in AppSignal **Logs**, not error tracking. Matches the code path (`Monitoring::Logging.log_error` → AppSignal Logs). No OAuth needed.
- [ ] After fixes ship, trigger one failure per patched endpoint in dev and confirm the log lands in AppSignal Logs with the expected properties.
