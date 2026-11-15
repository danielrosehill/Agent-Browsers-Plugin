// Reproduce what the Playwright MCP does to the desktop: headed Firefox launch, navigate, new tab, close,
// relaunch. Usage: node test/launch-cycle.cjs <path-to-playwright-core> [executablePath]
const pw = require(process.argv[2]);
const exe = process.argv[3] || undefined;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
(async () => {
  for (let round = 0; round < 2; round++) {
    const b = await pw.firefox.launch({ headless: false, executablePath: exe });
    const ctx = await b.newContext();
    const p = await ctx.newPage();
    await p.goto('data:text/html,<h1>agent browser test</h1>');
    await sleep(1500);
    const p2 = await ctx.newPage();
    await p2.goto('data:text/html,<h1>tab 2</h1>');
    await sleep(1500);
    await b.close();
    await sleep(1000);
  }
  console.log(JSON.stringify({ ok: true }));
})().catch((e) => { console.error(e); process.exit(1); });
