# Generating SSH keys

## The key pair

`ssh-keygen` makes two files:

- `~/.ssh/id_ed25519` — private. Never leaves your machine. Never shared with anyone, ever.
- `~/.ssh/id_ed25519.pub` — public. Safe to paste anywhere.

The `.pub` is the only half you hand out. It goes into `~/.ssh/authorized_keys` on the server you want to reach. That file means "any of these keys may log in as this user".

So when a founder adds you to a devbox, all they did was append your `.pub` line to that file.

## The handshake

1. You run `ssh you@devbox`
2. Devbox reads `authorized_keys`, finds your public key, sends back a random challenge
3. Your machine signs the challenge with the private key
4. Devbox verifies the signature using the public key. Match means you're in.

The private key never crosses the wire. The server only ever holds the public half. That's the whole point — a compromised server leaks nothing that lets someone impersonate you.

## Host keys and known_hosts

Everything above is you proving who you are to the server. Authentication runs the other way too, and it runs first.

Every SSH server has its own key pair, generated at install time, living in `/etc/ssh/ssh_host_*`. Same idea as yours, different owner. Before you authenticate, the server signs a challenge with its host private key so you can confirm the machine on the other end is the one you meant to reach.

Your side records the server's public host key in `~/.ssh/known_hosts`. First connection looks like:

```
The authenticity of host 'devbox (10.0.0.5)' can't be established.
ED25519 key fingerprint is SHA256:abc123...
Are you sure you want to continue connecting (yes/no)?
```

That prompt is honest: your machine has never seen this server and cannot vouch for it. Saying yes writes the key to `known_hosts`. Every later connection is checked silently against that stored copy.

This is called trust on first use. The first connection is the weak point — you're accepting a key you can't verify. To do it properly, get the fingerprint from whoever runs the box, over a channel that isn't the connection you're securing, and compare before typing yes. On the server itself:

```
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

### When the key changes

```
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

Two possible causes, and they are very different:

- Benign: the box was rebuilt, reimaged, or the IP got recycled onto a different machine. Common with cloud instances and devboxes.
- Not benign: something is sitting between you and the server, presenting its own key to read your traffic.

Do not blindly run `ssh-keygen -R`. Confirm with whoever owns the box that it was rebuilt. Once confirmed, drop the stale entry and reconnect to accept the new one:

```
ssh-keygen -R brother-devbox
```

The reason this warning is loud and refuses to connect is that host key checking is the only thing standing between you and a machine-in-the-middle. Your private key won't be leaked either way, but everything you type in that session would be.

### Why it matters more than it looks

Say yes without checking and you get most of SSH's protection anyway — after that first connection, any later substitution is caught. The risk is concentrated entirely in that one prompt. Worth knowing so you can spend the effort where it counts instead of clicking through both.

## Anatomy of the keygen command

```
ssh-keygen -t ed25519 -a 64 -f ~/.ssh/id_ed25519_brother_devbox -C "emmanuel@itsusstudio.com"
```

`-t ed25519` — key type. Elliptic curve, not RSA. 256-bit, roughly equal in strength to 3072-bit RSA, but far smaller and faster. The modern default. Related option worth knowing: `ed25519-sk`, which is backed by a hardware security key.

`-a 64` — 64 KDF rounds. If you set a passphrase, the private key file on disk gets encrypted with a key derived from that passphrase. More rounds means slower derivation, so brute-forcing a stolen file costs more per guess. Default is 16. Costs you about a tenth of a second at unlock time.

Caveat: this only matters if you actually set a passphrase. Empty passphrase means the file is unencrypted and the rounds do nothing.

`-f <path>` — output path. Writes both files: the private key at that path (mode 600) and the public key at the same path plus `.pub`.

Using a non-default name gives you one key per destination. Good hygiene — revoking access to one box then doesn't touch anything else.

`-C "email"` — comment. Plain text appended to the `.pub` file. Purely a label, so whoever admins the box knows whose key that line is. Not an identity, not verified, not used in the handshake at all.

## Looking at what you made

Read the public key back:

```
cat ~/.ssh/id_ed25519_brother_devbox.pub
```

One line, three space-separated fields:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... emmanuel@itsusstudio.com
```

- `ssh-ed25519` — the algorithm, so the server knows how to verify signatures from it
- the base64 blob — the actual public key material
- `emmanuel@itsusstudio.com` — the `-C` comment, just a label

That whole line is what gets appended to `~/.ssh/authorized_keys` on the server. Copy it exactly, one line, no wrapping.

Confirm the private key is locked down:

```
ls -l ~/.ssh/id_ed25519_brother_devbox
```

Should read `-rw-------` (mode 600). If the group or world can read it, ssh refuses to use the key at all — a deliberate guard, not a bug.

If you want a short identifier for the key without exposing anything, get its fingerprint:

```
ssh-keygen -lf ~/.ssh/id_ed25519_brother_devbox.pub
```

Useful for confirming over a call that the key on the server is the same key you hold.

## Consequence of a custom filename

SSH only auto-tries the default names (`id_ed25519`, `id_rsa`, and friends). A custom name won't get picked up. Add it to `~/.ssh/config`:

```
Host brother-devbox
  HostName <ip-or-dns>
  User <username>
  IdentityFile ~/.ssh/id_ed25519_brother_devbox
  IdentitiesOnly yes
```

Then just `ssh brother-devbox`.

`IdentitiesOnly yes` matters more than it looks. Without it, ssh offers every key in your agent before the right one. Servers usually cut you off after about 6 failed attempts, so a full agent can lock you out of a box you have perfectly valid access to.

## 1Password as an SSH agent

An SSH agent is the thing that holds your private key and performs step 3 of the handshake on your behalf. 1Password can be that agent, which is why it asks for a private key when you create an SSH item.

It wants *your* private key, the one on your laptop. Not anything from the server. The server has no private key of yours and never will.

Two ways to set it up:

**Move an existing key in.** Copy the full contents of the private key file, including the `-----BEGIN-----` / `-----END-----` lines, into a 1Password SSH key item. Then delete the local copies:

```
rm ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```

Deleting is the point. Otherwise you have two copies of a secret instead of one. Enable the agent in 1Password settings, then in `~/.ssh/config`:

```
Host *
  IdentityAgent ~/.1password/agent.sock
```

**Generate fresh inside 1Password.** The private key never touches disk. Cleaner, but the new public key has to be added to the server, so it costs another round trip with whoever admins it.

## Rules of thumb

- If anything other than your own agent or laptop asks for a private key, stop. A server, a website, a teammate — none of them ever need it.
- The `.pub` file is the only thing you paste into chat, tickets, or GitHub.
- One key per destination beats one key for everything.

## Open questions

- What's actually inside the OpenSSH private key format?
- What does an SSH certificate authority buy over `authorized_keys` and `known_hosts` at scale? Signing host keys with a CA is how orgs avoid trust on first use entirely.
- How does agent forwarding work, and why is it considered risky on boxes you don't control?
