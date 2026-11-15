#!/usr/bin/env bash
# List agent-browser processes running on THIS machine (Playwright-managed Firefox/Chromium/WebKit,
# i.e. binaries under ~/.cache/ms-playwright), with age and the MCP server that owns them. JSON out.
# Use before launching (reuse instead of opening another) and after a task (nothing of yours left open).
#
#   local-browsers.sh            # list
#   local-browsers.sh kill PID   # stop one leftover browser (only Playwright-managed PIDs are accepted)
set -euo pipefail
root=${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}
list() {
  ps -eo pid=,ppid=,etimes=,args= | awk -v r="$root" '
    index($0, r) && $4 ~ /(firefox|chrome|pw_run|MiniBrowser)$/ && $0 !~ /-contentproc|--type=/ { print }' |
  python3 -c '
import json, sys, subprocess
rows = []
for l in sys.stdin:
    pid, ppid, age, exe, *rest = l.split()
    args = " ".join(rest)
    owner = ""
    p = ppid
    for _ in range(4):   # walk up to the npm/node MCP process
        try:
            a = open(f"/proc/{p}/cmdline").read().replace("\0", " ")
            if "@playwright/mcp" in a or "playwright-mcp" in a:
                owner = a.strip()[:200]; break
            p = open(f"/proc/{p}/stat").read().split(") ")[1].split()[1]
        except OSError:
            break
    rows.append({"pid": int(pid), "age_s": int(age), "exe": exe.split("/ms-playwright/")[-1],
                 "headless": "-headless" in args or "--headless" in args, "mcp": owner or None})
print(json.dumps({"count": len(rows), "browsers": rows}))'
}
case ${1:-list} in
  list) list ;;
  kill)
    pid=${2:?pid}; exe=$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)
    [[ $exe == "$root"/* ]] || { echo "{\"ok\":false,\"error\":\"$pid is not a Playwright-managed browser\"}"; exit 1; }
    kill "$pid"; echo "{\"ok\":true,\"killed\":$pid}" ;;
  *) echo "usage: $0 [list|kill PID]" >&2; exit 2 ;;
esac
