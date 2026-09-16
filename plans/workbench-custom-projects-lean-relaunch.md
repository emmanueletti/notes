# Custom projects: lean relaunch plan

## Background

Custom projects launched in beta. Feedback from SarahBijoux (Sarah + Florence, one studio, two people replying on the same thread) came back negative on adoption:

- They will keep using their current system (binder + Google Drive + shared Google Sheet) for now.
- Main complaint: the workflow feels impersonal and rigid, breaks the direct client relationship that matters in custom jewellery work.
- Feature requests raised: size field, metal choice (colour/carat), multiple projects per client, multiple estimates per project.
- When asked directly what's painful about their current process, Sarah named one specific thing: "the time it takes to store files in the drive."

Important caveat: this is one studio's feedback, not a broad signal. Before committing to a rebuild, get 2-3 more studios' input. Emmanuel has already reached out asking about current tooling, pain points, and missing features; Florence hasn't answered that yet.

## Why lean methodology applies here

The V1 build invested in a full workflow (client-facing renderings, estimates, structured fields) based on an unvalidated assumption: that jewellers want a formal system for custom projects. That assumption was wrong for this account. Rebuilding more fields onto the same rejected shape repeats the mistake.

Lean approach: stop building on assumptions, go back to the one validated, felt pain point, build the smallest testable thing that addresses it, ship, measure adoption, then decide whether to expand.

The validated pain point is narrow: **file organization is slow**, not "we need end-to-end project management."

## Is it even solvable without replacing Drive

Yes. The pain isn't "Drive is bad," it's "manual filing is slow." That's addressable by integrating with their existing Drive rather than building a competing storage system. Drive stays the source of truth; Workbench automates the plumbing they already do by hand.

## Proposed MVP scope

**Core mechanic**
- Studio connects their Google Drive account once (OAuth).
- Creating a custom project in Workbench auto-creates a matching Drive folder using a template, e.g. `/Custom Projects/<client> - <project>/Sketches, Renderings, STL, Correspondence`, instead of the jeweller manually navigating and naming folders each time.
- Workbench stores the Drive folder's file ID (not name or path) as the link. Folder IDs are immutable, so the link survives the studio renaming or moving the folder in Drive. Only breaks if the folder is deleted/trashed or Drive access is revoked. If Workbench caches the folder's display name, it should re-fetch from the API rather than storing it statically, so renames don't go stale.

**In the project view**
- Embedded Drive picker so files can be dragged in without leaving Workbench or hunting for the right folder. This directly targets Sarah's named pain.
- Only required fields: client name and the folder link. Size, metal, project status: optional notes, never mandatory gates. Avoids repeating the "rigid system" complaint.

**File previews**
- Images, PDFs, Google Docs/Sheets/Slides preview cleanly via Drive's `thumbnailLink` and embeddable preview iframe (`drive.google.com/file/d/<id>/preview`). Works out of the box.
- STL files (3D models) are not previewable through Drive's API. Would need a custom client-side viewer (e.g. Three.js STL loader) fetching raw file bytes. Treat as phase 2, not MVP-blocking.
- OAuth scope tradeoff: narrow `drive.file` scope only sees files the app itself touched (or picked via the Drive Picker), which is safer but means files uploaded directly in Drive outside the app aren't visible to Workbench. Broader `drive.readonly` avoids that but is a bigger permission ask during setup and a bigger surface for the security review.

**Deliberately out of scope for MVP**
- No auto-generated renderings or estimates sent to the customer. Jeweller keeps sending those manually, however they do today. This is what fixes the "impersonal" complaint: the tool never touches the client relationship, it only organizes the back office.
- No multi-project/multi-estimate scaffolding yet. Not validated beyond one account's request.

**Phase 2 candidate (not in MVP)**
- Replace the studio's shared Google Sheet (casting step tracking) with a status field in Workbench, once folder-linking is proven out.

## Success metric for the pilot

Time from "project starts" to "files organized" drops versus their current manual Drive process, or more simply: studios keep using it past week 2 without reverting to their old process.

## Next steps

1. Wait for Florence's reply to Emmanuel's outreach questions (current tooling, pain points, missing features).
2. Get 2-3 more studios' input on the file-organization pain point specifically, before committing build time. Confirm it's a shared pain, not a one-off.
3. Draft interview questions targeting the "auto-linked Drive folder" concept directly, to validate before building.
4. If validated: scope the MVP above, flag the Drive OAuth scope decision for security review given the broader read-access tradeoff.

## Proposed flow

Kept intentionally thin, matching the MVP scope above.

1. **Side nav entry**: keep the existing "Custom Projects" nav item. No rename, no re-teaching, the pivot is in what happens after the click.
2. **Index page**: simple list, client name, project name, Drive folder link, created date. No dashboard, no status pipeline. One button: "New custom project."
3. **Create step**: minimal form, not a wizard. Client (existing customer or new name) and project name (free text). No size, metal, or estimate fields at creation. Submit immediately.
4. **On submit**: Workbench calls the Drive API, creates the folder from the template, stores the folder ID, redirects straight to the project page. No confirmation screens.
5. **Project show page**: Drive folder embed at the top (live thumbnail grid via the API, so it stays true even if files get added directly in Drive), drag-and-drop or embedded Drive picker to add files without leaving the page, "Open in Drive" always visible as an escape hatch, one optional free-text notes field for anything else, never required.
6. **Deliberately absent**: no "send to client" button, no rendering/estimate builder, no required fields past client + project name, no multi-estimate structure. Two carat options for now means two lines in the notes field, not a new schema, until real demand proves it out.

Total path from nav to "files landing in the right folder": nav to new project to fill 2 fields to submit to drag files in. That's the loop the lean bet rides on: faster than opening Drive, finding the folder, and naming files by hand.

## How this maps to Sarah's stated pain

Her exact words: "the time it takes to store files in the drive, I like to work fast."

What's likely slow today: opening Drive, navigating the folder tree to find or create the right client/project folder, typing a consistent name, building subfolders (sketches, renderings, STL), then dragging each file in. Repeated every time a new file shows up for that project.

| Step today | Step in the flow |
|---|---|
| Open Drive, hunt for the right folder | Folder already linked on the project page, zero navigation |
| Create folder, type a name, keep naming consistent | Auto-created from template on project creation, one time, no typing |
| Build sketches/renderings/STL subfolders by hand | Subfolders come from the template automatically |
| Alt-tab to Drive, drag file into the right subfolder | Drag file straight into the embedded picker on the project page she's already on |
| Repeat all of the above on every new file for that project | Same one-click path every time, folder link persists regardless of renames |

Why it's actually faster, not just different: she doesn't have to leave Workbench or make any decisions (where does this go, what do I name it), only "open the project" and "drop the file." Drive itself doesn't change, so nothing new to learn, just fewer clicks between having a file and it being filed correctly.
