#!/usr/bin/env bash
# Desktop launchers that open a remote agent browser (lan/vps) as a native local window through the Xpra client
# (seamless mode): its own name, icon, coloured border and title prefix, so it looks like a local app.
# One launcher per browser in browsers.json whose "viewer.kind" is "xpra"; address from registry.py resolve.
#
#   xpra-viewers.sh install        # Xpra client if missing (Debian/Ubuntu, xpra.org repo), launchers, icons
#   xpra-viewers.sh status         # JSON per browser: launcher, xpra, viewer reachable
#   xpra-viewers.sh launch <id>    # attach (what the launcher runs)
#   xpra-viewers.sh uninstall      # launchers and icons; the Xpra client stays
#
# viewer fields (all optional except kind): {"kind":"xpra","launcher":"Work Browser (Agent)","title":"Work",
#   "color":"#1565c0","letter":"W","password_command":"<shell command printing the password>"}
# Without password_command, AGENT_BROWSER_VIEWER_PASSWORD from the environment is used, else no password.
set -euo pipefail
src=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
APPS=$DATA/applications; ICONS=$DATA/icons/hicolor/scalable/apps
LIB=$DATA/claude-agent-browsers/bin      # stable copy: the plugin's own path changes with each version
reg() { python3 "$src/registry.py" "$@"; }

viewers() {   # id<TAB>launcher<TAB>title<TAB>color<TAB>letter for every xpra viewer
  python3 - "$src/registry.py" <<'PY'
import json, subprocess, sys
run = lambda *a: json.loads(subprocess.run([sys.executable, sys.argv[1], *a], capture_output=True, text=True).stdout or "{}")
for b in run("list").get("browsers", []):
    v = run("get", b["id"]).get("viewer") or {}
    if v.get("kind") != "xpra": continue
    name = v.get("launcher") or f"{b['id']} (Agent browser)"
    print(b["id"], name, v.get("title") or b["id"], v.get("color") or "#455a64",
          (v.get("letter") or b["id"][:1]).upper()[:1], sep="\t")
PY
}

field() { python3 -c 'import json,sys; d=json.load(sys.stdin); print(eval(sys.argv[1]) or "")' "$1"; }

launch() {
  local id=$1 r url v pw cmd
  r=$(reg resolve "$id") || { echo "$r" >&2; exit 1; }
  url=$(field 'd.get("viewer_url")' <<<"$r")
  [[ $url == tcp://* || $url == ws://* || $url == wss://* || $url == ssl://* ]] || { echo "viewer_url $url is not an xpra URL" >&2; exit 1; }
  v=$(reg get "$id"); cmd=$(field '(d.get("viewer") or {}).get("password_command")' <<<"$v")
  title=$(field '(d.get("viewer") or {}).get("title") or d["id"]' <<<"$v")
  color=$(field '(d.get("viewer") or {}).get("color") or "#455a64"' <<<"$v")
  if [ -n "$cmd" ]; then pw=$(bash -c "$cmd" 2>/dev/null || true); else pw=${AGENT_BROWSER_VIEWER_PASSWORD:-}; fi
  local auth=()
  if [ -n "$pw" ]; then
    local pwf=${XDG_RUNTIME_DIR:-/tmp}/agent-browser-$id.pw
    (umask 077; printf '%s' "$pw" >"$pwf"); auth=(--password-file="$pwf")
  fi
  exec xpra attach "${url%/}/" "${auth[@]}" --title="[$title] @title@" --border="$color,3" \
    --window-icon="$ICONS/agent-browser-$id.svg" --encoding=auto --opengl=auto --tray=no --notifications=no \
    --reconnect=yes --speaker=off --microphone=off --webcam=no --printing=no --file-transfer=no >/dev/null 2>&1
}

ensure_xpra() {
  command -v xpra >/dev/null && return
  command -v apt-get >/dev/null || { echo '{"ok":false,"error":"install the xpra client with your package manager"}'; exit 1; }
  local codename; codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
  sudo curl -fsSL https://xpra.org/xpra.asc -o /usr/share/keyrings/xpra.asc
  sudo curl -fsSL "https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/$codename/xpra.sources" -o /etc/apt/sources.list.d/xpra.sources
  sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq xpra-client xpra-client-gtk3 xpra-codecs xpra-codecs-extras
}

status() {
  local rows=() id name t c l r
  while IFS=$'\t' read -r id name t c l; do
    r=$(reg check "$id" 2>/dev/null || true)
    rows+=("{\"id\":\"$id\",\"launcher\":\"$name\",\"installed\":$([ -f "$APPS/agent-browser-$id.desktop" ] && echo true || echo false),\"viewer_url\":\"$(field 'd.get("viewer_url")' <<<"$r")\",\"reachable\":$(field 'str(bool(d.get("viewer_reachable"))).lower()' <<<"$r")}")
  done < <(viewers)
  printf '{"xpra":%s,"viewers":[%s]}\n' "$(command -v xpra >/dev/null && echo true || echo false)" "$(IFS=,; echo "${rows[*]}")"
}

case ${1:-} in
  install)
    ensure_xpra; mkdir -p "$APPS" "$ICONS" "$LIB"
    install -m 755 "$src/xpra-viewers.sh" "$src/registry.py" "$LIB/"
    while IFS=$'\t' read -r id name t c l; do
      cat >"$ICONS/agent-browser-$id.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="2" y="2" width="60" height="60" rx="14" fill="$c"/><circle cx="50" cy="14" r="7" fill="#ffb300"/><text x="32" y="45" font-family="sans-serif" font-size="34" font-weight="700" fill="#fff" text-anchor="middle">$l</text></svg>
SVG
      cat >"$APPS/agent-browser-$id.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=$name
Comment=Agent browser "$id" as a native window (Xpra)
Exec=$LIB/xpra-viewers.sh launch $id
Icon=agent-browser-$id
Categories=Network;WebBrowser;
Terminal=false
DESK
    done < <(viewers)
    command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" >/dev/null 2>&1 || true
    command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
    status ;;
  uninstall)
    while IFS=$'\t' read -r id _; do rm -f "$APPS/agent-browser-$id.desktop" "$ICONS/agent-browser-$id.svg"; done < <(viewers)
    rm -rf "$LIB"; echo '{"ok":true,"removed":"launchers"}' ;;
  status) status ;;
  launch) launch "${2:?browser id}" ;;
  *) sed -n '2,15p' "$0"; exit 2 ;;
esac
