# Rebuild the data table and list pages

2026-11-20. Workbench 2.0, Jobs split view and Clients.

## Problem

The Jobs split view needed 120-character class strings to undo the data grid's
spreadsheet behaviour. The same causes show up across every list page.

1. `u-data-grid` is a spreadsheet (sticky first column, nowrap, sideways scroll,
   column menu, inline editing, phone stacking). The Jobs list is a list of
   jobs to scan. Building one on the other means overriding most features.
2. No component owns the full-screen list page. Each view repeats a
   `md:flex md:min-h-0 md:flex-col` chain, and `fill-viewport.css` reaches into
   the app shell with `:has()`.
3. Filter options are positional tuples `[value, label, icon, count]`. Status
   stage and person data ride in the icon slot, so the shared helper guesses
   with `is_a?(Hash)` and knows about job status colours.
4. List URLs are built six ways (sort path, remove filter, select job, saved
   views, `Params#to_url_params`, hidden fields). Each drops different params.
5. Cell helpers return whole `<td>`s, so other layouts can't reuse them.

Dead or duplicated: `data_table_controller.js` (unused), `navigateRow`, `sort`
and `clearSort` in the filters controller, the `tabs:` filter type, and
selection done both in `u-data-grid` and `data-table--selection`.

## Non-goals

- No change to what shops see on the classic Jobs list before the Dec 4
  assessment. The split view stays behind `feature_enable_jobs_split_view`.
- No new sorting or column features. Usage data (Nov 7 to 20): about 20 sort
  clicks in total against about 3,700 search interactions.

## Approach

### Phase 1: Workbench internals, no visible change

1. `ListState` value object: search, sort, filters, saved view, page, selected
   job. Parsed once from params. Builds every URL variant: `with(page:)`,
   `without_filter(name)`, `selecting(id)`, `cleared`. All list links use it.
2. Typed filter options: `Option = Data.define(:value, :label, :count, :group,
   :marker)`. Marker is `{kind: :status, stage:}` or `{kind: :person}` or nil.
3. Content-only cell helpers (`job_status_button`, `job_due_text`, ...). Table
   rows wrap them in `<td>`, list rows in their own markup.
4. Delete dead JS and options; one selection implementation.
5. Tests guard the classic Jobs list and Clients list behaviour.

### Phase 2: Uniform components, split Jobs view on them

1. List page layout (`u-index`): header, controls, scrolling body, footer.
   Replaces `fill-viewport.css` and the per-view flex chains.
2. List rows on `u-list` with selection: checkbox, number, title, detail line,
   status, people. Shared with the client page's job rows.
3. Filter pill and menu (`u-filter`) moved into Uniform with docs.
4. Rebuild the split Jobs view on these. Fold in today's uncommitted split work.
5. J and K move the selection to the next and previous job; the pane follows.

### Phase 3: Clients

1. Clients on the list page layout.
2. Decide whether Clients needs the data grid at all, given sort usage.

## Risks

- Phase 1 touches code the live Jobs list runs on. Mitigation: controller tests
  on URLs, filters, sort and selection before refactoring, kept green.
- `u-data-grid` users outside Workbench (Uniform docs site) keep working; the
  grid itself is not changed, only no longer used for lists.

## Open questions

- Does Clients keep sortable columns (decided yes on 2026-11-20) in the grid,
  or move to the list with a sort menu?
