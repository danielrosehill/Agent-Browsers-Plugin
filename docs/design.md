# Design

Moved from the start-up handover on 2026-11-15.

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

## Sources (port patterns only, never personal values)

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

## Other Linux desktops

KDE first, since the owner runs Plasma 6 on Wayland. Leave a clean `workspace.backend` seam for GNOME (workspaces are
first-class on Ubuntu; likely a GNOME Shell extension or `gdbus` calls to `org.gnome.Shell`) and Hyprland/Sway
(window rules `workspace X silent`), even if only KDE is built now.

## Skills to end up with (planned)

Built 2026-11-15: `setup`, `pick-browser`, `drive-browser`, `show-me`, `deconflict-desktop` (covers `take-over` via
`kde-browser-workspace.sh takeover`). Still to port: `browser-login`, `captcha-handoff`, `browser-status`.


- `setup` — write `browsers.json` interactively, create the agent desktop, install the window rule, verify with the poller.
- `pick-browser` — choose a browser by task (local vs LAN vs VPS, login needed, egress), resolve the address.
- `drive-browser` — generic driving notes (snapshot → ref → act, close when done).
- `browser-login` / `captcha-handoff` / `browser-status` — ported, viewer URL from config.
- `deconflict-desktop` — install/check/remove the rule + the jump fix; `status` runs the poller test.
- `take-over` — let the user type into the agent browser temporarily (if candidate 1 is chosen).

## Owner requirements added 2026-11-15

- **Local browser hygiene.** Agents tend to open a new browser per task and leave it open. The local-browser
  skills must reuse an already-open agent browser instead of launching another one, and must close whatever
  they opened (tabs, then the browser via `browser_close`) when the task is done, the way a test cleans up.
- **Show on request, never by force.** The browser stays on the agent desktop. When there is something worth
  seeing, the agent asks ("want to look at the preview?"); only on a yes does it switch the user's view to the
  agent desktop (`workspace.backend` → KDE: `VirtualDesktopManager.current = <agent desktop id>`; GNOME and
  wlroots equivalents behind the same seam), and it offers to switch back afterwards. Skill: `show-me`.
