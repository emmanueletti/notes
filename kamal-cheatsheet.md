# Kamal cheatsheet (incident/CI-CD lens)

### First deploy vs every deploy after

`bin/kamal setup` — one-time. Installs kamal-proxy, boots accessories, registers the docker network. Idempotent (safe to rerun if something's broken), but not the normal day-to-day command.

`bin/kamal deploy` — every deploy after that. Builds/pushes image, runs release (migrations), swaps containers zero-downtime.

Never assume `setup` when `deploy` is what's needed mid-incident — `setup` re-provisions infra, `deploy` just ships code.


### Deploy is stuck / hanging

Kamal serializes deploys with a lock. If a previous deploy died mid-way (Ctrl-C, network drop, crashed CI runner), the lock can be left held:

`bin/kamal lock status` — see if it's held, by whom, since when

`bin/kamal lock release` — force-release it (only if you're sure nothing else is actually deploying — releasing a lock held by a real in-flight deploy on someone else's machine causes a race)

Then retry the deploy.


### Deploy fails at "target failed to become healthy"

Means the new container never returned a 200 on its health check path before kamal-proxy gave up (30s default). Check what actually happened:

`bin/kamal app logs` — tail the new container's boot logs, look for the real error (migration failure, missing env var, crash on boot)

`bin/kamal app details` — shows what's currently running (image tag/SHA, status, ports) vs what you expect

If the app boots fine but health check still fails, suspect the health check path itself, or that `assume_ssl`/`force_ssl` is redirecting the health check into a loop (redirect ≠ 200, proxy marks it unhealthy). Check for a stray 301 on `/up`.


### Something changed in git but the deploy doesn't reflect it

Kamal tags images by git commit SHA and builds from **committed content only** — uncommitted changes never make it into the image, even though Kamal's own config (`deploy.yml`, `.kamal/secrets`, hooks) is read straight off your local disk. If a fix "isn't taking," check `git status` before anything else:

`git log --oneline -1` — confirm your fix is actually the tip commit, not sitting uncommitted

A dirty working tree with an already-built/pushed image under that SHA means Kamal happily reuses the *stale* image on the next deploy — commit first, then redeploy, to force a genuinely fresh build.


### Rollback

`bin/kamal app containers` — lists every container still on the host per version tag (full git SHA), with status (`Up`/`Exited`). Old ones stick around after a deploy rather than getting deleted immediately, so recent history is usually still there to roll back to without needing `git log` at all.

`bin/kamal rollback <version>` — swap back to a previously-deployed image tag (the full SHA from the list above), zero-downtime, without rebuilding

Fast, since it's just repointing kamal-proxy at an image that's already built and pushed — no build step. If the target version's container was already stopped/pruned, Kamal rebuilds it from the still-tagged image rather than failing outright.


### Maintenance mode

For when you need to take the app offline on purpose — a risky migration, an upstream outage you can't route around, buying time mid-incident — rather than it just falling over uncontrolled:

`bin/kamal app maintenance` — kamal-proxy serves a maintenance page to all traffic instead of routing to the app. Options: `--message="..."` to customize what visitors see, `--drain-timeout=N` to control how long in-flight requests get to finish first.

`bin/kamal app start` — end maintenance mode, resume normal routing.

Different from `bin/kamal app stop` (kills the container outright, `bin/kamal app start` brings it back) — maintenance mode keeps the container running but fronts it with a proxy-served page, so it's the gentler option and what you want for "we know about this, hang tight" rather than "something crashed."


### Proxy (kamal-proxy) itself is the problem

Distinguish "my app is broken" from "the proxy in front of my app is broken" — the proxy is a separate container, shared across every app on the box if you're multi-tenant on one server.

`bin/kamal proxy logs` — TLS handshake errors, cert issuance failures, routing state live here, separate from app logs

`bin/kamal proxy details` — is it even running

`bin/kamal proxy reboot` — stop + recreate the proxy container fresh. Clears wedged internal state (e.g. an ACME/cert-issuance flow stuck retrying). Reasonable first move if the app itself looks healthy but nothing serves.

`bin/kamal proxy restart` — gentler restart of the existing container, without recreating it. Try this before `reboot` if you just want to bounce it.


### TLS cert not issuing / site hangs on HTTPS but HTTP works

kamal-proxy uses Let's Encrypt automatically when `proxy.ssl: true`. Cert issuance needs Let's Encrypt's own validator to reach port 80 on your box from the public internet — this has more failure points than it looks:

- DNS actually pointing at the right IP (`dig +short <domain>`)
- Host firewall (`ufw`/`iptables`) allowing 80 and 443 inbound from Anywhere, not just your own IP/VPN
- **Cloud-level firewall, separate from the host's own firewall** (DigitalOcean Cloud Firewalls, AWS Security Groups, etc.) — this one's easy to miss because it's dashboard-only, invisible from SSH, and self-to-self curl tests from the box never exercise it. A cloud firewall with an empty inbound rule set is **default-deny**, not default-allow — silently drops every genuinely external connection while `ufw`-level SSH keeps working fine (stateful reply traffic on a connection you initiated outbound still gets through even with zero inbound rules)
- Let's Encrypt rate limits (5 failed validations/hour per account+hostname) — repeated failed attempts while debugging can trigger this, making retries hang/silently fail even after you've fixed the actual cause; back off ~30-60min rather than hammering retries

Check what's actually cached: `docker exec <proxy-container> cat /home/kamal-proxy/.config/kamal-proxy/certs/*/<domain>` — presence of a real `-----BEGIN CERTIFICATE-----` block means issuance succeeded even if you're still seeing stale symptoms elsewhere (browser cache, an old hung connection).


### Get into a running container / accessory

`bin/kamal app exec --interactive --reuse "bin/rails console"` (or whatever your alias is) — shell into the live app container

`bin/kamal accessory exec db --interactive "psql -U <user> -d <database>"` — **spins up a fresh throwaway container**, not a shell in the running one. No access to the running accessory's local socket — pass `-h <accessory-container-name>` to psql (or whatever CLI) to force TCP to the real container over the docker network.

To actually get inside the *running* accessory: SSH to the host directly and `docker exec -it <container-name> <command>`.


### Secrets not resolving during deploy

`.kamal/secrets` runs as a shell script locally (on your machine or CI), before anything touches the server — errors here are pure local shell/tool issues, not server-side:

- 1Password adapter: `op signin` first, and the `--account` flag is required explicitly (no silent fallback to your one signed-in account)
- Missing env var referenced in the script: check it's actually exported in your current shell (`.env` files aren't auto-loaded unless Kamal's dotenv support is active)


### Quick incident triage order

1. `bin/kamal app details` — is anything even running, what version
2. `bin/kamal app logs` — what's the app itself saying
3. `bin/kamal proxy logs` — is traffic even reaching the app, or dying at the edge
4. `git log --oneline -1` + confirm it matches what's deployed — ruling out a stale-build issue
5. `bin/kamal lock status` — ruling out a stuck deploy blocking your fix from going out
6. If it's a fresh domain/TLS issue: DNS → host firewall → **cloud firewall** → cert cache, in that order — most incidents claiming to be "Kamal is broken" turn out to be one of these four, not Kamal itself


### Discovering commands you don't have memorized

`bin/kamal help` — top-level command tree

`bin/kamal <command> help` — subcommands for that tree (e.g. `bin/kamal proxy help`, `bin/kamal accessory help`)

Faster and always version-accurate vs. searching docs, which can lag your installed Kamal version.
