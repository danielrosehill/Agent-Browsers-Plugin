---
name: drive-browser
description: How to drive an agent browser through a Playwright-style MCP (navigate, snapshot, act by ref) without leaving a mess. For local browsers, reuse what's open, never launch extras, and close everything you opened when done. Use for any web task on an agent browser ("use your browser", "check the page", "log in and look"), after pick-browser.
---

# Drive an agent browser

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. Every script prints JSON.

## Before you start (local browsers)

- **Reuse, don't multiply.** `mcp__<server>__browser_tabs` `{"action":"list"}` first. If a tab is open, work in it
  (or add one tab). Don't open a new isolated context or a second browser for a new task.
- `$PLUGIN/scripts/local-browsers.sh` lists every Playwright-managed browser on this machine with its age and
  owning MCP. Note the PIDs that exist before you start, so you know at the end which ones are yours.

## Driving

**Shared profiles** (lan/vps browsers the user also watches): check `browser_tabs` first and open a new tab rather
than navigating one they have open. Never log out or clear site data: those sessions are theirs.

1. `browser_navigate` → `browser_snapshot` → act by `ref` (`browser_click`, `browser_type`, `browser_fill_form`). Re-snapshot after anything that changes the page.
2. Prefer the snapshot to screenshots. Take a screenshot only when the user wants to see something, or when layout matters.
3. A local browser stays on the agent's desktop and never takes focus. **Don't switch the user's view yourself.** When
   there's something worth seeing, ask; on a yes, follow `show-me`.
4. **Through a gateway** (`mcp_route: "gateway"` in the registry, tools called via the gateway's toolbox): element
   `ref`s and modal state (file choosers) usually don't survive between calls. Click by CSS selector (`browser_click`
   `{"target": "#id"}`), read with `browser_evaluate`, or do a multi-step action in one `browser_run_code_unsafe` call.
   Files to upload must exist on the browser's host, not this machine. See the entry's `ops_doc`.
5. Login wall: check the browser's `login_source` (`registry.py get <id>`). `chrome-cookies`: the user signs in in
   their Chrome and the agent browser picks it up at its next launch. `manual-in-viewer`: give them the viewer URL and wait.

## When done (always, also on failure or a change of plan)

1. Close every tab you opened: `browser_tabs` `close`, then `browser_close` on the last one. With Playwright
   MCP 0.0.85, closing the last tab ends the browser process (confirmed 2026-11-15).
2. Local: `local-browsers.sh` again. Any browser that wasn't there at the start and is still running is a
   leftover: close it through its MCP, or `local-browsers.sh kill <pid>` if its MCP is gone. Leave browsers that predate the task alone.
3. If you switched the user's view (`show-me`), offer to switch back.
4. Exception: the user asked to keep it open. Then say it's still open.
