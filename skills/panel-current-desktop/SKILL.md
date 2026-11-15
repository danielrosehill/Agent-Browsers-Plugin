---
name: panel-current-desktop
description: Stop the user's KDE panel (task manager) from showing windows from other virtual desktops, so the agent's browser on its own desktop doesn't appear in their panel. Or undo it. Use on "I don't want to see the agent's windows in my panel", "hide other desktops' windows from the taskbar", "only show this desktop's windows", "show all desktops in the taskbar again".
---

# Panel: current desktop's windows only

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. The script prints JSON.

KDE Plasma 6. It's a per-widget setting, the same as right-click task manager > Configure > Behavior >
"Show only tasks: From current desktop". The script applies it to every task manager on every panel, live, through
plasmashell's scripting D-Bus API, and Plasma saves it to `~/.config/plasma-org.kde.plasma.desktop-appletsrc`.
Plasma's default is to show all desktops.

1. `$PLUGIN/scripts/kde-panel-current-desktop.sh status`: one entry per task manager. `null` means not set, which is
   Plasma's default (all desktops).
2. `kde-panel-current-desktop.sh on`. Check every entry now reads `true`. An empty list means no task manager widget
   was found (the panel uses something else, or plasmashell isn't running): say so and point to the GUI setting.
3. Ask the user to confirm the agent's windows are gone from their panel. The config value alone doesn't prove the panel
   redrew.
4. Undo: `kde-panel-current-desktop.sh off`.

Side effect to mention: the user's own windows on other desktops disappear from the panel too. Alt+Tab and the
desktop overview still reach them.
