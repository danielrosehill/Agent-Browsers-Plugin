#!/usr/bin/env -S uv run -q --script
# /// script
# dependencies = ["playwright"]
# ///
"""Render a web page (or one element of it) to a clean A4 PDF with headless Chrome.

Usage: page-to-pdf.py URL OUT.pdf [--select CSS] [--hide CSS ...] [--browser chrome|chromium] [--wait MS]
--select keeps only that element (e.g. an order-confirmation block), dropping site header/footer.
--hide removes matching elements (cookie bars, chat widgets). Prints JSON.
"""
import argparse, hashlib, json, os, sys
from playwright.sync_api import sync_playwright

ap = argparse.ArgumentParser()
ap.add_argument("url"); ap.add_argument("out")
ap.add_argument("--select"); ap.add_argument("--hide", action="append", default=[])
ap.add_argument("--browser", default="chrome", help="'chrome' = installed Google Chrome, 'chromium' = Playwright's")
ap.add_argument("--wait", type=int, default=1500, help="extra ms after network idle")
a = ap.parse_args()

res = {"ok": False, "url": a.url, "out": os.path.abspath(a.out)}
try:
    with sync_playwright() as p:
        kw = {"channel": "chrome"} if a.browser == "chrome" else {}
        b = p.chromium.launch(**kw)
        pg = b.new_page(locale="he-IL" if ".il/" in a.url else None)
        pg.goto(a.url, wait_until="networkidle", timeout=60000)
        pg.wait_for_timeout(a.wait)
        res["title"] = pg.title()
        for h in a.hide:
            pg.evaluate("s => document.querySelectorAll(s).forEach(e => e.remove())", h)
        if a.select:
            n = pg.evaluate("""s => { const el = document.querySelector(s); if (!el) return 0;
                document.body.innerHTML = ''; document.body.appendChild(el); return 1; }""", a.select)
            if not n:
                raise SystemExit(json.dumps({**res, "error": f"selector not found: {a.select}"}))
        pg.emulate_media(media="print")
        pg.pdf(path=a.out, format="A4", print_background=True,
               margin={"top": "12mm", "bottom": "12mm", "left": "10mm", "right": "10mm"})
        b.close()
    data = open(a.out, "rb").read()
    res.update(ok=True, bytes=len(data), pages=data.count(b"/Type /Page") - data.count(b"/Type /Pages"),
               sha256=hashlib.sha256(data).hexdigest())
except SystemExit as e:
    print(e.code); sys.exit(1)
except Exception as e:
    res["error"] = str(e); print(json.dumps(res, ensure_ascii=False)); sys.exit(1)
print(json.dumps(res, ensure_ascii=False))
