#!/usr/bin/env python3
"""Read the agent-browser registry (~/.config/claude-agent-browsers/browsers.json). Stdlib only. JSON out.

  registry.py path                 # where the config is, and whether it exists
  registry.py list                 # every browser, summarised
  registry.py get <id>             # one browser's full entry
  registry.py resolve [<id>]       # pick the first reachable address (lan, then tailnet, then public),
                                   # fill {address} in mcp_url / viewer_url. No id: the "default" browser.
  registry.py workspace            # the workspace block (desktop_name, backend) with defaults applied

Override the config path with CLAUDE_AGENT_BROWSERS_CONFIG.
"""
import json, os, socket, sys
from urllib.parse import urlparse

CFG = os.environ.get("CLAUDE_AGENT_BROWSERS_CONFIG") or os.path.join(
    os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "claude-agent-browsers", "browsers.json")
ORDER = ["lan", "tailnet", "public"]
WS_DEFAULTS = {"desktop_name": "Claude", "backend": "kde"}


def out(o, code=0):
    print(json.dumps(o, indent=None)); sys.exit(code)


def load():
    if not os.path.exists(CFG):
        out({"ok": False, "error": "no config", "path": CFG,
             "hint": "run the setup skill, or copy config/browsers.example.json there"}, 1)
    with open(CFG) as f:
        return json.load(f)


def find(cfg, bid):
    bid = bid or cfg.get("default")
    for b in cfg.get("browsers", []):
        if b.get("id") == bid:
            return b
    out({"ok": False, "error": f"no browser with id {bid!r}", "ids": [b.get("id") for b in cfg.get("browsers", [])]}, 1)


def reachable(host, port, timeout=1.0):
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False


def resolve(b):
    r = {"ok": True, "id": b["id"], "type": b.get("type"), "mcp_server": b.get("mcp_server")}
    if b.get("type") == "local":
        r.update(address=None, via="local", window_class=b.get("window_class"))
        return r
    addrs = b.get("addresses", {})
    order = b.get("address_order") or ORDER
    tmpl = b.get("mcp_url") or b.get("viewer_url") or ""
    tried = []
    for kind in order:
        a = addrs.get(kind)
        if not a:
            continue
        u = urlparse(tmpl.replace("{address}", a)) if tmpl else None
        port = (u.port or (443 if u.scheme == "https" else 80)) if u else None
        ok = reachable(a, port) if port else None
        tried.append({"via": kind, "address": a, "port": port, "reachable": ok})
        if ok or port is None:
            r.update(address=a, via=kind)
            break
    else:
        r.update(ok=False, error="no address reachable", address=None, via=None)
    for k in ("mcp_url", "viewer_url"):
        if b.get(k):
            r[k] = b[k].replace("{address}", r["address"]) if r.get("address") else None
    r["tried"] = tried
    return r


def main(argv):
    cmd = argv[0] if argv else "list"
    if cmd == "path":
        out({"path": CFG, "exists": os.path.exists(CFG)})
    cfg = load()
    if cmd == "list":
        out({"default": cfg.get("default"), "browsers": [
            {k: b.get(k) for k in ("id", "type", "purpose", "engine", "mcp_server", "login_source")}
            for b in cfg.get("browsers", [])]})
    if cmd == "get":
        out(find(cfg, argv[1] if len(argv) > 1 else None))
    if cmd == "resolve":
        r = resolve(find(cfg, argv[1] if len(argv) > 1 else None))
        out(r, 0 if r["ok"] else 1)
    if cmd == "workspace":
        out({**WS_DEFAULTS, **cfg.get("workspace", {})})
    out({"ok": False, "error": f"unknown command {cmd!r}", "usage": __doc__.strip().splitlines()[2:8]}, 2)


if __name__ == "__main__":
    main(sys.argv[1:])
