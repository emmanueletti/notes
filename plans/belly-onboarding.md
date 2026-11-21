# Belly onboarding: rollout checklist

Status: built (Flow A, Flow B nudges, empty states, "Add to playlist"). Only rollout is left. Shrunk from the full plan on 2026-10-28; delete this file once every box is ticked.

## Nudges (Flow B)

- [ ] Push the unpushed commits (c295642 through 6fba0d5). 41c7650 adds the `dismissable_elements` table, so that deploy is a schema change.
- [ ] Ship iOS and Android releases with the `tab` bridge component.
- [ ] Once those builds are approved and live, turn on `feature_enable_onboarding_nudges`. Not before: older builds push Plan and Groceries onto whichever tab the user is on.

## First-run onboarding (Flow A)

- [ ] Roll `feature_enable_first_run_onboarding` out to everyone.
- [ ] Then delete the old welcome email (`OnboardingMailer.welcome`, skipped today for flagged users in `User#activate!`).

## Open

- [ ] Confirm Leanne Brown's credit wording for the Good and Cheap starters, if her permission specifies one.

## Later, only if wanted

- Tab bridge: carry a URL so a recipe tapped on Plan opens in the Recipes tab (TODO in `app/javascript/controllers/bridge/tab_controller.js`).
- A `viewed` event for nudges, for a seen-vs-tapped funnel.
