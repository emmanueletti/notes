# Metro fare system

Reported on Blind by a Shopify candidate. The problem got progressively harder, one fare rule at a time. Nothing here is hard alone. The test is whether the fifth rule still lands in one place.

## Prompt

Build the fare system for a metro. Riders have a card. They tap in at one station and tap out at another.

- `tap_in(card, station)`
- `tap_out(card, station)`: charges the fare and returns the trip.

Start simple: every trip costs a flat $2.50. Store money as integer cents.

## Follow-ups they add

1. Zones. Each station is in a zone. The fare is a base price plus a charge for each zone crossed.
2. Peak and off-peak. Trips that start in rush hour cost more. Ask: is peak decided at tap-in or tap-out? Are weekends ever peak?
3. A daily cap. Once a rider has spent $10 in a day, the rest of the day is free. A trip that crosses the cap is charged only up to it.
4. Transfers. If you tap in within 30 minutes of your last tap-out, the trip is free. Ask how many free transfers in a row are allowed.
5. Card balance and top-ups. A card needs a minimum balance to tap in.
6. Concessions. Seniors and students get a percentage off. Ask whether the cap is discounted too.

## Core idea

A fare is a short pipeline: zone fare, then peak, then concession, then transfer, then cap. Each rule is one step. The order matters, so say it out loud and get the interviewer to agree.

Inject a clock from the start. Peak, transfers, and the daily cap all depend on time. With a fake clock, a test can say "it's 8:00 on a Wednesday" and move time forward without sleeping.

## Design that takes the follow-ups

- `Station`: name and zone. A value object.
- `FareTable`: base, per-zone charge, peak surcharge, peak windows. `fare(origin, destination, at)`. Zone and peak changes go here.
- `Concession`: a name and percent off. `apply(cents)`. Adults are 0% off, so there's no special case.
- `Card`: id, concession, balance, trip history. `top_up`, `record(trip)`, `spent_on(day)`.
- `Trip`: origin, destination, times, fare charged, and whether it was a transfer. Keep it, because the cap and transfer rules read history.
- `FareSystem`: stations, fare table, cap, transfer window, clock. Holds open taps. Runs the pipeline at tap-out.

## Senior talking points

- Money is integer cents. Round once, in one place (`Concession#apply`), and say which rounding you use.
- Charge at tap-out, because you don't know the fare before. So tap-in checks a minimum balance, and the balance can briefly go below zero. Ask if that's OK.
- A transfer rule without a limit lets people ride all day on short hops. Allow one free transfer per paid trip.
- The "day" for the cap is a service day. Real metros end it around 4 a.m., not midnight. Name it, even if you use the calendar date for now.
- Missing tap-outs are the classic real-world problem. Usually the rider is charged the maximum fare. Mention it before they ask.
- Keep `FareSystem` thin. If rules keep coming, turn the pipeline into a list of rule objects that each take and return a fare.

## Test cases to name before the AI does

- Same zone, off-peak: base fare, and the balance goes down
- Crossing two zones
- Peak at 8:00 on a weekday, not peak at 8:00 on a Saturday
- The cap: 400, 400, then 200, then 0
- The cap resets the next day
- A transfer inside the window is free, but a second one in a row is charged
- A trip just after the window is charged
- A low balance blocks tap-in, and a top-up fixes it
- Concession: half fare and half cap
- Tap-out without tap-in, and tapping in twice
