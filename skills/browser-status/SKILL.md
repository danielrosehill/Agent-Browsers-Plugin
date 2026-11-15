---
name: browser-status
description: Check whether the user's agent browsers are up and reachable (local MCP and process, LAN/VPS MCP and viewer ports), and recover the common failures. Use when browser tools error or vanish, the viewer won't load, after a server restart, or on "is the agent browser up", "browser tools broken", "restart the agent browser".
---

# Agent browser status and recovery

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. Every script prints JSON.

## Check

1. `python3 $PLUGIN/scripts/registry.py list`, then for each browser (or just the one in trouble):
   - **lan / vps:** `registry.py check <id>` → which address answered, `mcp_reachable`, `viewer_reachable`.
   - **local:** `claude mcp get <mcp_server>` (registered and connected?) and `$PLUGIN/scripts/local-browsers.sh` (what's running, how old).
2. **One real call** per browser: `mcp__<mcp_server>__browser_tabs` `{"action":"list"}`. Reachable ports don't prove the
   tools work. A call that answers does.
3. Report a JSON-ish table: id, type, address used, MCP ok, viewer ok, real call ok.

## Fix by symptom

| Symptom | Fix |
|---|---|
| `mcp__<server>__*` tools missing from the session | The server was added or changed after the session started: `/mcp` reconnect, or restart Claude Code. Check `claude mcp list` |
| Local: tool call errors, browser process gone or stuck | `browser_close`, then `browser_navigate` relaunches. A stuck process with no live MCP: `local-browsers.sh kill <pid>` |
| Local: `Executable doesn't exist` after a Playwright MCP upgrade | `npx -y playwright@<version that @playwright/mcp depends on> install firefox` (or chromium) |
| Local: `Error setting storage state` | One bad cookie in the seeded state rejects the whole file. Find it by bisecting with `context.addCookies` and filter it in the cookie-sync tool |
| Local: window lands on the user's desktop, or the view jumps | `deconflict-desktop` |
| lan/vps: no address reachable | Off the LAN and the tailnet is down, or the host is down. Check `tailscale status`, then the host |
| lan/vps: MCP port open, viewer closed (or the reverse) | That one service is down on the host. Recover it per the browser's `ops_doc` |
| lan/vps: logged out of everything | The profile storage was replaced. Check per `ops_doc`. Never delete a profile volume to fix something: it holds the user's sessions |

Server-side recovery (containers, sidecars, restarts) depends on the deployment. Follow the entry's `ops_doc` and don't
guess. No `ops_doc`: report what failed and ask.
