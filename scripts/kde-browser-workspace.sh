#!/usr/bin/env bash
# Keep the LOCAL agent browser on the agent's KDE virtual desktop and stop it stealing focus.
# Installs one KWin window rule in ~/.config/kwinrulesrc (group "agent-browser-workspace")
# and moves any open agent-browser windows there. Idempotent. JSON out.
#
#   kde-browser-workspace.sh install [DESKTOP_NAME [WINDOW_CLASS]]
#   kde-browser-workspace.sh status
#   kde-browser-workspace.sh remove
#   kde-browser-workspace.sh takeover on|off   # on: the window may take focus so the user can type in it;
#                                              # off (installed state): it can never be activated
#
# Defaults come from browsers.json: desktop = workspace.desktop_name, class = window_class of the first
# "local" browser; without a config, "Claude" and "firefox-default" (Playwright's Firefox build; everyday
# Firefox is "firefox", so the user's own browser is never matched).
set -euo pipefail
here=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)

cfg_defaults() {
  python3 - "$here/registry.py" <<'PY2'
import json, subprocess, sys
def run(*a):
    try: return json.loads(subprocess.run([sys.executable, sys.argv[1], *a], capture_output=True, text=True).stdout)
    except ValueError: return {}
ws = run("workspace"); lst = run("list")
cls = "firefox-default"
for b in lst.get("browsers", []):
    if b.get("type") == "local":
        cls = run("get", b["id"]).get("window_class") or cls; break
print(ws.get("desktop_name", "Claude"), cls, sep="\t")
PY2
}
IFS=$'\t' read -r cfg_desk cfg_class < <(cfg_defaults)

RULE=agent-browser-workspace
RC=kwinrulesrc
cmd=${1:-status}; desk_name=${2:-$cfg_desk}; CLASS=${3:-$cfg_class}

desk_id() {   # UUID of the virtual desktop called $1
  qdbus6 --literal org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.desktops \
    | grep -oP '\(uss\) \d+, "\K[0-9a-f-]{36}(?=", "'"$1"'")' | head -1
}

rules_list() { kreadconfig6 --file $RC --group General --key rules; }

set_rules_list() {
  kwriteconfig6 --file $RC --group General --key rules "$1"
  local n=0; [ -n "$1" ] && n=$(tr ',' '\n' <<<"$1" | grep -c .)
  kwriteconfig6 --file $RC --group General --key count "$n"
}

reconfigure() { qdbus6 org.kde.KWin /KWin reconfigure >/dev/null; }

# Rules only fire when a window opens; move windows that are already open.
move_open() {
  local id=$1 f; f=$(mktemp --suffix=.js)
  cat >"$f" <<JS
var d = workspace.desktops.filter(function (x) { return x.id == "$id"; })[0];
workspace.windowList().forEach(function (w) {
  if (d && w.resourceClass == "$CLASS") { w.desktops = [d]; }
});
JS
  local sid; sid=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$f" "$RULE-move")
  qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.run >/dev/null 2>&1 || true
  sleep 0.3
  qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$RULE-move" >/dev/null || true
  rm -f "$f"
}

case $cmd in
  install)
    id=$(desk_id "$desk_name")
    [ -n "$id" ] || { echo "{\"ok\":false,\"error\":\"no virtual desktop named $desk_name\"}"; exit 1; }
    w() { kwriteconfig6 --file $RC --group $RULE --key "$1" "$2"; }
    w Description "Agent browser ($CLASS) on the $desk_name desktop, no focus stealing"
    w wmclass "$CLASS";  w wmclassmatch 1;  w wmclasscomplete false
    w types 1                       # normal windows
    w desktops "$id";    w desktopsrule 2       # force onto the agent desktop
    w fsplevel 4;        w fsplevelrule 2       # focus stealing prevention: extreme
    w acceptfocus false; w acceptfocusrule 2    # never activated -> KWin has nothing to follow to the agent desktop
    cur=$(rules_list)
    tr ',' '\n' <<<"$cur" | grep -qx "$RULE" || set_rules_list "${cur:+$cur,}$RULE"
    reconfigure; move_open "$id"
    echo "{\"ok\":true,\"rule\":\"$RULE\",\"class\":\"$CLASS\",\"desktop\":\"$desk_name\",\"desktop_id\":\"$id\"}" ;;
  remove)
    kwriteconfig6 --file $RC --group $RULE --key Description --delete >/dev/null 2>&1 || true
    python3 - "$HOME/.config/$RC" "$RULE" <<'PY'
import sys, re
p, g = sys.argv[1], sys.argv[2]
s = open(p).read()
s = re.sub(r'\n\[' + re.escape(g) + r'\]\n(?:[^\[].*\n?)*', '\n', s)
open(p, 'w').write(s)
PY
    set_rules_list "$(rules_list | tr ',' '\n' | grep -vx "$RULE" | paste -sd, -)"
    reconfigure; echo "{\"ok\":true,\"removed\":\"$RULE\"}" ;;
  takeover)
    case ${2:-} in
      on)  kwriteconfig6 --file $RC --group $RULE --key acceptfocus true ;;
      off) kwriteconfig6 --file $RC --group $RULE --key acceptfocus false ;;
      *) echo "usage: $0 takeover on|off" >&2; exit 2 ;;
    esac
    reconfigure; echo "{\"ok\":true,\"takeover\":\"$2\"}" ;;
  status)
    d=$(kreadconfig6 --file $RC --group $RULE --key desktops)
    c=$(kreadconfig6 --file $RC --group $RULE --key wmclass)
    af=$(kreadconfig6 --file $RC --group $RULE --key acceptfocus)
    inl=$(rules_list | tr ',' '\n' | grep -cx "$RULE" || true)
    echo "{\"installed\":$([ "$inl" = 1 ] && [ -n "$d" ] && echo true || echo false),\"desktop_id\":\"$d\",\"class\":\"$c\",\"accept_focus\":${af:-true},\"expected_desktop_id\":\"$(desk_id "$desk_name")\",\"expected_class\":\"$CLASS\"}" ;;
  *) echo "usage: $0 install [DESKTOP [CLASS]]|status|remove|takeover on|off" >&2; exit 2 ;;
esac
