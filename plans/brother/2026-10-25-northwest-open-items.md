# Northwest Seminary: open items

Moved out of the repo's AGENTS.md on 2026-10-25.

## Next steps

1. Founder sign-off on the nav, especially the mobile layout (no design existed).
2. bca-renderer hero section with an image light/dark field that outputs
   `nw-hero` and `nw-hero--dark` (drives the header's light/dark look).
3. Before the new theme goes to production: ACF Pro on production, the
   Navigation settings and the audience menus there.
4. CI deploy pipeline. Blocked on a WP Engine user scoped to the three
   Northwest installs (a key on a personal profile reaches all 40 agency
   sites). Then: deploy key on that user, GitHub secret
   WPE_SSHG_KEY_PRIVATE, .github/workflows/deploy.yml (main to staging;
   tags plus environment approval to production). Until then, ddev deploy.
5. Restrict org GitHub Actions to GitHub-owned actions plus
   shivammathur/setup-php.
6. Extract portable parts (rules, .agents/skills, .ddev commands, lint
   setup) into a bca-wp-starter template repo.
7. Dev install (northwests3dev) is a stale June production copy; copy staging
   to dev in the portal before using it for previews.
8. lefthook pre-commit glob skips PHP files at the top of the theme folder.

## How the site is set up

- Production runs the old Astra child theme with Beaver Builder (212 of 230
  pages). northwest-rebuild and bca-renderer run on staging. Existing Beaver
  Builder pages stay; new pages use bca-renderer sections.
- Header nav is database content edited in wp-admin: Appearance >
  Navigation (audiences: tab label, home page, menu, button; contact),
  Appearance > Menus, and the Navigation box on pages (audience exception,
  section links: automatic / none / a different menu, header button).
- An audience's home page claims itself and every page under it. Section
  links are the children of the top-level menu item the visitor is in;
  hidden on phones (they're in the menu).
- Code: inc/nav-context.php resolves the nav per request; template-parts/
  header/ renders it; tools/nav-seed.php seeds local/dev/staging (refuses
  production); tools/nav-check.php prints the resolved nav for a path.
- Menus named by role: "Audience menu – …", "Section links – …", "Footer – …".
- Header is dark (dark-blue bar) unless the page has a hero marked dark
  (nw-hero nw-hero--dark), which switches it to the light (sand) one.
- Figma: "Northwest - Internal" (ycKscXj4jUmXtm7fhsWY5P).
- Plan docs: 2026-10-25-nav-rebuild-design.md, 2026-10-25-nav-review.md in
  this folder.
