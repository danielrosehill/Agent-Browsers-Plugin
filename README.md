# Claude Agent Browsers

> **Work in progress.** See [`HANDOVER.md`](HANDOVER.md) for the plan and open problems.

A Claude Code plugin that gives Claude its own browsers and keeps them out of your way.

- **Typed browser registry.** Local (this machine), LAN (a home server) or VPS (remote). Each has addresses
  (LAN / tailnet / public), an MCP endpoint, a viewer URL and a login source, all in your own
  `~/.config/claude-agent-browsers/browsers.json`. See [`config/browsers.example.json`](config/browsers.example.json).
- **Linux desktop deconfliction.** The agent browser runs on the agent's own virtual desktop, in the background.
  It never pulls your view over or steals focus. KDE Plasma 6 first; GNOME and wlroots are planned.

## License

MIT
