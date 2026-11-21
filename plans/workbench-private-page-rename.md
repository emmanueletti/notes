# Workbench: rename "client portal" to "private page"

Do this after the client page Uniform migration lands. Decided 2026-11-17: the client's own sign-in area is called their "private page", to feel like private banking. The staff-facing client page copy already says it. Everything below still says "portal".

Internal names stay as they are: `portal_status`, `CustomerPortalMailer`, the `Portal::` controllers, the `portal.` subdomain. Only words people read change.

## Client-facing (highest priority)

Clients read these, so they set the tone.

- Sign-in page, `server/config/locales/en.yml` `portal.sessions.new`
  - `eyebrow`: "Private client portal"
  - `prompt`: "Enter your email address and we'll send a secure link to sign in to the client portal."
- Browser tab title, `portal.shell.title_prefix`: "Client portal"
- Sign-in link email, `customer_portal_mailer.magic_link`
  - `subject`: "Your %{shop} portal sign-in link"
  - `intro`: "Use the link below to sign in to %{shop}'s client portal."
  - `button`: "Portal sign in"
- Job update and intake summary emails use `track_cta` buttons that link to the page. They don't say "portal", but check that the wording leads into "private page".

## Staff-facing

- Job form hint, `customer_visibility_hint` (en.yml lines ~462 and ~487): "Clients see this in their portal. Use Notes for internal-only details."
- Settings, business page (en.yml ~857 to ~876)
  - `address_description`: "…shown on the client portal."
  - `name_description`: "Used on tickets, receipts and the client portal."
  - `customer_portal`: "Client portal" (section heading)
  - `portal_link`: "Client portal link"
  - `portal_description`: "Clients use this link to see their jobs." (fine, keep)
- Settings, job statuses (en.yml ~916): "…in texts, emails and the portal."
- Error shown as a toast when turning a private page on fails. `activerecord.errors.models.customer.attributes.portal_status` has no human attribute name, so Rails prefixes the message with "Portal status". Add `activerecord.attributes.customer.portal_status: Private page`, then reword `email_required` and `email_taken` to read after it.

## French

`server/config/locales/fr.yml` has 9 matching strings under the same keys. Translate per `create-i18n-translation` once the English is settled. Pick the French term on purpose ("page privée" or "espace privé"), not word for word.

## Marketing site

- `marketing/src/_blog_posts/2026-06-25-your-customers-can-now-check-in-on-their-own-jobs.md` uses "client portal" and "portal link" throughout. It also names the old menu item "Send portal sign-in link" and the "Customer panel", both now out of date ("Send sign-in link", the "⋯" menu in the page header).
  - Decide: edit the post, or leave it as a dated announcement and add a short note at the top.
  - Its screenshots (`customer-portal.webp`, `send-portal-link.webp`, `unique-shop-link.webp`, `portal-entrance.webp`) show the old design. Retake them if the post is edited.

## What comes after

This note is step 1 of "Later: the client's private page" in `workbench-2-0-plan.md`. Step 2 moves the page from `portal.` to `my.useworkbench.ca`, and step 3 gives each shop its own domain. The plan has both.

## Open questions

- Does the in-app changelog or help mention the portal anywhere else? Run `audit-changelog` when this ships.
