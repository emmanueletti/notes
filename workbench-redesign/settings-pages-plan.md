# Workbench settings pages: Uniform build plan

Decided 2026-11-17 in the settings prototype (https://claude.ai/artifact/QKDjB8atiFCeWY1v4a6bJk). Business and Reminders are already built (commit d232d4f5).

## Rules every page follows

- Choices (switches, selects, radios, reorder) save when they change, with a toast.
- Typed text edits in a dialog with Save (u-setting-edit row with a pencil).
- Long text clients see (messages, terms) opens on what clients see, then Edit, with Cancel and Save. Nothing autosaves.
- No cards around settings; Uniform pieces only; no Tailwind.
- French fields and language choices only show when at least one client prefers French.
- Width: narrow (768) by default; Team, Job form and Messages use the default container (1280).

## Pages

Team (C, table)
- u-table: name (avatar), email address, role, access; row menu with resend or cancel invite, invite to sign in, archive or restore.
- Active and Archived as u-page-tabs.
- One Add person dialog: name, role, then "Send an invite" or "Don't invite", email address.
- Change role in the menu is a new feature; not decided, leave out unless asked.

Job statuses (A)
- Flat stage groups (To do, In progress, Waiting, Ready, Done, Cancelled) with the stage meaning and Add status.
- Rows: drag handle, colour (menu, saves at once), name, job count and Default, menu.
- Rename in a dialog that holds the English and French names.
- A "French names" setting row with Translate and the missing count.

Billing (B for trial, rows once subscribed)
- Trial: toned-down banner with days left, one plan block with a Monthly / Annual switch, the price in mono, what's included, Subscribe.
- Subscribed: setting rows for plan, payment method, receipts; Cancel subscription after a divider.

Messages (B)
- Opens on the email as the client sees it, with Edit.
- Edit: Email / Text tabs, language select, subject, message, Insert menu for the details Workbench fills in, preview, Reset to default, Cancel, Save.

Policies
- Read view: the terms as Uniform prose, Edit in the header, language tabs.
- Edit: rich text editor with a quiet toolbar, "Start from our template", Cancel and Save.

Job form (A plus)
- Question list with drag handle, answer type and choices, menu; "Your team sees, for each piece" preview beside it.
- Add and Edit open one dialog; answer types in plain words with an example.
- First visit: starter questions in two groups (Most shops ask, Often useful).

## New data (backend work)

- Answer type "Choose any" (multi-select). Needed for "Work needed".
- Answer type Money. Needed for declared value and the go-ahead limit.
- Question setting "Print on the job ticket" (build first).
- Question setting "Must be answered".
- Question setting "Show the client on their pickup page" (later).

## Order

1. Team
2. Job statuses
3. Billing
4. Messages and Policies
5. Job form (Uniform conversion first, then new answer types and settings)
