# Customer messages: research

Date: 2026-11-17. This covers how teams with a strong engineering culture build "send something to a customer", and what that means for Workbench.

## What today's code does

There are four ways to send, and each works differently:

- Status update: a template from the database or YAML, filled in with placeholders, saved as a CustomerNotification, then sent by one job per channel.
- Intake summary: a mailer view saved as HTML, then built again at send time.
- Sign-in link: sent straight from the mailer, with no record.
- Email confirmation: its own job, logged as a consent event.

There are also three preview UIs, and an email job that switches on the message type twice.

## What the references show

### 37signals (Fizzy, "Vanilla Rails is plenty")

- One record per notice: `Notification` belongs to the recipient, the creator and a polymorphic source.
- One small class per source type, picked by naming convention (`Notifier.for(source)` finds `Notifier::<Source>EventNotifier`). There's no registry and no config.
- Delivery lives on the record. A concern handles push, a callback hands off to email bundling, and Turbo broadcasts update the UI.
- Logic sits in rich models, not service objects. The controller does the orchestrating.

### Active Delivery (Evil Martians)

- The problem it solves is ours: one action sends email, SMS or push, each behind its own conditional, spread across the codebase.
- The idea: the caller says what happened, and one delivery class decides the channels and checks preferences in one place.
- The cost: an extra layer, with behaviour hidden behind conventions and callbacks. The idea is worth taking. With 4 kinds and 2 channels, the gem isn't.

### Noticed gem

- Per-channel delivery methods, each with an `if:` for preferences. That suits apps with many notification types and channels. We have 4 and 2.

### Shopify and Jobber

- One settings page lists every message the business sends to its customers.
- Each message ships with a default. The business edits a copy and can revert to the default.
- Jobber puts the email and text versions of one message in tabs in the same editor. Where a message can't go by text, only the email tab shows.
- Variables are listed per message, because not every variable works in every message.
- The preview shows the message with real-looking values filled in.
- Jobber lets the business pick who receives replies for each kind of email.

### Transactional vs marketing (Courier, Fyno)

- Required messages (a sign-in link, a receipt) and optional updates follow different consent rules. Whether consent is needed is a fact about the kind of message, not an `if` in a job.

## What this means for Workbench

Take these:

- One record for every message a client receives. It's the outbox, the client's history and the delivery status. A job sends what the record says and never builds the message again.
- One small class per kind, found by name: StatusUpdate, IntakeSummary, SignInLink, EmailConfirmation. Each says which channels it can use, whether it's required or needs consent, which variables it offers, and how it's written.
- Mailers stay the email layer. The kind class hands its subject and text to one mailer, and a sign-in link sends a fixed mail.
- Defaults ship with the app. The shop edits a copy and can revert, the way Shopify works.
- A sign-in link is never stored with a working token in it.

Leave these out:

- No gem (Noticed, Active Delivery). The problem is too small for one.
- No registry, plugin system or workflow engine. Find classes by name, and use a `case` on the channel when there are only two.
- No Liquid. `{{ customer.full_name }}` placeholders, checked against the variables the kind offers, are enough.
- No separate service layer. Behaviour lives on the record and the kind classes, and controllers do the orchestrating.

Rough shape, to argue with:

```ruby
CustomerMessage::StatusUpdate.new(job_item).deliver_later(via: :email, sent_by: current_user)
```

Behind that call: build the subject and text, save a CustomerMessage, and enqueue `CustomerMessage::EmailJob` or `SmsJob`. That's one model, four kind classes, one mailer and two jobs.

## Questions for prototyping

- Send dialog: when the client accepts both, are email and text two tabs, one choice or two checkboxes? How does the dialog read when the client accepts neither?
- Should the dialog let staff edit this one message before sending, or only send the template?
- Settings: one "Messages" page listing every kind with its channels, Shopify-style, versus today's editor with a picker.
- Client history: where does "what we've sent this client" live, on the client page, the job, or both?

## Sources

- https://github.com/basecamp/fizzy (app/models/notifier.rb, app/models/notification.rb)
- https://dev.37signals.com/vanilla-rails-is-plenty/
- https://evilmartians.com/chronicles/crafting-user-notifications-in-rails-with-active-delivery
- https://github.com/excid3/noticed
- https://help.shopify.com/en/manual/orders/notifications/edit-template
- https://help.getjobber.com/hc/en-us/sections/360000010147-Automated-texts-emails
- https://help.getjobber.com/en/articles/variables/
- https://www.courier.com/blog/transactional-product-and-marketing-notifications-what-are-the-differences
