# little-brother: post-decision archive pipeline

## Status: mostly decided, blocked on one hard input (see bottom).

Resolved since the last version of this doc:
- No job — `Dashboard::MeetingsController#archive` calls
  `ArchiveMeetingToKnowledgeRepoService.call(meeting)` directly and
  synchronously (already built).
- No LLM summary step — use Fathom's `default_summary` as-is
  (`meeting.summary`, already stored). The "LLM provider" dependency from
  earlier versions of this plan is dropped entirely for now.
- Commit content — not designed here; will be directed live during
  implementation.
- Auto-merge, no review gate — confirmed final.
- All services return a `Dry::Monads::Result` (house-wide rule as of this
  session) — `ArchiveMeetingToKnowledgeRepoService.call` already does this;
  `publish_to_knowledge_repo` below needs to follow the same contract once
  real, i.e. rescue `Octokit::Error` and return `Failure`, not let it raise.

## Current shape (already built)

```ruby
module ArchiveMeetingToKnowledgeRepoService
  extend Dry::Monads[:result]

  def self.call(meeting)
    return Success(meeting) if meeting.processed?

    publish_to_knowledge_repo(meeting)
    meeting.processed!
    Success(meeting)
  end

  def self.publish_to_knowledge_repo(meeting)
    raise NotImplementedError
  end
end
```

Everything below is the plan for `publish_to_knowledge_repo`'s real body.

## Dependency: octokit

`gem "octokit"` — the standard, actively maintained Ruby GitHub API client.
No strong reason to hand-roll HTTP calls against GitHub's REST API.

## Auth token

New credential, not touched by me — same handling as the Fathom webhook
secret. Proposed path (matches the `webhooks.fathom.secret` convention):

```
github:
  knowledge_repo:
    token: ghp_... (or a GitHub App installation token)
```

Set via `! bin/rails credentials:edit` when we get here. Needs write access
to the target repo (create branch/commit/PR, and merge).

## Repo target — the one blocking input

I don't know which GitHub repo is "the knowledge repo" (owner/name). Not
sensitive, so this can just live in `config/app.yml` next to `app_url` etc.,
e.g.:

```yaml
shared:
  knowledge_repo:
    owner: "itsusstudio"
    name: "???"
```

**I need this value from you before writing real code** — everything else
in this plan can be built and tested (mocked) without it, but the actual
`AppSettings.knowledge_repo.*` wiring needs the real repo.

## Publish flow (Git Data API, not the Contents API)

Using the low-level Git Data API rather than the simpler Contents API
because we need two separate commits in one push, which the Contents API
(one file write = one commit, immediately pushed) can't do cleanly — Git
Data API lets us build both commit objects first and move the branch ref
once at the end.

1. `client.ref(repo, "heads/#{default_branch}")` → base commit SHA.
2. `client.create_ref(repo, "refs/heads/archive-meeting-#{meeting.id}", base_sha)`
   — new branch off the current default branch tip.
3. **Commit 1**: build blob(s) for whatever content goes in it (TBD — your
   call live), create a new tree from the base tree + those blobs, create a
   commit object (parent: base commit), don't move the ref yet.
4. **Commit 2**: same, parent is commit 1's SHA.
5. `client.update_ref(repo, "heads/archive-meeting-#{meeting.id}", commit_2_sha)`
   — move the branch to point at the second commit. This is the only ref
   update, so the branch always looks correct even if step 3 or 4 fails
   first (nothing partially visible on GitHub).
6. `client.create_pull_request(repo, base: default_branch, head: branch_name, title:, body:)`.
7. `client.merge_pull_request(repo, pr.number, merge_method: "merge")` —
   plain merge commit, not squash, so both original commits stay visible in
   history (squashing would silently defeat "two commits").
8. `client.delete_branch(repo, branch_name)` — tidy up now that it's merged.

## Error handling

Per the house-wide Result rule: wrap the whole sequence, rescue
`Octokit::Error` (covers auth failures, rate limits, 404s, conflicts), and
return `Failure(error)` from `publish_to_knowledge_repo` — don't let it
raise past this service. `ArchiveMeetingToKnowledgeRepoService.call` needs
a small update once this is real: check the Result from
`publish_to_knowledge_repo` before calling `meeting.processed!` and
`Success(meeting)`, rather than assuming it always succeeds.

## Idempotency / retry safety

If `call` is invoked twice for the same meeting (e.g. host double-clicks
Archive before the redirect, or this becomes a retryable job later), the
existing `return Success(meeting) if meeting.processed?` guard only
protects once `processed!` has actually been set — a failure *between*
opening the PR and marking processed would leave an orphan branch/PR on
GitHub with no record of it in our DB, and a retry would create a second
one. Worth adding a `Meeting#knowledge_repo_pr_url` (string, nullable)
column: set it right after the PR is created (before merge), and check it
at the top of `publish_to_knowledge_repo` to skip re-publishing if already
set. Doubles as a useful audit trail / link from the dashboard later.

## Testing

- `publish_to_knowledge_repo`: mock the `Octokit::Client` entirely (external
  boundary) — verify the call sequence (ref, create_ref, blobs, trees,
  commits, update_ref, create_pull_request, merge_pull_request,
  delete_branch) without hitting real GitHub.
- Error path: `Octokit::Error` raised by the mocked client → service returns
  `Failure`, `meeting.processed?` stays false.
- Idempotency: calling `.call` twice doesn't create a second PR (once
  `knowledge_repo_pr_url` is set, or once `processed?`).
- No system test — backend orchestration, not a browser flow.

## Open items

1. **Repo owner/name** — blocking, see above.
2. **Commit content** — you'll direct this live during implementation, not
   answering it here per your instruction.
3. **Naming** — `ArchiveMeetingToKnowledgeRepoService` stands unless you'd
   rather rename it now that its shape is settled.
