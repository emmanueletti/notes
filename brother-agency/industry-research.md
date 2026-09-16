# Industry research: modern WordPress agency dev and deployment

Purpose: ground the agentic development plan in what modern WordPress agencies
actually do, so decisions lean on the battle scars of others rather than
first-principles guessing. Sourced from published guides and agency writeups
(links at the bottom).

## Headline

The modern agency path is well-trodden, standard, and boring. The work then
becomes: adopt the standard stack, build only the differentiated leverage (a
reusable component library), and buy the rest.

## The consensus stack

There is real convergence across the sources:

1. Repo structure. WordPress core stays out of git. Either git-root at
   `wp-content/` or use Bedrock. Track only custom themes, mu-plugins, and
   custom plugins. Gitignore `uploads/`, cache, `.env`, and `wp-config.php`.
   Manage plugins via Composer plus WPackagist. This is what Brother's current
   `.gitignore` already does, and what Bedrock formalizes.
2. Dependencies. Composer plus WPackagist for core and plugin version pinning.
   Dependabot for automated update pull requests.
3. Local dev. Docker based, and DDEV is the modern favorite. Agencies moved off
   Trellis and Vagrant to DDEV as smoother. Reproducible per-project PHP and
   database versions. Bedrock officially supports DDEV, Lando, and Local.
4. Deployment. GitOps: git is the single source of truth, `main` is production
   plus a `staging` branch plus feature branches, deploy via GitHub Actions or
   WP-CLI, staging to production flow, daily backups.
5. Components. ACF Blocks is the agency standard for reusable component
   libraries.

## ACF Blocks: strong consensus, one real caveat

The data is encouraging and sobering:

- PHP-oriented teams ship ACF Blocks fast (4 to 6 hours to learn, no React
  required), and reusable block libraries compound ROI: build once, reuse
  everywhere. The "Rows" custom-post-type pattern makes pages modular stacks
  editable in one place.
- Caveat and the scar: ACF Blocks require a mature delivery practice and
  systematic validation before launch. Component systems that are not validated
  drift. This is the one discipline worth keeping, not deleting.
- Nuance on Tailwind: the mainstream ACF Blocks path uses PHP templates, which
  is the low learning curve. Tailwind is a compatible, additive choice (and
  agents are good at it), but the reuse value comes from ACF Blocks
  standardization, not Tailwind specifically. Do not conflate the two.

## Hosting: a nuance that may avoid a migration

Corrected 2026-07-30 after checking primary sources. The original version of this
section claimed WP Engine "supports Bedrock (via an empty environment)". That is
wrong, and it was load-bearing for Decision 5. No WP Engine or Roots
documentation describes such a mechanism.

- WP Engine does offer per-site git-push auto-deploy. The founder is already on
  WP Engine.
- WP Engine does not support Bedrock's layout. The document root is fixed at the
  install root and cannot be pointed at `web/`. Roots' own server-configuration
  docs name Kinsta as a host that will repoint a docroot; WP Engine is absent
  from their supported-hosts list.
- Bedrock can still be *deployed* to WP Engine, and WP Engine documents this,
  but only by flattening `web/app/` into `wp-content/` during a build step and
  adding a `00-autoloader.php` mu-plugin, because WP Engine owns
  `wp-config.php`. Bedrock's `.env` config layer does not survive that.
- The two features are mutually exclusive. Native git-push deploy has no build
  step, so it cannot run `composer install`. Any Composer-managed site on WP
  Engine deploys through GitHub Actions, Bedrock or not.
- Kinsta does support Bedrock natively: `POST /change-webroot-subfolder` sets a
  per-environment webroot such as `/web`. API-only for now, no MyKinsta UI.
  Kinsta has no native git-push (needs GitHub Actions or SSH glue).
- Managed PaaS (Upsun, Sevalla) has native git-push plus preview environments
  and is Bedrock friendly.

Honest read: WP Engine can do git-push deploy plus staging, and can host a
Composer-managed site via GitHub Actions, so the low-risk default is still to
configure what they have rather than re-platform. But that default does not
include Bedrock, and it does not include per-branch previews. Move to Kinsta or
a PaaS only if Bedrock's layout or preview-per-branch is worth the migration.

## What this means for Brother

- The standard stack (Composer plus DDEV local plus managed-host git deploy plus
  ACF Blocks plus GitOps branches) is documented and supported. This validates
  the buy-don't-build direction: most of what the agency needs is standard, so
  the bespoke `tool-*` infrastructure is the anomaly to retire.
- Bedrock is one of two accepted repo structures, not a requirement. The
  consensus stack above says "either git-root at `wp-content/` or use Bedrock",
  and the reproducibility the agency is after comes from Composer plus DDEV
  either way. On WP Engine, Bedrock costs a build-and-flatten step and returns
  nothing Composer and DDEV did not already provide.
- Non-migration confirmed, with a caveat: WP Engine can host the Composer plus
  DDEV stack with no re-platform, but deploys go through GitHub Actions rather
  than native git-push, because the build step is required.
- Keep one discipline the scars insist on: component and block validation.
  Unvalidated block systems drift.

## Sources

Consensus stack and git practices:

- DeployHQ, WordPress Development in 2026:
  https://www.deployhq.com/blog/wordpress-development-in-2025-from-full-site-editing-to-flawless-deployments
- Belov Digital, WordPress Git best practices:
  https://belovdigital.agency/blog/wordpress-development-with-git-version-control-best-practices/
- Pressable, WordPress GitHub workflows:
  https://pressable.com/blog/wordpress-github-workflows/
- Upsun, modern WordPress development workflow:
  https://upsun.com/blog/modern-wordpress-development-workflow/

Bedrock, Trellis, DDEV, Docker:

- Roots Bedrock local development:
  https://roots.io/bedrock/docs/local-development/
- Roots Bedrock with DDEV: https://roots.io/bedrock/docs/bedrock-with-ddev/
- DeployHQ Bedrock deploy guide: https://www.deployhq.com/guides/bedrock
- Kinsta, Bedrock and Trellis: https://kinsta.com/blog/bedrock-trellis/
- CSS-Tricks, scalable WordPress server with Trellis:
  https://css-tricks.com/i-spun-up-a-scalable-wordpress-server-environment-with-trellis-and-you-can-too/

ACF Blocks and component libraries:

- ACF, From Chaos to Control with ACF:
  https://www.advancedcustomfields.com/blog/from-chaos-to-control-with-acf/
- ACF, ACF Blocks vs Native Blocks data:
  https://www.advancedcustomfields.com/blog/acf-blocks-vs-native-blocks/
- Sonnet.digital, scaling WordPress dev with ACF and custom blocks:
  https://sonnet.digital/the-edge/how-we-scale-wordpress-development-with-acf-and-custom-blocks/
- GetDevDone, modular WordPress with ACF Blocks (JSON registration):
  https://getdevdone.com/blog/how-to-build-modular-wordpress-websites-with-acf-blocks-json-registration-guide.html

Hosting git-push deploy:

- Kinsta push environments:
  https://kinsta.com/docs/wordpress-hosting/wordpress-push-environments/
- Kinsta continuous deploy with GitHub Actions:
  https://kinsta.com/blog/continuous-deployment-wordpress-github-actions/
- Anchor.host, automatic git deploy with Kinsta via SSH:
  https://anchor.host/automatic-git-deploy-with-kinsta-via-ssh/
