#!/usr/bin/env bash
# Desktop backend seam: move the USER's view to/from the agent's virtual desktop, on request only.
# Backend and desktop name come from browsers.json "workspace" (defaults: kde, "Claude"). JSON out.
#
#   desktop.sh current    # {"backend":..,"current":{"id":..,"name":..},"agent":{"id":..,"name":..},"on_agent":bool}
#   desktop.sh ensure     # create the agent desktop if missing
#   desktop.sh show       # remember where the user is, switch their view to the agent desktop
#   desktop.sh back       # switch back to where they were before `show`
#
# Implemented: kde (Plasma 6, X11 or Wayland). gnome / hyprland / sway: not yet (exit 3).
set -euo pipefail
here=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
ws=$(python3 "$here/registry.py" workspace 2>/dev/null || true)   # no config yet: defaults
IFS=$'\t' read -r backend name < <(python3 -c '
import json, sys
try: w = json.loads(sys.argv[1]); w = w if "backend" in w else {}
except ValueError: w = {}
print(w.get("backend", "kde"), w.get("desktop_name", "Claude"), sep="\t")' "$ws")
state=${XDG_RUNTIME_DIR:-/tmp}/claude-agent-browsers; mkdir -p "$state"
cmd=${1:-current}

die() { printf '{"ok":false,"backend":"%s","error":"%s"}\n' "$backend" "$1"; exit "${2:-1}"; }

case $backend in
  kde)
    VDM=(qdbus6 org.kde.KWin /VirtualDesktopManager)
    desks() { qdbus6 --literal org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.desktops \
      | grep -oP '\(uss\) \d+, "[0-9a-f-]{36}", "[^"]*"' | sed -E 's/\(uss\) ([0-9]+), "([^"]+)", "(.*)"/\1\t\2\t\3/'; }
    id_of()   { desks | awk -F'\t' -v n="$1" '$3==n{print $2; exit}'; }
    name_of() { desks | awk -F'\t' -v i="$1" '$2==i{print $3; exit}'; }
    cur()     { "${VDM[@]}" org.kde.KWin.VirtualDesktopManager.current; }
    go()      { "${VDM[@]}" org.freedesktop.DBus.Properties.Set org.kde.KWin.VirtualDesktopManager current "$1" >/dev/null; }
    create()  { "${VDM[@]}" org.kde.KWin.VirtualDesktopManager.createDesktop "$(desks | wc -l)" "$1" >/dev/null; }
    ;;
  gnome|hyprland|sway) die "backend $backend not implemented yet" 3 ;;
  *) die "unknown backend $backend" 2 ;;
esac

report() {
  local c a; c=$(cur); a=$(id_of "$name")
  printf '{"ok":true,"backend":"%s","action":"%s","current":{"id":"%s","name":"%s"},"agent":{"id":"%s","name":"%s"},"on_agent":%s}\n' \
    "$backend" "$1" "$c" "$(name_of "$c")" "$a" "$name" "$([ -n "$a" ] && [ "$c" = "$a" ] && echo true || echo false)"
}

case $cmd in
  current) report current ;;
  ensure)  [ -n "$(id_of "$name")" ] || create "$name"; [ -n "$(id_of "$name")" ] || die "could not create desktop $name"; report ensure ;;
  show)
    a=$(id_of "$name"); [ -n "$a" ] || die "no desktop named $name (run: desktop.sh ensure)"
    c=$(cur); [ "$c" = "$a" ] || echo "$c" >"$state/previous-desktop"
    go "$a"; report show ;;
  back)
    p=$(cat "$state/previous-desktop" 2>/dev/null || true); [ -n "$p" ] || die "no previous desktop recorded"
    [ -n "$(name_of "$p")" ] || die "previous desktop $p no longer exists"
    go "$p"; rm -f "$state/previous-desktop"; report back ;;
  *) echo "usage: $0 current|ensure|show|back" >&2; exit 2 ;;
esac
