# Agent-Browsers-Plugin — agent context

Public Claude Code plugin. Read `docs/design.md` (goal, sources, planned skills, desktop backends) and
`docs/desktop-jump.md` (the open KDE desktop-jump bug, fix candidates, definition of done).

House rules:
- User-specific values only ever come from `~/.config/agent-browsers/browsers.json`. No owner names,
  emails, IPs, tailnet names, hostnames or account lists in commits; use `192.0.2.x` / `100.64.x.x` /
  `example.com` in docs.
- Machine-facing output is JSON.
- Release tier: small (`v0.<n>` until it works end to end, then `v1.0`, `v1.1`, …).

Lineage (2026-11-15): successor to the owner's private `Agent-Browsers-Plugin` (retired that day). Per-user values
and deployment notes stay out of this repo: they live in the user's `browsers.json` and in the `ops_doc` it points to.
