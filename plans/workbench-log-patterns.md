# Workbench production log patterns

**Window:** Apr 26 – May 26, 2026 (30 days) · severities `warn`+ · source: AppSignal

## Top user-frustration patterns

| #   | Pattern                                                    | Frequency                                | Impact                                  |
| --- | ---------------------------------------------------------- | ---------------------------------------- | --------------------------------------- |
| 1   | `Job ticket was not created — "Job needs a customer"`      | ~40+ across the month, every active shop | Real users submitting and bouncing      |
| 2   | `Customer was not created — "Phone number is invalid"`     | Several hits, often paired with #1       | Blocks inline customer creation         |
| 3   | Rack-attack blocklist hitting real dashboard paths         | One large spike May 21, recurring risk   | Real users banned for minutes/hours     |
| 4   | Shopify `Non-expiring access tokens no longer accepted`    | 5 hits May 15                            | Integration on borrowed time            |
| 5   | Resend `Invalid reply_to field`                            | 2 jobs May 2                             | Customer pickup emails silently failing |
| 6   | Twilio `21408 region not enabled`                          | 1 job Apr 28                             | International SMS silently failing      |
| 7   | `demo_data.reset` reads `/rails/test/fixtures/...` in prod | 2 hits May 19                            | Houston demo data broken                |
| 8   | Portal session mailer `shop_slug: nil` URL build           | 1 hit May 15                             | Customer email never sent               |

## Details

### 1. Job ticket "needs a customer"

- Controller: `Dashboard::JobTicketsController#create`
- Repeat offenders: Jewellery Clinic (Wholesale) #8, Kelowna #16, JEWELLERY CLINIC #10, SarahBijoux #27, Russell #9, Wellington #35
- Repeat team members: 11, 58, 81, 14, 15
- Validation message shifted from `"Customer must exist"` → `"Job needs a customer"` around May 5
- **Fix direction:** make customer selection a blocking step in the UI, not a server-side 422

### 2. Phone number invalid

- Controller: `Dashboard::CustomersController#create`, frequently right before a #1 failure
- Pattern suggests inline customer creation from job-ticket flow
- **Fix direction:** softer validation, inline format hints, accept more formats

### 3. Rack-attack false positives

- May 21 flood: `rule: "scanner paths + fail2ban"` blocking GETs/PATCHes to `/dashboard/job_tickets`, `/dashboard/job_items/*/images`, search URLs with real RCM ticket numbers
- Source IPs: `104.23.197.178`, `104.23.243.182` — both Cloudflare egress
- Compare May 19: same rule legitimately blocked `/.env`, `/test.php`, `/staging/.env` (real scanners)
- **Root cause likely:** rack-attack keys on Cloudflare edge IP, not `CF-Connecting-IP`. One scanner triggers fail2ban, all customers behind that Cloudflare PoP get banned
- **Fix direction:** verify `config/initializers/rack_attack.rb` uses `req.headers["CF-Connecting-IP"]` (or trust the chain via `ActionDispatch::RemoteIp`)

### 4. Shopify deprecated tokens

- `ShopifyAPI::Errors::HttpResponseError` on May 15, 5 hits in 20 min
- Migrate to expiring offline tokens before Shopify enforces

### 5. Resend invalid reply_to

- Job `CustomerNotificationEmailDeliveryJob`, Russell Jewellers tickets #552 and #563
- Shop's configured reply-to is malformed
- **Fix direction:** validate reply-to on save, fall back to `customer@notifications.useworkbench.ca` on send

### 6. Twilio region 21408

- repair_shop 10, customer 5559, job_item 52396
- **Fix direction:** pre-flight phone country vs enabled regions; skip SMS gracefully and inform shop

### 7. Demo data ENOENT

- `Houston::RepairShopsController` → `/rails/test/fixtures/files/image_1.jpg` not found in prod
- **Fix direction:** ship a real demo asset in `app/` or `lib/`

### 8. Portal session URL build

- `MailDeliveryJob` raises `ActionController::UrlGenerationError` with `shop_slug: nil`
- **Fix direction:** guard nil shop_slug at the mailer or upstream, soft-fail the job

## Noise to filter out (not user signal)

- `No route matches [POST] "/"` — bot probes, most frequent line in the window
- `Cannot autoload REST resources for API version '2026_07', folder is missing` — boot warning on every worker start
- `/rails/info/properties`, `/rails/info/routes`, `/rails/db`, `/rails/mailers` — diagnostic probes
- `ActionController::BadRequest: Invalid encoding for parameter` — junk-byte probes
- `ActiveRecord::RecordNotFound` (single hit) — likely a stale bookmark

## Priority order for fixes

1. Job-ticket flow: make customer required client-side
2. Phone validation: relax + inline hints
3. Rack-attack: verify client IP is true client, not Cloudflare edge
4. Shopify: migrate token type
5. Reply-to: validate on save, fall back on send
6. Twilio: pre-flight region check
7. Houston demo data: ship demo asset
8. Portal mailer: guard nil shop_slug
