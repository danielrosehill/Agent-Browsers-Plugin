# Claude Agent Browsers

> **Work in progress.** See [`docs/design.md`](docs/design.md) for the plan and [`docs/desktop-jump.md`](docs/desktop-jump.md) for the open bug.

A Claude Code plugin that gives Claude its own browsers and keeps them out of your way.

- **Typed browser registry.** Local (this machine), LAN (a home server) or VPS (remote). Each has addresses
  (LAN / tailnet / public), an MCP endpoint, a viewer URL and a login source, all in your own
  `~/.config/claude-agent-browsers/browsers.json`. See [`config/browsers.example.json`](config/browsers.example.json).
- **Linux desktop deconfliction.** The agent browser runs on the agent's own virtual desktop, in the background.
  It never pulls your view over or steals focus. KDE Plasma 6 first; GNOME and wlroots are planned.

## Skills

| Skill | What it does |
|---|---|
| `setup` | Writes your `browsers.json`, creates the agent desktop, installs the window rule, proves the browser launches without moving your view |
| `pick-browser` | Chooses local / LAN / VPS for a task and resolves the reachable address (LAN, else tailnet, else public) |
| `drive-browser` | Snapshot → ref → act; reuses the open local browser instead of launching another, and closes everything it opened when done |
| `show-me` | Asks before showing you the agent browser; on a yes switches your view to the agent desktop, and back afterwards |
| `panel-current-desktop` | Sets the KDE panel's task manager to show only this desktop's windows, so the agent's browser doesn't appear there |
| `deconflict-desktop` | Installs, checks, removes and tests the KDE window rule; `takeover` lets you type into the agent browser |

## Scripts (all print JSON)

| Script | Purpose |
|---|---|
| `scripts/registry.py` | `path`, `list`, `get <id>`, `resolve [<id>]`, `workspace` over your `browsers.json` |
| `scripts/desktop.sh` | `current`, `ensure`, `show`, `back`: the desktop backend seam (KDE built; GNOME, Hyprland, Sway planned) |
| `scripts/kde-browser-workspace.sh` | `install`, `status`, `remove`, `takeover on\|off`: the KWin rule (forced desktop, extreme focus-stealing prevention, never accepts focus) |
| `scripts/kde-desktop-watch.sh N` | Watches for N seconds and reports any desktop switch, window creation and activation. This is the test for "did it jump?" |
| `scripts/kde-panel-current-desktop.sh` | `status`, `on`, `off`: task manager "only current desktop" on every panel, applied live |
| `scripts/local-browsers.sh` | Lists Playwright-managed browsers running on this machine, with age and owning MCP; `kill <pid>` for leftovers |
| `test/launch-cycle.cjs` | Headed Playwright Firefox launch / navigate / new tab / close, twice, to test the rule without an MCP |

Requirements: Linux, KDE Plasma 6 (`qdbus6`, `kwriteconfig6`, `kreadconfig6`) for the desktop parts, Python 3, a Playwright MCP server for each browser.

## License

MIT
