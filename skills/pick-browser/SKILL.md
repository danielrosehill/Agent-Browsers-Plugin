---
name: pick-browser
description: Choose which of the user's agent browsers (local, LAN server or VPS) to use for a web task and resolve how to reach it right now (LAN, else tailnet, else public address). Use before any browser task when more than one agent browser is configured, or on "which browser should you use", "use the server browser", "use the local browser".
---

# Pick an agent browser

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. Every script prints JSON.

1. `python3 $PLUGIN/scripts/registry.py list`. No config: run the `setup` skill.
2. Choose by the task, using each entry's `purpose` first and these defaults second:
   - **local**: the user may want to watch it, localhost / dev servers, quick public pages. It dies when the machine sleeps.
   - **lan**: needs a persistent logged-in profile, should keep running when the laptop sleeps, needs home egress.
   - **vps**: non-home egress, always-on public work.
   - The user named a browser: use it. Nothing decides it: `default`.
3. `registry.py resolve <id>`. `ok` false = unreachable from here: say so and offer the next-best browser rather than failing.
4. Use its `mcp_server` tools (`mcp__<mcp_server>__browser_*`, or via the user's MCP gateway if it isn't a direct server). If you give the user a viewer link, use the resolved `viewer_url`.
5. Then follow `drive-browser`.
