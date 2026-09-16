# Git: SSH remotes vs the gh credential helper

> The recurring question: *"push suddenly asks for a GitHub username, what
> broke?"* Usually the answer is that something was quietly rewriting your https
> remote to SSH and it stopped. See also
> [generating-ssh-keys.md](./generating-ssh-keys.md).

---

## Two knobs, not one

Keep these separate in your head:

1. Transport: ssh or https. Decided before git connects.
2. Credentials: who answers the password prompt. Only exists for https.

Credential helpers are an https-only mechanism. SSH never consults them, it uses
your key. This is why "use gh when available, ssh as a fallback" is harder than
it sounds. More on that below.

---

## Seeing what the remote actually is

```bash
git remote -v                    # the raw stored URL
git config --get remote.origin.url   # same thing
git ls-remote --get-url origin   # the URL after insteadOf rewrites
```

The third one is the important one. `insteadOf` rewrites happen at connect time,
not in storage, so `git remote -v` will keep printing `https://...` while git is
really talking SSH. If those two commands disagree, a rewrite is active.

---

## Making a repo use SSH

Three levels, pick by blast radius.

### Per repo, explicit

```bash
git remote set-url origin git@github.com:USER/REPO.git
```

Rewrites the stored URL. Clear and obvious. Trade-off: it dies on every fresh
clone, and if you clone by pasting an https URL from the web you have to
remember to redo it.

### Global, transparent

```bash
git config --global url."git@github.com:".insteadOf https://github.com/
```

Leaves stored URLs as https and rewrites them at connect time. Nothing to
remember per repo.

Trade-off: it applies to every https GitHub URL you ever touch, including
submodules and `go get`. Usually what you want on a personal machine, usually
wrong on a shared or CI machine, where there is a token but no key of yours.

In `.gitconfig` it looks like:

```ini
[url "git@github.com:"]
	insteadOf = https://github.com/
[url "git@gitlab.com:"]
	insteadOf = https://gitlab.com/
[url "git@bitbucket.org:"]
	insteadOf = https://bitbucket.org/
```

### Push only

```bash
git config --global url."git@github.com:".pushInsteadOf https://github.com/
```

Rewrites pushes only, leaves fetches on https. Good for public repos you want to
clone anonymously but push to as yourself.

---

## The gh credential helper

For https remotes, `gh` can answer the credential prompt with its own token:

```bash
gh auth setup-git
```

That writes something like:

```ini
[credential "https://github.com"]
	helper =
	helper = !/usr/bin/gh auth git-credential
```

The empty first `helper =` is not a typo. Credential helpers are a list, and an
empty value resets the list, discarding anything inherited from system config or
from an earlier config file. Without it you stack gh on top of whatever else is
configured and get unpredictable ordering.

Note that `gh auth setup-git` honors gh's own protocol setting. If
`gh auth status` reports `Git operations protocol: ssh`, it will not set up an
https helper. To use the gh path:

```bash
gh config set git_protocol https
gh auth setup-git
```

---

## Why "gh when available, ssh as fallback" cannot be config

This is the useful thing to learn from all of this.

The transport decision happens first and is static. If `insteadOf` rewrites
https to ssh, git connects over SSH and the credential helper is never
consulted. If it does not rewrite, git connects over https and gh answers. The
two are mutually exclusive, and git has no "if this command exists" conditional.
`includeIf` only supports `gitdir:`, `onbranch:`, and `hasconfig:`.

So the fallback has to be decided when the config is written, not when git runs.
In a dotfiles repo that means the install script decides:

```sh
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh auth setup-git
else
  git config --global url."git@github.com:".insteadOf https://github.com/
fi
```

---

## Which to pick

Personal machine, dotfiles repo: use the global `insteadOf` rewrite. One line,
transport level so nothing can prompt, and daily pushes do not depend on gh
being installed, logged in, and holding an unexpired token.

Container, fresh VM, Codespace, CI: use the gh helper or a token. SSH keys are
awkward to get in there and often should not be.

---

## Gotcha: SSH_ASKPASS pointing at a missing binary

Symptom on a KDE Fedora box:

```
fatal: cannot exec '/usr/bin/ksshaskpass': No such file or directory
Username for 'https://github.com':
```

`/etc/profile.d/kde-openssh-askpass.sh` exports `SSH_ASKPASS=/usr/bin/ksshaskpass`
unconditionally, but the `ksshaskpass` package may not be installed. This stays
invisible while SSH works without a prompt, and surfaces the moment anything
needs to ask you for a secret. Either install `ksshaskpass` or unset the variable
in your shell config when the binary is missing.
