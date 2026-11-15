---
name: setup
description: Set up Claude Agent Browsers on this machine. Writes the user's browser registry (~/.config/claude-agent-browsers/browsers.json), creates the agent's virtual desktop and installs the window rule that keeps the local agent browser there, then checks it. Use on "set up agent browsers", "add a browser to the registry", "configure the agent browser", or when another skill reports "no config".
---

# Set up agent browsers

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. Every script prints JSON.

1. **Config.** `python3 $PLUGIN/scripts/registry.py path`. If it doesn't exist, build it from
   `$PLUGIN/config/browsers.example.json` by asking the user, one browser at a time:
   - `id`, `type` (`local` = on this machine, `lan` = a server on the home network, `vps` = a remote host), `purpose` (one line: when to use it).
   - `mcp_server`: the Claude Code MCP server name that drives it (`claude mcp list` shows the candidates).
   - local: `engine` and `window_class` (Playwright Firefox is `firefox-default`; Playwright Chromium is `chromium` or similar, so check with `$PLUGIN/scripts/kde-desktop-watch.sh` while one launches).
   - lan / vps: `addresses` (`lan`, `tailnet`, `public`, whichever exist), `mcp_url` and `viewer_url` with `{address}` in place of the host.
   - `login_source.kind`: `manual-in-viewer`, `chrome-cookies` (seeded from a Chrome profile at launch) or `none`.
   - `default`: the id to use when nothing else decides. `workspace.desktop_name` (default `Claude`), `workspace.backend` (`kde`; others are not built yet).
   Write it to the path from step 1. It is the user's own file: never copy it into a repo.
2. **Check.** `registry.py list`, then `registry.py resolve <id>` for each lan/vps browser. A browser with `"ok": false` is unreachable from here; say so and keep going.
3. **Agent desktop** (only if there is a `local` browser): `$PLUGIN/scripts/desktop.sh ensure`.
4. **Window rule** (KDE): `$PLUGIN/scripts/kde-browser-workspace.sh install`, then `status`: `installed` true, `class` and `desktop_id` equal to their `expected_` values, `accept_focus` false.
5. **Panel (optional, ask):** keep the agent browser out of the user's panel too: follow the `panel-current-desktop` skill.
6. **Prove it:** run `$PLUGIN/scripts/kde-desktop-watch.sh 20` in the background, launch the local browser
   (its `browser_navigate` to any page), `browser_close`, then read the JSON. Pass = `jumped` false, the
   browser window in `windows_added` on the agent desktop, and no activation of its class. Report pass/fail with that JSON's numbers.
