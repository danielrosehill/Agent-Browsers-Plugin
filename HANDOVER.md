# Handover: Claude-Agent-Browsers-Plugin (started 2026-11-15)

Written by the agent that started this repo, for the agent that finishes it. The owner started it from a Home
Assistant session and wants this work done in its own session. Delete this file once its items are done and
the README describes the plugin.

## Goal

A **public** Claude Code plugin, installable on any of the owner's machines (and useful to others), that does two
things together:

1. **Agent browsers as a first-class, typed registry.** Each browser has a `type` — `local` (on this machine),
   `lan` (a server on the home network), `vps` (a remote host) — plus its addresses (LAN, tailnet, public), MCP
   endpoint, viewer URL, engine and login source. All of it is **user configuration**
   (`~/.config/claude-agent-browsers/browsers.json`, shape in `config/browsers.example.json`). Nothing personal
   goes in the repo. Skills pick a browser by purpose/type and reach it by the best address (LAN when on the LAN,
   else tailnet, else public).
2. **Linux desktop deconfliction.** The agent's browser lives on the agent's own virtual desktop ("workspace") and
   runs in the background: it must **never** move the user's view, take focus or pop over their work. This is the
   point of the plugin. Claude in Chrome works but gets in the way on a laptop.

## Where it comes from (private sources, do not copy personal values)

- `danielrosehill/Agent-Browsers-Plugin` (private, local clone `../Agent-Browsers-Plugin`): the owner's current
  plugin. Skills `drive-personal-browser`, `drive-business-browser`, `browser-login`, `captcha-handoff`,
  `browser-status`, `install-local-viewers`, `drive-local-browser`, `local-browser-workspace`. Port the
  *patterns*; replace every hostname, IP, port, email and account with config lookups. Plan: once this one
  works, that private plugin either goes away or shrinks to the owner's `browsers.json` plus anything truly
  private.
- `danielrosehill/Chrome-To-Agent-Browser-Login-Sync` (private): copies Chrome profile cookies into Playwright
  storage state for the local browser (`targets/firefox/launch.sh <name>`). Decide: depend on it as an optional
  `login_source.kind = "chrome-cookies"` backend, or fold a generic version in.
- `danielrosehill/Claude-KDE-Agent-Workspace-Plugin` (**public**, `../Claude-KDE-Agent-Workspace-Plugin`):
  creates the agent desktop, `scripts/kagent.py` (KWin scripting over D-Bus: list windows, move, capture,
  AT-SPI input). Reuse it as a dependency, or move the browser-specific parts here. Keep the two from overlapping.
- `scripts/kde-browser-workspace.sh` here is copied as-is from the private plugin's
  `scripts/local-browser-workspace.sh` (no personal data in it). It writes the KWin rule
  `[agent-browser-workspace]` in `~/.config/kwinrulesrc`: `wmclass=firefox-default` (exact), `desktops=<UUID of the
  desktop named Claude>` forced, `fsplevel=4` (extreme) forced, `types=1`. Make the class and desktop name
  come from `browsers.json` (`window_class`, `workspace.desktop_name`).

## Open bug: the desktop still jumps (reproduced 2026-11-15, KDE Plasma 6, Wayland)

With the rule above installed, the window **does** open on the Claude desktop. But KDE **switches the user's view
to Claude** when the Playwright MCP starts a new Firefox. Evidence, from polling
`qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.current` every 100 ms during a
`browser_navigate` that launched a fresh browser:

```
15:43:01.908 <user desktop uuid>
15:43:05.416 <Claude desktop uuid>     <- jump at window launch
15:43:07.242 <user desktop uuid>       <- probably the user switching back by hand
```

So focus-stealing prevention "extreme" alone is not enough. Playwright starts Firefox with `-foreground`, and the
browser asks to be activated. KWin activates the window and follows it to its desktop. An earlier check missed this:
it read the current desktop only *after* launch. **Verify with the 100 ms poller, not a single read.**

Candidates, none tested yet (the owner stopped the first attempt so it could move to this repo):
1. KWin rule `acceptfocus=false` + `acceptfocusrule=2`: the window can never be activated, so there's nothing to
   follow. Cost: the user can't type into it when taking over (the Playwright protocol doesn't need OS focus).
   Maybe toggle it off with a "take over" skill.
2. KWin rule `activity`/`minimizerule`, or the `kwinrc [Windows]` setting that controls what happens when a window
   on another desktop is activated (Plasma 6 "when activating a window on a different virtual desktop"). Neither
   of its options, switch or bring here, is what we want, so probably not.
3. Stop the activation at the source: launch the Playwright browser without `-foreground` (custom executable
   wrapper or launch options in the Playwright MCP config), or run it in a nested/headless compositor and view it
   another way. `kde-agent-workspace` already has a headless-KWin "sandbox" mode on a private bus that may
   solve this for free.
4. A small KWin script (loaded persistently) that on `windowActivated` of class X on the agent desktop
   switches `workspace.currentDesktop` straight back. Last resort; it would flicker.

Done means: the poller shows **no** desktop change across launch, navigation, new tabs and `browser_close` +
relaunch, and the user's focused window stays focused.

## Other Linux desktops

KDE first, since the owner runs Plasma 6 on Wayland. Leave a clean `workspace.backend` seam for GNOME (workspaces are
first-class on Ubuntu; likely a GNOME Shell extension or `gdbus` calls to `org.gnome.Shell`) and Hyprland/Sway
(window rules `workspace X silent`), even if only KDE is built now.

## Skills to end up with (suggested)

- `setup` — write `browsers.json` interactively, create the agent desktop, install the window rule, verify with the poller.
- `pick-browser` — choose a browser by task (local vs LAN vs VPS, login needed, egress), resolve the address.
- `drive-browser` — generic driving notes (snapshot → ref → act, close when done).
- `browser-login` / `captcha-handoff` / `browser-status` — ported, viewer URL from config.
- `deconflict-desktop` — install/check/remove the rule + the jump fix; `status` runs the poller test.
- `take-over` — let the user type into the agent browser temporarily (if candidate 1 is chosen).

## House rules for this repo

- Public. No owner names, emails, IPs, tailnet names, hostnames or account lists in commits. Use `192.0.2.x` /
  `100.64.x.x` / `example.com` in docs.
- Release tags `v0.<n>` until it works end to end, then `v1.0`, `v1.1`, … (owner's scheme: small tier `vMAJOR.N`).
- Machine-facing output is JSON.
