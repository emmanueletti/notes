# Screen sharing from Linux to the Mac mini

Driving the Mac mini (`studio-macmini`) from the Framework, mainly to run the
Xcode simulator for iOS work.

## The hardware

```
Macmini8,1          2018 Mac mini
6-core Intel i5     3 GHz
Intel UHD 630       integrated only, no discrete GPU
macOS 15.7.7        Sequoia
```

Intel matters more than it looks — several decisions below only make sense
because of it. Macmini8,1 was dropped from the supported list in the macOS
release after Sequoia, so 15.7.7 is likely this machine's ceiling. Worth
checking `xcodebuild -showsdks` against the iOS versions being targeted before
investing further in this setup.

## The shape of it

macOS already is a VNC server. Screen Sharing in System Settings is a full VNC
server listening on 5900 — there is nothing to install on the Mac for the
screen half. The Linux side only needs a client.

So the split is:

- Mac: enable Screen Sharing, install Tailscale. Nothing else.
- Linux: a VNC client, plus Tailscale.

Tailscale is what makes this safe. macOS caps its legacy VNC password at 8
characters, which is not something you want reachable from the open internet.
On a tailnet the port is only exposed to your own devices, so the weak password
stops mattering.

## Connect

```
remmina -c vnc://studio-macmini
```

Short name works because the tailnet suffix is in the resolv.conf search list.
The FQDN always works regardless:

```
studio-macmini.sailfish-gorgon.ts.net
```

Saved Remmina profiles should use the FQDN — profiles outlive network config
changes.

Check the far end is actually up before blaming the client:

```
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/studio-macmini/5900' && echo open
```

## Authentication

Two paths, and which one you get decides whether you need that 8-char password.

macOS's native auth is Apple ARD security type 30 (Diffie-Hellman). Remmina's
VNC backend is libvncclient, which supports type 30, so you can log in with your
real Mac username and password.

TigerVNC does not support type 30. It only speaks standard VncAuth (type 2). To
use it you have to enable the legacy path on the Mac:

System Settings > General > Sharing > Screen Sharing (i) > Computer Settings >
"VNC viewers may control screen with password"

That's the 8-character cap. Username blank, password only.

## Why Remmina and not TigerVNC

Tried both. TigerVNC is uninstalled now — this is the record of why, so the
comparison doesn't have to be redone later.

They're different categories. TigerVNC is a VNC protocol implementation with its
own tuned renderer, and its raw throughput is generally better. Remmina is a
connection manager wrapping backends, and its libvncclient backend is slower.
Throughput turned out not to be the deciding factor.

The dealbreaker is scaling. TigerVNC 1.16.2 has no client-side scale-to-fit at
all — verified against both the man page and the binary. The only sizing options
are `DesktopSize` and `RemoteResize`, and both work by asking the *server* to
change resolution via the SetDesktopSize message. macOS Screen Sharing doesn't
implement it, so both silently do nothing and you get the remote framebuffer 1:1
in a scrolling window with no way to fit it.

Verify the claim rather than trusting this note, if it ever matters again:

```
zcat /usr/share/man/man1/vncviewer.1.gz | grep -ic scal
```

Zero. The `sws_scale` strings in the binary are ffmpeg's swscale used for H.264
decoding, not viewport scaling.

Secondary reasons Remmina wins:

- Keyboard grab that works windowed, not only fullscreen
- ARD type-30 auth, so no 8-character legacy password needed
- Saved profiles, credentials, per-host quality settings

TigerVNC would still be the better choice against a server that supports
SetDesktopSize — a Linux box running x0vncserver, say. It's specifically the
macOS end that rules it out.

## Keyboard grab

The single most important setting. Xcode and the Simulator are Cmd-key soaked,
and GNOME swallows Super before it ever reaches the VNC client — Cmd-R,
Cmd-Shift-K, Cmd-Shift-H all dead.

```
Ctrl+Alt+G
```

Or the keyboard icon in the connection toolbar. Then Super passes through as
Cmd.

Remmina saves the toggle per profile, so it only needs setting once.

## Zoomed-in display

The cause, measured while the Dell was still attached:

```
Resolution:    3840 x 2160
UI Looks like: 1920 x 1080 @ 30.00Hz
```

Classic 2x HiDPI. macOS draws the UI at "looks like 1080p" but the real
framebuffer is 3840x2160, and VNC ships the whole framebuffer. Four times the
pixels needed, arriving at double size. That is the zoom.

The 30Hz is a second, independent problem — that panel does 4K60 over
DisplayPort, so something was negotiating down. 30Hz feels sluggish before VNC
is involved at all.

Quick fix, in Remmina:

```
Ctrl+Alt+S
```

Toggles scaled mode, fitting the remote desktop into the window instead of
showing a 1:1 crop. Costs sharpness — Xcode text goes soft. There is no
TigerVNC equivalent, see above.

## The dummy plug decision

Buy a 1080p HDMI headless display emulator. Roughly $8, sold in multipacks,
search "HDMI dummy plug 1080p".

Why a plug rather than fixing the resolution in software: the Dell is only
connected while setting things up, and it gets powered off the rest of the time.
Powering off a DisplayPort monitor drops the link, so macOS sees a genuine
disconnect and goes headless. Any `displayplacer` setting applied to the Dell
dies with it — different display, different id, nothing carries over.

Headless on an Intel mini is the bad case: macOS synthesises a low-resolution
virtual display and the compositing path for it is degraded. This is why CI
farms put dummy plugs on Intel minis, and Simulator rendering through
WindowServer is exactly that workload.

The plug solves it structurally. Always present, always 1080p, never HiDPI. No
`displayplacer`, no persistence problem, no virtual display.

Why 1080p and not 4K, since this reads backwards at first: 1080p is not the
fuzzy option, it is the sharp one. The Mac renders 1920x1080, VNC sends
1920x1080, the Framework's 2256x1504 screen shows it one pixel to one pixel with
room to spare. No resampling anywhere.

A 4K plug would mean 3840x2160 arriving on a smaller screen, so Remmina would
have to shrink it — and that resampling is what makes text soft. It would also
push 4x the pixels through UHD 630 and over the wire. Fuzzy and slow, to gain
screen real estate that doesn't fit on the laptop panel anyway.

Sharp and cramped beats fuzzy and slow. The tradeoff is space, not sharpness.

Once the plug arrives, unplug the Dell entirely. Leaving both attached works but
makes it a dual-display setup with arrangement to manage.

Software fallback if a plug isn't to hand and a real display is attached:

```
brew install displayplacer
displayplacer list
displayplacer "id:<screen-id> res:1920x1080 hz:60 scaling:off origin:(0,0) degree:0"
```

`scaling:off` is the part that matters — that's what kills the 2x framebuffer.
It does not survive the display being disconnected.

## Skip the GUI when you can

Most of iOS dev needs no pixels, and SSH has no latency problem:

```
ssh <user>@studio-macmini
xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 17' build test
xcrun simctl boot "iPhone 17"
xcrun simctl install booted App.app
xcrun simctl launch booted com.you.app
xcrun simctl io booted screenshot /tmp/s.png
xcrun simctl io booted recordVideo /tmp/s.mov
```

Catch: `simctl` will boot a simulator headless over SSH, but launching the
visible `Simulator.app` window needs an active Aqua session. So the Mac needs
auto-login enabled, and the screen share has to attach to that same console
session.

Screen share is for the 10% where you actually need to tap through UI.

## Making it fast

Biggest wins first, all on the Mac:

- Solid colour wallpaper, never a photo or dynamic one. Animated wallpaper
  destroys VNC delta encoding.
- Accessibility > Display > Reduce Motion on, Reduce Transparency on.
- Drop the display to 1920x1080.
- Disable sleep, enable Wake for network access.

In the Simulator:

- Cmd-2 or Cmd-3 for 50%/33% scale. Fewer pixels is directly less lag.
- Small device (iPhone SE) when you don't need a big one.
- Debug > Slow Animations off.

In Remmina's profile: colour depth 16bpp, quality "Good" or lower.

## FileVault on a headless box

Worth deciding deliberately. With FileVault on, a reboot parks at the pre-boot
unlock screen with no network — no SSH, no screen share, you're walking over
with a keyboard. Turning it off means an unencrypted disk. Decide by where the
machine physically lives.

## If VNC isn't good enough

RustDesk is the next step up. Not VNC — its own protocol using a real video
codec instead of framebuffer deltas, so it's noticeably smoother for animated
UI. Self-hostable relay. Costs an agent install on the Mac plus Screen Recording
and Accessibility permission grants.

NoMachine performs better than all of these by a margin, but it's proprietary.

## Box automation

Fedora side is handled by the box repo:

- `platforms/fedora/modules/02-packages/packages.list` — remmina,
  remmina-plugins-vnc, tigervnc, tailscale
- `platforms/fedora/modules/02-packages/003-enable-vendor-repos.sh` — tailscale
  repo file
- `platforms/fedora/modules/04-postinstall/007-setup-tailscale.sh` — enables
  `tailscaled`, sets `--operator` so tailscale runs without sudo

The operator bit is why `tailscale up` and `tailscale status` don't need sudo.

## Open questions

- Does libvncclient's ARD support cover the newer high-performance Screen
  Sharing mode in recent macOS, or only the legacy VNC path?
- Can the Simulator be driven entirely headless — `simctl` plus a video stream —
  and skip the desktop session requirement altogether?
- Is there a Wayland-native VNC client that handles Super/Cmd remapping better
  than the keyboard-grab workaround?
