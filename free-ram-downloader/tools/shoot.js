// node tools/shoot.js <outdir>   screenshots the web preview on phone + desktop
const { chromium } = require("playwright");
const path = require("path");
(async () => {
  const out = process.argv[2] || ".";
  const url = "file://" + path.resolve(__dirname, "../preview/index.html");
  const browser = await chromium.launch();
  const shots = [
    ["phone-home",    { width: 390, height: 844 }, true,  null],
    ["phone-popup",   { width: 390, height: 844 }, false, "popup"],
    ["phone-download",{ width: 390, height: 844 }, false, "dl"],
    ["phone-scan",    { width: 390, height: 844 }, false, "scan"],
    ["desktop-home",  { width: 1280, height: 900 }, false, "popup"],
  ];
  for (const [name, vp, full, mode] of shots) {
    const ctx = await browser.newContext({ viewport: vp, deviceScaleFactor: vp.width < 600 ? 2 : 1, hasTouch: vp.width < 600, isMobile: vp.width < 600 });
    const page = await ctx.newPage();
    const errors = []; page.on("pageerror", e => errors.push(e.message));
    await page.goto(url); await page.waitForTimeout(400);
    if (mode === "popup") await page.waitForTimeout(3200);
    if (mode === "dl") { await page.click("#dlBtn"); await page.waitForTimeout(3500); }
    if (mode === "scan") { await page.click("#scanLink"); await page.waitForTimeout(2600); }
    await page.screenshot({ path: path.join(out, name + ".png"), fullPage: full });
    if (errors.length) console.log(name, "JS ERRORS:", errors);
    await ctx.close();
  }
  await browser.close();
})();
