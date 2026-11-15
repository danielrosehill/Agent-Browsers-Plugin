#!/usr/bin/env bash
# KDE Plasma 6: make every panel task manager show only windows on the CURRENT virtual desktop, so the agent's
# browser (on its own desktop) doesn't appear in the user's panel. GUI equivalent: right-click the task
# manager > Configure > Behavior > "Show only tasks: From current desktop". Applies live through the
# plasmashell scripting D-Bus API (no restart). JSON out.
#
#   kde-panel-current-desktop.sh status
#   kde-panel-current-desktop.sh on    # only current desktop
#   kde-panel-current-desktop.sh off   # all desktops (Plasma's default)
set -euo pipefail
cmd=${1:-status}
case $cmd in
  on) val=true ;; off) val=false ;; status) val= ;;
  *) echo "usage: $0 status|on|off" >&2; exit 2 ;;
esac
js='
var val = "'"$val"'", out = [];
panels().forEach(function (p) { p.widgets().forEach(function (w) {
  if (!/org\.kde\.plasma\.(icontasks|taskmanager)$/.test(w.type)) return;
  w.currentConfigGroup = ["General"];
  if (val) { w.writeConfig("showOnlyCurrentDesktop", val == "true"); w.reloadConfig(); }
  var v = w.readConfig("showOnlyCurrentDesktop", "unset");
  out.push("{\"panel\":" + p.id + ",\"widget\":" + w.id + ",\"type\":\"" + w.type +
           "\",\"showOnlyCurrentDesktop\":" + (v === "unset" ? "null" : String(v)) + "}");
}); });
print("[" + out.join(",") + "]");'
res=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$js")
printf '{"ok":true,"action":"%s","task_managers":%s}\n' "$cmd" "$res"
