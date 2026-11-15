---
name: install-viewers
description: Install (or remove) desktop launchers that open the user's remote agent browsers (LAN server or VPS, served over Xpra) as native local windows, each with its own name, icon, coloured border and title prefix. Installs the Xpra client if missing. Run once per desktop or laptop. Use on "install the browser launchers", "set up the viewer here", "add the agent browser apps", "install xpra for the agent browsers", or when a viewer launcher is missing.
---

# Install the viewer launchers

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. The script prints JSON.

One launcher per browser in `browsers.json` with `"viewer": {"kind": "xpra", ...}`, and `viewer_url` like
`tcp://{address}:<port>`. Optional `viewer` fields: `launcher` (app name), `title` (window-title prefix), `color`
(border and icon), `letter` (icon), `password_command` (a shell command that prints the viewer password, e.g. from
the user's secret manager; never write the password itself into the config).

1. `$PLUGIN/scripts/xpra-viewers.sh install`: installs the Xpra client if missing (Debian/Ubuntu: the xpra.org apt
   repo, because some Ubuntu releases don't ship it; uses sudo), then copies the launcher script and `registry.py` to
   `~/.local/share/claude-agent-browsers/bin/` (a stable path across plugin updates) and writes
   `~/.local/share/applications/agent-browser-<id>.desktop` and an icon.
2. Check: every viewer shows `installed` and `reachable` true. `reachable` false: off the network the address needs
   (usually the tailnet), or the browser host is down. Run `browser-status`.
3. Check auth without opening a window on the user's screen: write the password to a 0600 temp file, run
   `xpra info <viewer_url> --password-file=<file>`, expect exit 0 and a `display.` line, then delete the file.
   Don't print the password.
4. Rerun `install` after changing a viewer in `browsers.json`. Remove: `xpra-viewers.sh uninstall` (leaves the Xpra client).

The address is resolved on every launch, so a laptop moving between the LAN and the tailnet keeps working.
