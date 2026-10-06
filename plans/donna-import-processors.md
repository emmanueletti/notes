# Donna: import processors

Goal: the Import CSV page lets you pick a processor, and the CSV is built to
target that processor. The user must pick one explicitly.

## Decisions

- Processors live in code, one class each, in a small registry.
- No per-workspace restriction and no generic processor: every workspace lists
  every processor and the user must pick one. An upload without a valid
  processor is rejected (422). No schema change.
- No new lead fields yet. If Belly needs something Lead can't hold, add a
  `data` jsonb column later.
- Template CSV download and a "Copy instructions for Claude" block per
  processor, so the sales skills build the CSV from donna's spec.

## Processors

`workbench_leads`: category limited to jewelry, watch, both (default jewelry).
`belly_leads`: category free text, size defaults to solo.
Both dedupe on name + city (a blank city counts as blank) and accept the legacy
headers 

## Code

- `app/importers/lead_importer.rb`: base class and registry
  (`LeadImporter.all`, `LeadImporter.find(key)`, `LeadImporter.for(workspace, key)`). A
  processor declares its columns (name, required, description, allowed values)
  and overrides `duplicate?` and attribute defaults where needed.
- `app/importers/lead_importer/{workbench_leads,belly_leads}.rb`.
- Parsing moves out of `LeadsController` (`process_csv`, `build_lead_attributes`,
  `normalize_*`, `parse_*`) into the base class. The controller only picks the
  processor, calls it, and renders the result.
- Header preflight: a missing required column fails the whole upload up front;
  unknown columns are listed as ignored.
- `GET /dashboard/leads/import_template?processor=key` returns a template CSV.
- Import page: processor links, then the columns table, template download, copy-instructions block, upload form carrying the
  processor key.

## Tests

- One test file per processor covering its defaults, validation and dedupe.
- Registry: an unknown key returns nil, and posting one to import is rejected.
- Header preflight, ignored columns, template CSV, copy-instructions text.
- Existing import tests pass an explicit processor.

## Rollout

1. Registry and processors, existing tests green. Done.
2. Page UI, template and instructions. Done.
3. Update the jean-claude sales skills to take a processor key.
