---
name: page-to-pdf
description: Save a web page as a clean PDF (receipt, order confirmation, invoice, booking, article) with headless Chrome, optionally keeping only one element so the site header and footer don't pad it to many pages. Use on "render this as a PDF", "save this page as PDF", "PDF the receipt", "print this order page", or before filing a web-only receipt.
---

# Web page to PDF

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. The script prints JSON.

## 1. Pick the route

- **Page opens without signing in** (most order-received pages carry a key in the URL, e.g. WooCommerce
  `/checkout/order-received/<id>/?key=wc_order_…`): headless, step 2. No visible browser, nothing on the user's desktop.
- **Page needs the user's session:** headless can't see it. Print from the browser that's signed in: in the agent
  browser (`drive-browser`) run `await page.pdf({ path, format: 'A4', printBackground: true })` through its
  run-code tool (Playwright's `page.pdf` works only in headless Chromium; if the agent browser is headed, say so
  and ask the user to use Ctrl+P → Save as PDF). Don't copy cookies out of the user's browser.

## 2. Render

```bash
$PLUGIN/scripts/page-to-pdf.py "<url>" "/tmp/<dir>/<name>.pdf" [--select "<css>"] [--hide "<css>"]
```

- First render without `--select`. A page count far above the content (a one-item receipt at 10+ pages) means the
  site chrome is printing: re-run with `--select` on the content block. Known blocks: WooCommerce `.woocommerce-order`;
  Shopify `.order-summary, .main`; otherwise inspect the page and pick the content container.
- `--hide` for cookie bars, chat bubbles and sticky banners that overlap the content.
- Uses the installed Google Chrome (`--browser chromium` for Playwright's own; first run: `uv run --with playwright playwright install chromium`).

## 3. Check it, then file it

- **Look at it**, don't trust `ok`: `pdftoppm -r 50 -png -f 1 -l 1 out.pdf /tmp/<dir>/prev` and view the image.
  Confirm the order number, items and total are there and nothing important is cut off. `pdftotext` on RTL
  (Hebrew/Arabic) pages scrambles word order, so read the image, not the text.
- Name it `YYYY-MM-DD <Store> order <number> <item> <currency><total>.pdf`.
- Upload where the user keeps receipts (their notes say where; ask once if not). For Google Drive with an `rclone`
  remote: `rclone copyto <file> "<remote>:<name>" --drive-root-folder-id <folder-id>`, then confirm with
  `rclone hashsum sha256` that the Drive copy matches the local `sha256` from step 2.
- Report: where it was saved, and any order facts the user asked for (a tracking number usually isn't on the
  order page until the order ships; check the store's confirmation email and say "none yet" if absent).
