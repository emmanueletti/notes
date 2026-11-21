# Landing SarahBijoux

Goal: get SarahBijoux using Workbench for custom pieces, not only repairs. Last
updated 2026-11-21.

## Why they matter

- Our way into Quebec. Montréal studio (5260 Boulevard Saint-Laurent).
- Impressive name: everyone we tell they're on Workbench says "wow". Keeping
  them, and getting them deeper in, is worth more than one shop's subscription.
- Tenant 27 in PostHog. Active 14 of 15 days, 2026-11-07 to 2026-11-21.

## People

- Sarah: owner and designer. Runs custom pieces. Barely uses Workbench, because
  she doesn't handle repairs.
- Florence Gauthier Charest: manager. Runs the repair counter on Workbench.
- Our side: Mackenzie (demoed custom projects v1), Emmanuel (developer, followed
  up).

## Email thread, 2026-07-13 to 2026-07-23

1. 2026-07-13, Mackenzie demoed custom projects v1.
2. 2026-07-14, Sarah turned it down:
   - "We've created a system that is much less formal and polished, but perhaps
     better adapted to the approach we wish to take with our customers. Making
     this type of project requires a certain proximity and direct involvement
     with our clients. Going through a system like workbench to send renderings
     and estimates makes the whole experience impersonal."
   - Missing: ring size; metal choice (colour and karat); more than one project
     per client ("we often do more than one ring"); more than one estimate per
     project ("sometimes we'll quote two different carats or literally two
     different projects").
   - "For now we won't be using this particular feature, but we'll keep in mind
     that possibility if at a certain point if feels like the best way to work."
3. 2026-07-14, Florence agreed: "with our current workflow and our very personal
   approach with clients, we would probably continue using our existing system
   for the moment. That being said, as custom projects continue to take a bigger
   place in the business, I think this is a great tool to keep in mind for the
   future."
4. 2026-07-15, Emmanuel admitted v1 automated too much of the client contact and
   asked about their current system, pains and missing features.
5. 2026-07-15, Sarah:
   - Current system: "Good old binder where all project have a written/drawn
     file (ones from meeting with clients, email exchanges with the client,
     Google drive to store all computer files for the project (sketches to the
     designer, renderings, STL), share google word sheet shared within our team
     with project steps once the ring is sent to casting)"
   - Pain: "The time it takes to store files in the drive, I like to work fast."
6. 2026-07-23, Florence on repairs: "Workbench is working very well for us, and
   we really appreciate being able to keep a history of our repairs now. It has
   made the process much easier to follow and more organized. The platform is
   also very user-friendly, and the training was very easy to understand and
   implement."

## What it means

- Repairs got them in the door. A custom-first brand adopted Workbench for its
  repair counter.
- Their "no" is the spec: custom projects stay internal. The jeweller talks to
  the client. Workbench never sends renderings or estimates.
- The pain is filing, not project management. Replace Drive with a project page
  that takes sketches, renderings and STL files in one step. Replace the shared
  sheet with a list of post-casting steps.
- Data to hold: ring size, metal colour and karat, several projects per client,
  several estimates per project.
- Sarah is the one to win, not Florence. Florence chose the repair tool. Sarah
  chooses the custom tool, and she cares about speed above all.

## Speed is the product

To win Sarah, Workbench needs the obsession with speed that Linear and Ramp
have: every action lands on screen the moment she makes it, with no waiting on
the server.

Decided 2026-11-21: performance-tuned Hotwire with hand-built optimistic
updates. Vue only if a page, measured under Hotwire, still misses the speed
target.

### How it works under Hotwire

Rails and Turbo have no built-in optimistic updates, so we build them by hand:

1. Stimulus changes the screen on click or drop (adds the thumbnail, moves the
   status).
2. Stimulus posts to Rails in the background (`fetch` or a Turbo form submit).
3. Rails answers with a Turbo Stream or `broadcasts_refreshes`. Turbo morphing
   swaps in the real HTML without a flash, keeping scroll and focus.
4. The same broadcast goes over Action Cable to every open view of the page.

Campfire (37signals) shows messages this way, from memory. Check its source
before relying on it.

Built by hand under Hotwire, easier with a Vue client-side store: rollback when
the server rejects a change, a queue that survives fast repeated edits or a
dropped connection, and several pending changes on one page staying consistent.

For file capture, the slow part is the upload, not rendering. Active Storage
direct uploads plus a thumbnail drawn from the local file on drop feels instant,
and Stimulus handles it.

### Fallback to Vue

If a page misses the speed target under Hotwire, embed a Vue component on that
page only: optimistic updates from a client-side store, queued sync to the
backend with retries, and Action Cable pushing each change to every open view.
Likely candidates are pages with many rapid edits, like a board or a dense list.
Vue is a second front end and departs from studio conventions, so each page
that uses it needs a measurement showing Hotwire fell short.

## Open

- The speed target that triggers Vue, set before building. For example, drop to
  thumbnail under 100 ms. Owner: Emmanuel.
- First page to build: custom project file capture, since it's Sarah's stated
  pain. Owner: founders.
- Evidence is one studio. Ask 4 more independent studios how they track a custom
  piece today and what takes the most time, before building beyond what Sarah
  needs. Owner: founders.
- When to show Sarah again, and what to show her. Owner: Mackenzie.

## References

Email thread, verbatim. Greetings, sign-offs and signatures removed. Sarah's
2026-07-15 answers were written inline under Emmanuel's questions.

**2026-07-13, Mackenzie to Florence** (only the opening was saved)

> I'm reaching out to let you know about a big new feature we are launching:
> custom projects

**2026-07-14, Sarah**

> Thank you for this demo ! Very cool to see BENCHWORK growing and as always,
> everything is very well thought !
>
> We've created a system that is much less formal and polished, but perhaps
> better adapted to the approach we wish to take with our customers. Making this
> type of project requires a certain proximity and direct involvement with our
> clients. Going through a system like workbench to send renderings and
> estimates makes the whole experience impersonal.
>
> Technically here are some things that could be added:
>
> - Size
> - Metal choice (colour/carat)
> - Option to add more than one project, we often do more than one ring.
> - Option to add different estimates (sometimes we'll quote two different
>   carats or literally two different projects).
>
> For now we won't be using this particular feature, but we'll keep in mind that
> possibility if at a certain point if feels like the best way to work !

**2026-07-14, Florence**

> Thank you for the demo! I think the platform is looking really complete, and I
> don't have any additional suggestions to add for now - Sarah mentioned
> everything.
>
> I do agree that, with our current workflow and our very personal approach with
> clients, we would probably continue using our existing system for the moment.
> That being said, as custom projects continue to take a bigger place in the
> business, I think this is a great tool to keep in mind for the future.
>
> I'm really happy to see how quickly you're developing and improving the
> platform !

**2026-07-14, Mackenzie**

> Your feedback regarding the need for more flexibility with metal choices,
> sizing, and the ability to manage multiple projects and estimates is
> incredibly helpful.
>
> We really appreciate your perspective on keeping that personal connection with
> your customers. It's great to know where we can improve to make this feel less
> like a rigid system and more like a tool that supports your unique approach.
> I'll definitely share these points with the rest of the team as we continue to
> develop this feature.

**2026-07-15, Emmanuel**

> I wanted to reach out to see if we could learn a bit more about your current
> workflow and the system you use. I agree that the V1 customs workflow doesn't
> feel personal, and we'll make changes right away based on your feedback.
>
> The idea behind the customs workflow was to build a tool that could help with
> the behind-the-scenes organization. But our mistake was trying to automate too
> much of the customer interaction, which is the magical part of making a custom
> piece from an independent jeweller.

**2026-07-15, Sarah** (answers inline)

> Q: what tool / system do you currently use for organizing custom projects? A:
> Good old binder where all project have a written/drawn file (ones from meeting
> with clients, email exchanges with the client, Google drive to store all
> computer files for the project (sketches to the designer, renderings, STL),
> share google word sheet shared within our team with project steps once the
> ring is sent to casting)
>
> Q: is there anything you do not like about your current process, or that you
> wish could be made easier? A: The time it takes to store files in the drive, I
> like to work fast.
>
> Q: in general, is there anything about Workbench you think could be made
> better or a missing feature that could help make your studio run even
> smoother? A: I'll let Florence answer that one because I do not use Workbench
> a lot since I'm not the one dealing with repairs !

**2026-07-23, Florence**

> I don't have much more to add. Workbench is working very well for us, and we
> really appreciate being able to keep a history of our repairs now. It has made
> the process much easier to follow and more organized.
>
> The platform is also very user-friendly, and the training was very easy to
> understand and implement.
