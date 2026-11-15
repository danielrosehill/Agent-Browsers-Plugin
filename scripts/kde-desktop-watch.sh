#!/usr/bin/env bash
# Watch for the agent browser pulling the user's view (KDE Plasma 6).
# Polls VirtualDesktopManager.current every 100 ms and logs KWin window-activation events
# (via a temporary KWin script printing to the journal) for SECONDS seconds, then prints JSON:
#   {"start_desktop":..,"desktop_changes":[{"t":..,"desktop":..}],"windows_added":[..],"activations":[{"t":..,"class":..,"caption":..}],"jumped":bool}
#   kde-desktop-watch.sh SECONDS
set -euo pipefail
secs=${1:-15}
tag="cab-watch-$$"
js=$(mktemp --suffix=.js); out=$(mktemp)
cat >"$js" <<JS
workspace.windowActivated.connect(function (w) {
  if (w) print("$tag act " + Date.now() + " " + w.resourceClass + " " + w.caption);
});
workspace.windowAdded.connect(function (w) {
  if (w && w.normalWindow) print("$tag add " + Date.now() + " " + w.resourceClass + " " +
    w.desktops.map(function (d) { return d.name; }).join("+") + " " + w.caption);
});
JS
since=$(date '+%Y-%m-%d %H:%M:%S')
sid=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$js" "$tag")
qdbus6 org.kde.KWin "/Scripting/Script$sid" org.kde.kwin.Script.run >/dev/null
cur() { qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.current; }
start=$(cur); last=$start
end=$(( $(date +%s%3N) + secs*1000 ))
while (( $(date +%s%3N) < end )); do
  c=$(cur); if [[ $c != "$last" ]]; then echo "$(date +%s%3N) $c" >>"$out"; last=$c; fi
  sleep 0.1
done
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$tag" >/dev/null || true
journalctl --user --since "$since" -o cat 2>/dev/null | grep -a "$tag act" | sed "s/^.*$tag act //" >"$out.act" || true
journalctl --user --since "$since" -o cat 2>/dev/null | grep -a "$tag add" | sed "s/^.*$tag add //" >"$out.add" || true
python3 - "$start" "$out" "$out.act" "$out.add" <<'PY'
import json, sys
start, f, a, ad = sys.argv[1:]
ch = [dict(zip(("t", "desktop"), l.split())) for l in open(f) if l.strip()]
acts = []
for l in open(a):
    p = l.rstrip("\n").split(" ", 2) + ["", ""]
    acts.append({"t": p[0], "class": p[1], "caption": p[2]})
added = []
for l in open(ad):
    p = l.rstrip("\n").split(" ", 3) + ["", "", ""]
    added.append({"t": p[0], "class": p[1], "desktops": p[2], "caption": p[3]})
print(json.dumps({"start_desktop": start, "desktop_changes": ch, "windows_added": added, "activations": acts, "jumped": bool(ch)}))
PY
rm -f "$js" "$out" "$out.act" "$out.add"
