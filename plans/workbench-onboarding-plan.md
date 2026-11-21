# Workbench: sign-up, onboarding and activation

Date: 2026-11-17. Replaces the current sign-up form, onboarding checklist modal
and `Onboarding::Progress` steps.

## Why

Today sign-up asks for the shop name, time zone, owner name and email address in
one form, then drops people into an empty dashboard with a three-step checklist
modal. We learn almost nothing about who signed up, the app is configured the
same way for a one-person repair counter and a Frank Darling-style house, and
nothing guides people to the moments where Workbench proves itself.

## Principles

- Sign-up is the same in every studio app and asks only what an account needs.
  Everything else is the app's own concern, asked in the app, after sign-up.
- Every question we ask changes something: what Workbench sets up, what it shows
  first, or what we learn. No question is asked for its own sake.
- One question per screen, skippable, with a sensible default.
- No modals that open by themselves, no tours, no confetti. Calm Uniform screens,
  with a few poster moments in the Swiss and Norma spirit.

## 1. Sign-up (studio-auth, shared by every app)

- Form: email address and name. Nothing else.
- Verify with the six-digit code studio-auth already sends, then create the user
  and sign them in.
- studio-auth calls one app hook after the account exists (for example
  `after_sign_up(user)`), and the app decides where to send them. Workbench
  creates the studio record there and redirects to onboarding.
- Workbench's `Public::SignupsController` and its shop fields go away. Time zone
  is still detected from the browser and kept for the onboarding step.

## 2. Onboarding questions (Workbench, in the app)

Asked once, right after sign-up, as a short sequence of full-page Uniform
screens. Each answer is saved as it is given, so leaving halfway loses nothing.

| Question | Answers | What it configures | What we learn |
|---|---|---|---|
| Your studio | Name, country (time zone, currency and language follow) | Studio record, documents, texts, portal | Market |
| What you do | Repairs, custom and commissions, retail, appraisals (pick any) | Starter statuses, job form fields (ring size, metal, stone), Home emphasis | Segment |
| Who works with you | Just me, 2 to 5, 6 or more | Team invite step, technician view, team load card | Size |
| How you keep track today | Paper, spreadsheets, another app (which one) | Shows the import step and the done-for-you import offer | Switching source |

Answers live on the studio (`onboarding_answers` jsonb or plain columns, decided
in the build) and go to PostHog as group properties.

## 3. Get started (from the prototype)

Prototype: https://claude.ai/artifact/ARwZPLGupK3D6xi9NgH4Zq#start

- The landing page after onboarding questions: poster ("Your studio's workflows,
  reimagined.") with the cobalt halftone, then the setup checklist (Uniform
  `u-checklist`).
- Steps depend on the answers above. Base set: add your first job, bring your
  clients over, turn on collection texts, invite your team (only if not just me),
  add your studio details.
- Sidebar item "Get started" with a count (2/5) at the top until setup is done or
  hidden.
- Home shows a compact "Continue setting up" card with the next step only.
- "Hide setup" on the page. When every step is done, a short "You're all set"
  poster replaces the checklist and the nav item retires.
- Owner and managers only; staff never see it.

## 4. Moments of value

The order a new studio should meet them, each with the step that leads to it:

1. First job added, and the intake ticket prints or emails with the studio's
   name on it. Target: within five minutes of sign-up.
2. The client receives their first update text or email, and opens their
   portal.
3. A job marked ready sends the collection text without anyone writing it.
4. Home fills in: what's late, what's ready, who has what.

## 5. Activation and measurement

- Activated (proposal): at least three jobs added and at least one client
  update sent within seven days of sign-up.
- PostHog events: `sign_up_started`, `sign_up_completed`,
  `onboarding_question_answered` (question, answer), `onboarding_completed`,
  `setup_step_completed` (step), `setup_hidden`, `first_job_added`,
  `first_client_update_sent`, `activated`.
- One funnel from sign-up to activated, split by segment and switching source.

## Build order

1. studio-auth: shared email and name sign-up with the after-sign-up hook.
2. Workbench: move studio creation to the hook; onboarding question screens.
3. Answers configure starter statuses, job form and Get started steps.
4. Get started page, nav item and Home card; retire the checklist modal and
   `Onboarding::Progress`.
5. PostHog events and the activation funnel.
6. Client import (self-serve spreadsheet upload), plus the done-for-you offer.

## Open questions

- Ask for the name at sign-up, or only the email address with the name as the
  first onboarding screen? Email only is the fastest form; the name is needed
  before anyone else sees the account.
- Can we promise a free done-for-you import, and how fast?

## Vocabulary

- The app keeps "job" for the core object: most studios use Workbench for
  repairs, and a house's aftercare (resizing, polishing, repairs) is jobs too.
- "Client" replaces "customer" across the app (done, 52eaa258).
- The brand register comes from headlines, client wording and visual polish,
  not from renaming jobs.

## Later: commissions as their own concept

Custom work is a different shape from a job, so it becomes its own concept
rather than a job with extra fields. Not built now; nothing in this plan should
block it.

| | Job | Commission |
|---|---|---|
| What | Repair, resize, cleaning, appraisal | Custom ring, bespoke piece |
| Length | Days | Weeks to months |
| Shape | One item moving through statuses | Phases: consultation, design or CAD, client approval, deposit, making, setting, final fitting |
| Money | One estimate, paid at collection | Quote, deposit, staged payments |
| Client experience | "It's ready" updates | Renders to approve, milestones, appointments |
| Volume | High | Low, high value |

- Name: "Commissions", the jeweller's own word, not "Projects".
- Shares clients, the portal, notifications, the timeline and stages with jobs;
  a commission can spawn jobs (casting sent to the setter).
- Its phases would be a second pipeline beside the job stages.
- Demand signal now: studios that pick "custom and commissions" in the "What
  you do" onboarding question are the list to talk to before designing it.
