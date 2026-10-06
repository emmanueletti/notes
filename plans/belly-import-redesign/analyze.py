import json, sys

cases = json.load(open(sys.argv[1]))

def pct(hit, total):
    return f"{hit}/{total} ({100 * hit / total:.0f}%)" if total else "n/a"

obs = {"has_ingredients": [0, 0], "has_steps": [0, 0], "points_elsewhere": [0, 0]}
outcome_new = [0, 0]
outcome_old = [0, 0]
invented = []
errors = 0
rows = []

for c in cases:
    want = c["new_expect"]
    want_ingredients = want in ("success", "INGREDIENTS_WITHOUT_METHOD")
    want_steps = want in ("success", "STEPS_WITHOUT_INGREDIENTS")
    judge_elsewhere = not want_ingredients and c["kind"] in ("caption", "video_caption") and want != "FOLLOW_LINK" and want != "STEPS_WITHOUT_INGREDIENTS"
    want_elsewhere = want == "RECIPE_GATED"
    new_hits = 0
    misses = {}
    for r in c["results"]["new"]:
        if "error" in r:
            errors += 1
            continue
        obs["has_ingredients"][1] += 1
        obs["has_ingredients"][0] += r["ingredients"] == want_ingredients
        obs["has_steps"][1] += 1
        obs["has_steps"][0] += r["steps"] == want_steps
        if judge_elsewhere:
            obs["points_elsewhere"][1] += 1
            obs["points_elsewhere"][0] += r["points_elsewhere"] == want_elsewhere
        if not want_ingredients and r["ingredients"]:
            invented.append((c["name"], r["ingredient_count"]))
        outcome_new[1] += 1
        if r["outcome"] == want:
            outcome_new[0] += 1
            new_hits += 1
        else:
            misses[r["outcome"]] = misses.get(r["outcome"], 0) + 1
    old_hits = None
    if c.get("old_expect"):
        old = c["results"]["old"]
        old_hits = sum(o == c["old_expect"] for o in old)
        outcome_old[0] += old_hits
        outcome_old[1] += len(old)
    rows.append((c["name"], want, new_hits, len(c["results"]["new"]), old_hits, len(c["results"]["old"]), misses))

print("OUTCOME ACCURACY")
print(f"  proposed design : {pct(*outcome_new)}")
print(f"  current prod    : {pct(*outcome_old)}  (against today's expected codes)")
print("\nPER OBSERVATION (proposed design)")
for name, (hit, total) in obs.items():
    print(f"  {name:17}: {pct(hit, total)}")
print(f"\nINVENTED INGREDIENTS (ingredients extracted where none expected): {len(invented)}")
for name, count in invented:
    print(f"  {name}: {count} ingredients")
print(f"\nAPI errors: {errors}")
print("\nPER CASE (proposed hits / runs, current hits / runs, proposed misses)")
for name, want, nh, nt, oh, ot, misses in rows:
    flag = "" if nh == nt else "  <--"
    old = f"{oh}/{ot}" if oh is not None else "  - "
    print(f"  {name[:44]:44} want {want:27} new {nh}/{nt}  old {old}  {misses if misses else ''}{flag}")
