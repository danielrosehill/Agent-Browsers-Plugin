---
name: deconflict-desktop
description: Install, check, remove or debug the desktop rule that keeps the local agent browser on the agent's own virtual desktop with no focus stealing, and test that launching it never moves the user's view. Use on "the browser jumped to my screen", "it pulled me to the Claude desktop", "the agent browser popped up", "check the window rule", "remove the browser rule".
---

# Keep the agent browser off the user's screen

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. Every script prints JSON. KDE Plasma 6 only for now (`workspace.backend` `kde`).

| Want | Run |
|---|---|
| Install / repair | `$PLUGIN/scripts/kde-browser-workspace.sh install` (desktop and class from browsers.json; idempotent; also moves open agent windows) |
| Check | `kde-browser-workspace.sh status`: `installed` true, `class`/`desktop_id` equal to their `expected_` values, `accept_focus` false |
| User wants to type in it | `kde-browser-workspace.sh takeover on`, later `takeover off` |
| Remove | `kde-browser-workspace.sh remove` |
| Agent desktop missing | `$PLUGIN/scripts/desktop.sh ensure`, then install again (the rule pins the desktop by UUID) |

## Test (do this, don't infer it from `status`)

Run `$PLUGIN/scripts/kde-desktop-watch.sh 25` in the background. Meanwhile: `browser_close`, `browser_navigate` (fresh
launch), `browser_tabs` new, `browser_close`. Pass: `jumped` false, the browser's windows in `windows_added` on the
agent desktop, and no `activations` for its class. Reading the current desktop once after launch is not a test: the
jump can come and go within seconds.

Known issue and history: `$PLUGIN/docs/desktop-jump.md`.
