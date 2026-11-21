# How our top shops use the job page

Study date: 2026-11-19. Author: Emmanuel, with Claude. Sources: PostHog events
and pageviews for the last 30 days, 10 session replays read by PostHog Replay
Vision, the Workbench codebase and AppSignal.

## Verdict

Our top shops don't browse jobs. They work through a queue of them: find a job
by its number, change a few fields, save, go back, and do the next one, dozens
of times a session. Workbench is built around a single job and its page, so
every update sends them through pages they don't need: the job page, the edit
form, the job page again, then the Jobs list. The complaint about the Edit
button was the visible edge of that. Edit is the main action on the job page at
five of the six active shops, and the job page itself is mostly somewhere people
pass through in 2 to 8 seconds. The sixth, Russell Jewellers (9), never edits at
all: it changes every status from the Jobs list.

The fix isn't more buttons. Workbench should treat updating a job as the core
loop and make it fast from start to finish: find, change, save, next. The best
modern back-office tools (Linear, Shopify admin, Superhuman, Front) win on
exactly this. You stay in your list, act with the keyboard, edit in place and
never lose your spot.

## What triggered this

On 2026-11-17 we moved the job page to Uniform (commit `c7fc82a0`). Print and
Edit moved from visible buttons into the ⋯ menu, and "New job" became the main
button. Fort Richmond (29) asked for Print and Edit back. Rather than treat it
as a layout preference, we looked at how six shops actually use the page. A
seventh account, C Creations test (53), is a test account, so it's left out.

## Shops at a glance

| Shop                  | People and device                | Intakes (30 days) | Edits from the job page    | Main reason to edit       | After saving                          | Prints                                      |
| --------------------- | -------------------------------- | ----------------- | -------------------------- | ------------------------- | ------------------------------------- | ------------------------------------------- |
| JC Kelowna (16)       | 1, Mac and Windows               | 69                | 110, 3s after landing      | Status plus notes         | Jobs list (95 of 110)                 | 99, mostly right after intake               |
| JC Surrey front (10)  | 1, Mac and Windows               | 74                | about 60, 3s after landing | Status                    | Jobs list (40), stay (27), print (19) | 93, after intake and straight from the list |
| C Creations (54)      | 1, Windows, new since 2026-11-07 | 45                | 90, 2s after landing       | Description, price, dates | Jobs list (74 of 90)                  | 16                                          |
| Sarah Bijoux (27)     | 3, Mac                           | 23                | 50, 8s after landing       | Status and price          | Jobs list (47 of 50)                  | Never                                       |
| Fort Richmond (29)    | 1, Mac                           | 34                | 46, 6s after landing       | Price                     | Print technician sheet (30 of 46)     | 54                                          |
| Russell Jewellers (9) | 1, Mac                           | 9                 | 0                          | None (status from list)   | None                                  | 11, almost all right after intake           |

Every active shop works on a desktop computer. JC Surrey wholesale (8), does
bulk intake on an iPad and is a separate case, so it isn't covered here.

## What we learned

### 1. Shops work in queues

The replays of JC Kelowna (16) and C Creations (54) show the same loop again and
again:

1. Type a job number into the Jobs list search. They read it off the paper
   ticket or the tag on the item.
2. Open the job, then go straight to Edit.
3. Change the status, add a line to the description, sometimes update the price.
4. Save, click the Jobs breadcrumb, and type the next number.

JC Kelowna (16) did this 34 times in one 25-minute session on 2026-11-07. C
Creations (54) edited one job (63467) five times in one session. This is how a
person at a desk works through a pile of tickets. It's the main way the job page
gets used, and we designed for it the least.

C Creations (54) goes further and runs two windows at once. On 2026-11-12 the
request logs show two sessions side by side from 13:47 to 15:24: one doing
intake (26 intake requests), the other working through edits (160 edit
requests). One person takes jobs in while catching up on the queue in another
window. That's a strong hint that the queue needs its own space, like the
Jobs list side panel in fix 8.

### 2. The job page is a pass-through

People spend 2 to 8 seconds on the job page before they leave for Edit or Print.
After saving, it's 2 to 3 seconds before they leave for the Jobs list. Sarah
Bijoux (27) is the only shop that reads the page: it opens a job, spends about 2
minutes on it and changes the status there (123 times). Russell Jewellers (9)
uses the job page for two things only: printing right after intake and sending
clients a message (9 times).

### 3. One form beats several quick controls

The job page has had a status picker since 2026-09-14. JC Kelowna (16) still
makes 91 of its 109 status changes through the full edit form, and JC Surrey
front (10) makes 41 of 65 that way. In one replay, JC Kelowna (16) used the
picker and then opened Edit anyway to add a note. People update several things
at once, so one predictable form beats three single-purpose controls. C
Creations (54) is the exception: it uses the picker and the Jobs list quick
actions for status, and opens the form for everything else. Russell Jewellers
(9) goes further. All 14 of its status changes happen on the Jobs list, through
the selection and bulk update there, and it never opens a job to do it. When an
action sits on the list, some shops use it there and skip the job page entirely.

### 4. The description is being used as a notes log

JC Kelowna (16) adds service notes to the description field on almost every
status change. Workbench already has job notes and a timeline, but nobody in
these replays uses them. Either shops don't know notes exist, or notes take too
many steps when you're working through a queue.

### 5. Printing belongs to a moment, not a page

- JC Kelowna (16), JC Surrey front (10) and Russell Jewellers (9) print the
  combined print-out within 5 seconds of finishing an intake (51, 15 and 7
  times). For Russell Jewellers (9) that's 7 of its 9 intakes.
- Fort Richmond (29) prints the technician sheet within 3 seconds of saving an
  edit (30 times).
- JC Surrey front (10) also opens a job from the list just to print it (34
  times).
- Sarah Bijoux (27) never prints.

A permanent Print button helps some shops and clutters the page for others.
Print at the moment it's needed, at the end of intake and after an edit, helps
everyone who prints.

### 6. The QR code on the ticket goes unused

The technician sheet prints a QR code that opens the job page. In every replay,
people type the job number instead. Desk staff have no reason to pull out a
phone, and the code opens the job page, which isn't where they want to go.

## Silent frictions: where Workbench fails them

These are frictions no shop has told us about. Each one costs time on every job.

| Friction                                                         | Evidence                                                                                                                                                   | Cost                                                          |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Edit and Print hidden behind ⋯ since 2026-11-17                  | Fort Richmond (29) complained, and edit counts at every shop                                                                                               | 1 extra click on every update                                 |
| Save lands on the job page, not where you started                | 280 saves followed by an exit within 3 seconds, across 4 shops                                                                                             | 1 page load and 1 click per update                            |
| The search is lost on the way back, so it's retyped every time   | Replays of 16 and 54                                                                                                                                       | Typing per job, plus finding your place again                 |
| An exact job number still shows a results table                  | Code: `_exact_id_match` lists matches and still needs a click                                                                                              | 1 page and 1 click per job                                    |
| No keyboard path at all                                          | Every active top shop works on a desktop                                                                                                                   | Mouse travel on every step                                    |
| Status picker solves the wrong job                               | 91 of 109 status changes at JC Kelowna (16) go through the form                                                                                            | The picker adds clutter without saving time                   |
| Notes live in the description                                    | Replays of 16                                                                                                                                              | History gets overwritten and has no timestamps                |
| "New job" is the main button on a page people use to update jobs | Edit outnumbers new jobs from this page at every shop                                                                                                      | The most-used action looks secondary                          |

## What this teaches us

- **A complaint names a symptom.** "Put the buttons back" was true, but the real
  need behind it was a faster queue. Always ask which loop the request sits in.
- **Judge clutter by how often a control gets used.** Hiding the most-used
  action to make the page look cleaner made it slower. The ⋯ menu is for rare
  actions.
- **Design for the queue, not only the record.** Shops spend their day moving
  through many jobs. A page built to show one job well can't make that faster on
  its own.
- **After an action, send people back to their work.** Every time we drop
  someone on a page they then leave, we cost them a page load.
- **Power users are on desktops.** They'll learn shortcuts if we show them, and
  shortcuts pay back on every job.
- **We can't see what people change.** Description, custom-field and client
  edits send no event, and autocapture strips element ids. This study needed
  replays to answer basic questions, so observability is part of the fix (see
  Observability below).

## Fixes

The order follows evidence and effort. Each fix names what it removes from the
loop. Ship each one behind a Flipper flag, except bug fixes. Tick an item when
it ships, with the commit and date.

### Now (week of 2026-11-17)

- [x] **1. Edit back in the job page header**, as a labelled button with a
  pencil icon. Shipped 2026-11-19 as a stop gap (`54d6671d`), without a flag,
  since the evidence already settled it. Print stays in the ⋯ menu. Removes the
  extra click from every update.
- [x] **2. Check the dropdown double-click on Windows.** Done 2026-11-19: no
  bug. The dead click spike is real data but a false signal.
  - It isn't Windows-only. Dead clicks rose about 30 times at all 9 active shops
    on 3 operating systems from 2026-11-17, Mac Safari included.
  - It isn't only dropdowns. Text inputs have the most (590), then selects
    (488). Clicking into a text box to type can't be broken.
  - It came with the Uniform move, not a PostHog release. Under PostHog's SDK
    1.450.0, clicks before the 2026-11-17 deploy had 0 dead clicks out of
    1,025, and 339 out of 4,644 after it.
  - People aren't frustrated. Rage clicks went from 4.8 to 6.8 per 1,000
    pageviews, and rage clicks on form fields fell from 15 to 7.
  - In the dev app (Chrome 158), every Uniform dropdown opened on the first
    click, including moving straight from one open list to another.
  Uniform changes the page through CSS and the browser's native popovers
  (`:focus`, `appearance: base-select`, `popover`), and PostHog doesn't see
  those as changes, so it calls the click dead. The replay summaries' "second
  click" came from AI guessing at masked recordings. Fix lives in O7.
- [x] **3. Confirm what C Creations (54) saw on 2026-11-12.** Done
  2026-11-19: no server error happened. The request logs (PostHog logs, by
  session id) show every request in both of the shop's sessions that afternoon
  succeeding, including all 4 saves of job 63471 and both of 63537. AppSignal
  has no exception, and there was no deploy that day. Two Replay Vision scans
  described two different dialogs, on two jobs, with different wording and
  buttons, and neither wording exists anywhere in our code. Replays mask all
  page text, so the scanner made it up. Optional: a person can watch
  [the recording at 55:00](https://us.posthog.com/project/718224/replay/01a1d118-5e88-7bd8-90f5-58f7a62e05f8?t=3300)
  for 30 seconds to rule out a browser-only failure.
- [x] **4. Save returns you to where you started.** Built 2026-11-19
  (`10d3c123`), behind `feature_enable_return_to_jobs_list`, off until rolled
  out per shop. Jobs opened from the Jobs list carry the list's address, search
  and filters included, in a `return_to` param through the job page and edit
  form. Save lands back on that list (no toast since 2026-11-19: the list itself shows the save), and the job page's
  Jobs link keeps the search. `Dashboard::ReturnTo` checks the param and can
  serve any later origin (fix 8). Not done: scroll position, and focus in the
  search box (belongs with fix 6).
- [x] **5. Print the shop's default, without choosing.**
  Built 2026-11-19 behind `feature_enable_quick_print`, off until rolled out
  per shop. Commits `a2d65dc0`, `1b0b1347`, `85dffe2d`, `8329a6d0`,
  `22d964fa`, `e3d34f21`, `feba4d74`. Clicks to paper are 1 from every
  surface.
  - Each person picks a default copy (technician, client or both) on
    Settings, Printing, which also holds what prints after intake. The Print
    buttons switch was removed on 2026-11-20 (see fix 8).
  - Job page: a split Print button. The main half prints the default; the
    menu prints any copy once and changes the default in place.
  - Edit form: a split Save and print, the same way.
  - Jobs list: a print button on every row, plus the copies in the row menu.
  - New job form: Create is a split button that says what it does ("Create
    and print the client copy"). Choosing a copy from its menu creates the job
    with that copy and remembers it, like GitHub's merge button.
  - Print in place from a hidden frame, so the dialog opens over the page.
  - Coloured dots on the printer tell the copies apart.
  - Changed from the plan: no detail line or shortcut in the menus (names are
    clear enough; shortcuts wait for fix 6), and no Print again toast, since
    every flow lands on a page with a Print button. Toasts now follow one
    rule: none when the page already shows the result.
  - Not done: the old step-by-step intake still ends with the "When I finish,
    print" dropdown. JC Kelowna (16) switched back to that form and prints
    most after intake. Since `c5eca727` the print event records where a
    print started (O4).

### Next (2026-11-24 to 2026-12-05)

- [x] **6. A keyboard layer, the way Linear and Gmail do it.** Built
  2026-11-20 (Workbench 5b9a11c9, Uniform 76da010 and a437954).
  - Keys: `/` search, `S` status, `E` edit, `P` print, `N` new job or client,
    `Ctrl/⌘+Enter` save or add a note, `Esc` cancel, `?` the list.
  - Hints sit inside buttons and menu items, inset in the search field, and in
    a grouped `?` list (General, On this page). Touch screens hide them.
  - The status menu opens on the next status, so `S` then Enter advances a job.
  - Personal setting turns single-key shortcuts off (WCAG 2.1.4).
  - `keyboard_shortcut_used` (keys, action, page) goes to PostHog.
  - Left for later: `G` sequences for the nav, `J`/`K` through list rows.
  - **Check on 2026-12-04:** `keyboard_shortcut_used` by shop and key. That
    decides between `G` sequences, `J`/`K` and the command menu (11).
- [x] **7. An exact job number goes straight to the job.** Built 2026-11-20 as
  "record jump": `#916` or `#916-2` in the Jobs search, and `#21` in Clients,
  opens the record on Enter. The field shows a badge, red when the number
  can't exist, and the placeholder shows the shop's latest number.
  - `#` search was a long-standing customer request and shops already use it
    a lot, so the jump builds on an existing habit. A plain `916` still shows
    the exact-match table, since a bare number can also match a phone number
    or reference.
  - Since fix 8, the jump opens Quick edit in the side sheet instead of the
    job page.
- [x] **8. Edit from the Jobs list in a side panel.** Built 2026-11-20 as
  Quick edit, behind `feature_enable_quick_edit`. Workbench 4f360aaa (with
  8c4d0f31, 27c275e7, bd6aed0a, a3a9abc8, d86a4d89), Uniform bad2b1b and
  8d36bc4.
  - Clicking a row or pressing `E` opens a side sheet over the list with
    status, price, completion date, assignees, description and a team-only
    note. `O` or the ID column opens the full job page.
  - `#916` plus Enter opens the sheet instead of the job page. Watch how
    often `O` follows a jump; if it's often, send the jump back to the job
    page.
  - After saving, the cursor waits in the search with its text selected, so
    the next number can be typed straight away.
  - Save is a split button (Save only, or Save and print a copy). It
    remembers the last choice per person in `action_after_quick_edit`, also
    set on Settings, Printing.
  - Unsaved changes hold the sheet open, with Discard changes and a flash
    on the message.
  - Events: `quick_edit_opened` (source list or jump) and
    `job_item_updated` (source and changed fields), which together give time
    per update.
  - Changed from the plan: no Save and next. Shops work from a pile of paper
    tickets, so the next job is the next number typed, not the next row.
    Revisit if analytics show people working down the list.
  - Not done: custom fields in the sheet (wait for customer feedback).
  - The Print buttons setting was removed on 2026-11-20; customizable
    actions wait for customer feedback. Drop the `show_print_buttons`
    column once the `ignored_columns` change has shipped.
  - Demo: https://claude.ai/artifact/54P9fQUM9mRvNfmyxxY1Jt

### Later

- [x] **9. One quick update for status and a note.** Done 2026-11-20
  through Quick edit (fix 8): status and a team-only note save together
  in one step, and the note goes to the timeline, not the description.
  The edit form also has the Notes box since 2026-11-20.
  - Still to check after rollout: replays showing notes moving out of
    the description.
- [x] **10. Complete and print at the end of intake.** Done with fix 5 for the new job form. Folded into fix 5: the
  "Print when you finish taking in a job" setting covers JC Kelowna (16), JC
  Surrey front (10) and Russell Jewellers (9), who print almost every job they
  take in.
- [x] **11. A command menu (`Ctrl+K`).** Built 2026-11-20 as global search,
  behind `feature_enable_global_search`. Workbench 4f0c3766, Uniform b22c168.
  Refactors before it moved every search into model scopes and query objects
  (9b806fe6, 13627dc4, 070d133b).
  - A search field at the top of the sidebar (and a search button on phones),
    also on `Ctrl/⌘+K`, finds jobs by number or text, clients by name, number
    or phone, job lists by status or assignee, and pages by name or hidden
    search terms (translated).
  - → on a job shows its actions: change status (opens on the next status),
    Quick edit, print a copy, open the job page. Status change is ⌘K, the
    number, →, Enter, Enter.
  - Matches are highlighted; phone digits match through formatting.
  - Event: `search_used` (kind, level, has_query, page).
  - Not done: decide rollout per shop and compare `search_used` with
    `keyboard_shortcut_used` on the Dec 4 check.
- [ ] **12. Make the QR code useful.** Point the technician sheet's code at the
  edit form, or at a quick-update view. Make the Jobs search accept a scanned
  job link, so a desk scanner works as fast as typing the number.

## Observability: closing the blind spots

Better visibility is part of this work, not an extra. This study needed 10
AI-read replays to answer questions a well-instrumented app answers with one
query. Each item below is a blind spot we hit, what it hid, and the change that
closes it. These ship alongside the fixes above, starting with fix 4.

- [x] **O1. Most edit fields send no event.** Done 2026-11-20:
  `job_item_updated` sends `source` (edit_form, quick_edit) and the changed
  field names from both forms. Not done: the form template. Description, custom-field, client
  and assignee edits are invisible: C Creations (54) made 90 edits and only 13
  showed up. Send `job_item_edited` on save with the names of the fields that
  changed (never their values), the item's form template and where the edit
  started (job page, Jobs list, shortcut, side panel).
- [ ] **O2. Clicks can't be named.** studio-monitoring masks all autocapture
  text and attributes (`mask_all_text`, `mask_all_element_attributes`), so no
  click on the job page could be identified. Keep the masking, since it protects
  client data. Send named events for the actions that matter instead:
  `job_action_used` with `action` (edit, print, new job, add item, delete) and
  `via` (button, menu, shortcut).
- [x] **O3. Search is invisible.** Done 2026-11-20: global search sends
  `search_used` (fix 11), and the Jobs list sends `jobs_searched` with `kind`
  (jump, number, text) and `result_count`, once per changed search text. Search runs in a Turbo frame and never
  appears in pageview URLs, so we couldn't tell searching from browsing until
  the replays. Send `jobs_searched` with the kind of query (exact job number,
  text, empty) and the result count, never the query itself.
- [x] **O4. Print source unknown.** Done 2026-11-19 (`c5eca727`):
  `print_out_generated` carries `source`. `print_out_generated` records the kind of
  print-out but not when in the flow it happened. Add `source`: after intake,
  after an edit, job page or Jobs list.
- [x] **O5. Errors users see aren't tied to requests.** Mostly done by
  2026-11-20: browser and server exceptions carry `$session_id`, so each one
  opens its replay. Left: request id on server exceptions, failed Turbo fetches. We spent most of an hour
  matching a replay to logs by hand for fix 3. Report every error page render
  (500, 422) and every failed Turbo fetch as a PostHog exception with the
  request id, so a replay links straight to its request log.
- [x] **O6. Server events have no session.** Done in studio-monitoring by
  2026-11-20: every server analytics event carries `$session_id`. Request logs already carry
  `sessionId` (that's how fix 3 was traced), but analytics events from the
  server don't, so change events can't be tied to a replay without guessing
  from the last pageview. Attach the same session id to server analytics events
  in studio-monitoring.
- [ ] **O7. Dead clicks are a false signal in Uniform.** Deferred 2026-11-20:
  the O9 dashboard reads rage clicks instead, so this only matters if someone
  reads raw dead clicks again. Since 2026-11-17,
  about 1 in 14 clicks counts as dead, mostly on inputs and dropdowns that work
  fine (fix 2), so a real broken control would be lost in the noise. Stop
  treating raw dead clicks as friction: chart rage clicks per 1,000 pageviews
  per shop instead, with an alert at 3 times the previous week's median, and
  read dead clicks only on buttons and links. Check whether posthog-js can
  ignore form fields for dead clicks in studio-monitoring.
- [ ] **O8. Replays show masked text only.** Replays mask all text, so Replay
  Vision has to infer what each control is, and can invent wording (see fix 3).
  Mark safe interface text (navigation, headers, buttons, field labels, error
  dialogs) with `data-replay-unmask`. Client data stays masked.
- [x] **O9. No standing view of the loop.** Built 2026-11-20 as the PostHog
  dashboard [Job update loop](https://us.posthog.com/project/718224/dashboard/2389528):
  median time between saved updates per shop (the metric), updates, quick
  edits and prints by source, rage clicks per 1,000 pageviews per shop (in place
  of dead clicks, O7) and shortcuts by action. Add `search_used` once it ships. Every number in this report came
  from hand-written SQL. Build a PostHog dashboard for the job update loop:
  time per update, edits by source, prints by source, dead clicks per day, all
  per shop.
- [x] **O10. Logs live in PostHog, not AppSignal.** Done 2026-11-20 in
  `server/CLAUDE.md`. Workbench sends logs to
  PostHog to stay in AppSignal's free tier (`config/initializers/monitoring.rb`),
  but AppSignal shows an empty log source, which sent this study down a dead
  end. Note where logs live in the app's `CLAUDE.md` and in the
  `observability-audit` and `debug-production-error` skills, or remove the empty
  AppSignal source.
- [ ] **O12. Turbo prefetch renders job pages nobody opens.** Moving the
  pointer down the Jobs list prefetches each job link, so C Creations (54)
  triggered up to 5 full job page renders a second without opening any. Measure
  how much server time prefetch costs, and turn it off on the Jobs list rows
  (`data-turbo-prefetch="false"`) if it's a large share.
- [ ] **O11. Scanner noise fills the warning logs.** Bots probing for `.env`
  files log dozens of `request_blocked` warnings a second, which buries real
  warnings. Log blocked scanner requests at debug level, or once per address
  per hour.

Each event follows the studio `monitoring` skill: snake_case past-tense names,
no personal data, tested.

## How we'll know it worked

The metric is the median time per job update: from opening a job in the Jobs
list to being back on the list after saving, for JC Kelowna (16), C Creations
(54), Sarah Bijoux (27) and JC Surrey front (10). Measure the baseline from
2026-11-19 onward, after Edit came back, so the hidden-Edit days from 2026-11-17
to 2026-11-19 don't make later fixes look better than they are. Use at least 1
week of baseline before each flag turns on.

- Target: cut it by half within 4 weeks of fixes 4 to 8 reaching those shops.
- Stop sign: if it hasn't dropped by a quarter by 2026-12-19, stop adding
  features to this loop and go talk to JC Kelowna (16) and C Creations (54) in
  person.
- Watch alongside: rage clicks per 1,000 pageviews per shop (O7), and how
  often `E`, `P`, `/` and `Ctrl+Enter` get used.

### Assessment handoff (run on 2026-12-04)

Building is paused. The next step is to wait two weeks and compare against the
frozen baseline below. Whoever runs this (person or agent) follows these steps
and writes the result here, under "Result".

Change after the freeze (2026-11-21, not yet deployed): picking a job in global
search now opens the job page, not Quick edit. Quick edit stays one → away in the
job's actions and on the Jobs list. Expect fewer Quick edits with
`source: "search"` once this deploys; count search-to-job-page-to-edit as the same
loop, and note the deploy date when comparing.

Where things stand on 2026-11-20:

- Quick edit reached JC Surrey front (10), C Creations (54) and Fort Richmond
  (29) on 2026-11-20 (first `quick_edit_opened` at 11:50, 11:28 and 12:58
  Toronto time). JC Kelowna (16), Sarah Bijoux (27) and Russell Jewellers (9)
  don't have it, so they're the comparison group. Check `/admin/flipper` for
  any flag turned on since, and treat a shop as treated only from its first
  `quick_edit_opened`.
- Global search (`search_used`), `jobs_searched` and the `search` source on
  Quick edit go live when Workbench `main` after `4f0c3766` is pushed. Find
  the deploy time in AppSignal deploy markers before reading those events.
- Dashboard: [Job update loop](https://us.posthog.com/project/718224/dashboard/2389528).

#### Baseline (frozen 2026-11-20)

PostHog data starts on 2026-11-07, so the baseline window is 2026-11-07 to
2026-11-16. It stops before 2026-11-17, when Edit was hidden behind the ⋯ menu
for two days. Two measures, because the event data alone is thin:

- **A, save to save:** median seconds between one saved update and the next by
  the same person, from server events. Before 2026-11-20 only status, price
  and completion date changes sent an event, so description edits are missing
  and gaps run long.
- **B, start to start (hydrated from pageviews):** median seconds between one
  edit form opening and the next by the same person. It covers every edit
  through the form, description edits included, which is how these shops
  updated jobs before Quick edit.

Gaps under 5 seconds (one save sending several events) and over 10 minutes (a
break, not the queue) are dropped in both.

| Shop | A median (p25 to p75) | A gaps | B median (p25 to p75) | B gaps |
| --- | --- | --- | --- | --- |
| JC Surrey front (10) | 118 s (44 to 232) | 38 | 94 s (33 to 201) | 56 |
| JC Kelowna (16) | 51 s (29 to 134) | 77 | 44 s (27 to 104) | 90 |
| Sarah Bijoux (27) | 153 s (20 to 255) | 61 | 101 s (21 to 236) | 37 |
| Fort Richmond (29) | 37 s (20 to 96) | 54 | 69 s (47 to 152) | 20 |
| C Creations (54) | 49 s (47 to 152) | 9 | 17 s (12 to 37) | 98, one day |
| Russell Jewellers (9) | 17 s (14 to 32) | 7 | none | 0 |

Read B as the main baseline. C Creations' B comes from a single day of two
windows running at once, and its A has only 9 gaps, so treat both as weak.
Russell Jewellers changes status from the list and is too small to judge.

#### How to compare

1. Run both queries below for 2026-11-21 to 2026-12-04, per shop. For B after
   the change, an update start is an edit form opening or a
   `quick_edit_opened`, so Quick edit shops are measured the same way as
   before.
2. Judge a shop only with at least 30 gaps in both periods.
3. For each treated shop, compare its change with the comparison group's
   change over the same weeks. A drop that the comparison group also shows
   isn't Quick edit's doing.
4. Decide with the rule above: halved means it worked, less than a quarter by
   2026-12-19 means stop building and visit JC Kelowna (16) and C Creations (54).
5. Then read the supporting tiles: how many updates come through Quick edit
   against the edit form, `jobs_searched` by kind, quick edits by source,
   prints by source, and whether rage clicks per 1,000 pageviews rose past 3
   times a shop's usual week.
6. Hold the 2026-12-04 keyboard check (fix 6) at the same time: compare
   `keyboard_shortcut_used` by action with `search_used`.

Measure A (swap the dates):

```sql
SELECT shop_id, round(quantile(0.5)(gap)) AS median_seconds,
  round(quantile(0.25)(gap)) AS p25, round(quantile(0.75)(gap)) AS p75, count() AS gaps
FROM (SELECT shop_id, dateDiff('second', prev_ts, ts) AS gap FROM (
  SELECT timestamp AS ts, person_id, $group_0 AS shop_id,
    lagInFrame(timestamp) OVER (PARTITION BY person_id ORDER BY timestamp
      ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS prev_ts
  FROM events
  WHERE event IN ('job_item_updated', 'job_item_updated_status',
      'job_item_updated_price_estimate', 'job_item_updated_estimated_completion_date')
    AND $group_0 IN ('9', '10', '16', '27', '29', '54')
    AND timestamp >= toDateTime('2026-11-21 00:00:00', 'America/Toronto')
    AND timestamp < toDateTime('2026-12-05 00:00:00', 'America/Toronto')))
WHERE gap BETWEEN 5 AND 600
GROUP BY shop_id ORDER BY shop_id
```

Measure B: the same query with this event filter in place of the `event IN`
line:

```sql
(event = 'quick_edit_opened'
  OR (event = '$pageview' AND match(properties.$pathname, '^/dashboard/job_items/[0-9]+/edit$')))
```

Caveats to carry into the result: most shops are one person, server events
carry no request id, and someone running two windows (C Creations) shows up
as one queue.

#### Result

Not run yet.

## Deliberately out of scope

- The iPad intake flow and the bulk intake shop. That's a different device and a
  different loop, and has its own plan.
- A visible Print button on the job page. Print at the moment it's needed covers
  the shops that print without cluttering the page for Sarah Bijoux (27).
- Removing the status picker or the Jobs list bulk update. Sarah Bijoux (27) and
  C Creations (54) use the picker, and Russell Jewellers (9) makes every status
  change through the list.
- Any change to the intake steps besides adding a print step at the end. The
  one-page intake is still rolling out (`335cc4bf`).

## Open questions

- Why does JC Kelowna (16) write notes into the description instead of using job
  notes? Emmanuel to ask JC Kelowna (16) when Edit ships.
- The C Creations (54) replay says they change status in the edit form, but the
  events show only 2 status changes from it. The replay may be reading a custom
  dropdown as status. Check it against the recording.

## Method and caveats

- Page sequences come from pageviews in order for each person. Autocapture
  strips element ids in this project, so clicks are inferred from which pages
  people visited, not tracked directly.
- Changes are matched to the last page viewed before the change event.
  Description, custom-field and client edits send no event.
- An earlier guess that edits happen on freshly created jobs was wrong. The
  first view of a job in PostHog isn't its creation date, because these shops
  imported their history (job numbers around 63,000). Replays showed people
  search for older jobs.
- The replay findings are AI summaries. They match the event data except where
  noted. For sessions from before 2026-11-17, the summaries say "⋯ menu" because
  the prompt described the new header. Those sessions had a visible Edit button.
- Most shops are one person, so "a shop does X" usually means one person does X.

## Recordings

- [JC Kelowna (16), 2026-11-07: the queue loop, three jobs in two minutes](https://us.posthog.com/project/718224/replay/01a1b7c9-88f4-79e1-95ae-1d2413c98467?t=179)
- [JC Kelowna (16), 2026-11-07: uses the status picker, then opens Edit anyway](https://us.posthog.com/project/718224/replay/01a1b7c9-88f4-79e1-95ae-1d2413c98467?t=1710)
- [JC Kelowna (16), 2026-11-14: glances at the picker, then goes to Edit](https://us.posthog.com/project/718224/replay/01a1dbfd-ec6e-7e88-b6ba-92aacdb28f02?t=146)
- [C Creations (54), 2026-11-12: 71 edits in one session (the "error dialog" here was invented, see fix 3)](https://us.posthog.com/project/718224/replay/01a1d118-5e88-7bd8-90f5-58f7a62e05f8?t=1102)
- [C Creations (54), 2026-11-18: edit loop; the scan claimed dropdowns needed a second click, disproved in fix 2](https://us.posthog.com/project/718224/replay/01a1f0f1-3901-7973-b646-40162451e3d8?t=311)
- [C Creations (54), 2026-11-18: fast intake](https://us.posthog.com/project/718224/replay/01a1efee-2956-7ff4-88a9-1da04e5e2f2c?t=72)
