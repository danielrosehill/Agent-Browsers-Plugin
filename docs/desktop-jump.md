# Open bug: KDE switches the user's view to the agent desktop at browser launch

Status: **open** (reproduced 2026-11-15, KDE Plasma 6, Wayland). Moved from the start-up handover.

With the rule above installed, the window **does** open on the Claude desktop. But KDE **switches the user's view
to Claude** when the Playwright MCP starts a new Firefox. Evidence, from polling
`qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.current` every 100 ms during a
`browser_navigate` that launched a fresh browser:

```
15:43:01.908 <user desktop uuid>
15:43:05.416 <Claude desktop uuid>     <- jump at window launch
15:43:07.242 <user desktop uuid>       <- probably the user switching back by hand
```

So focus-stealing prevention "extreme" alone is not enough. Playwright starts Firefox with `-foreground`, and the
browser asks to be activated. KWin activates the window and follows it to its desktop. An earlier check missed this:
it read the current desktop only *after* launch. **Verify with the 100 ms poller, not a single read.**

Candidates, none tested yet (the owner stopped the first attempt so it could move to this repo):
1. KWin rule `acceptfocus=false` + `acceptfocusrule=2`: the window can never be activated, so there's nothing to
   follow. Cost: the user can't type into it when taking over (the Playwright protocol doesn't need OS focus).
   Maybe toggle it off with a "take over" skill.
2. KWin rule `activity`/`minimizerule`, or the `kwinrc [Windows]` setting that controls what happens when a window
   on another desktop is activated (Plasma 6 "when activating a window on a different virtual desktop"). Neither
   of its options, switch or bring here, is what we want, so probably not.
3. Stop the activation at the source: launch the Playwright browser without `-foreground` (custom executable
   wrapper or launch options in the Playwright MCP config), or run it in a nested/headless compositor and view it
   another way. `kde-agent-workspace` already has a headless-KWin "sandbox" mode on a private bus that may
   solve this for free.
4. A small KWin script (loaded persistently) that on `windowActivated` of class X on the agent desktop
   switches `workspace.currentDesktop` straight back. Last resort; it would flicker.

Done means: the poller shows **no** desktop change across launch, navigation, new tabs and `browser_close` +
relaunch, and the user's focused window stays focused.

## Re-test 2026-11-15 (afternoon): not reproduced

Tooling: `scripts/kde-desktop-watch.sh SECONDS` (100 ms poll of `VirtualDesktopManager.current` plus a temporary
KWin script logging `windowAdded`/`windowActivated` to the user journal; JSON out), and `test/launch-cycle.cjs`
(headed Playwright Firefox: launch, navigate, new tab, close, ×2), run as
`node test/launch-cycle.cjs ~/.npm/_npx/<hash>/node_modules/playwright-core` (the playwright-core inside
`@playwright/mcp@0.0.85`).

Rule state: `[agent-browser-workspace]` installed, `desktops` = the Claude desktop, `fsplevel=4` forced.

| Trial | Fresh Firefox launches | Window landed on | `firefox-default` activations | Desktop changes |
|---|---|---|---|---|
| `launch-cycle.cjs` run 1 | 2 | (not logged yet) | 0 | 0 |
| `launch-cycle.cjs` run 2 | 2 (4 windows) | Claude | 0 | 0 |
| Real MCP: `browser_close`, `browser_navigate`, `browser_tabs new`, `browser_close` | 1 (2 windows) | Claude | 0 | 0 |

Confirmed: in these 5 launches the window was placed on Claude and never activated, and the user's focused window
(Konsole) stayed active. Playwright does pass `-foreground` to headed Firefox
(`playwright-core/lib/coreBundle.js`, `defaultArgs`), but with this rule it caused no activation here.
Not explained: why the morning run jumped. Unconfirmed guesses: the rule was written but KWin had not
reconfigured before that launch, or the browser launched while the user's focus was already moving. Keep the
bug open until it either reproduces (then try the candidates above) or stays clean across several days of normal use.

Side observation: every clipboard read by Claude Code (`wl-paste`) creates and activates a short-lived window
for about 2 ms, then gives focus back to Konsole. Harmless, but the watcher logs it.
