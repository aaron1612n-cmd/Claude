// node tools/render-logo.js  ->  writes the 1024 app icon + 512 in-app logo (+ preview copy)
const { chromium } = require("playwright");
const { execFileSync } = require("child_process");
const path = require("path");
const fs = require("fs");
(async () => {
  const root = path.resolve(__dirname, "..");
  const raw = path.join(require("os").tmpdir(), "free-ram-logo-256.png");
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 256, height: 256 }, deviceScaleFactor: 1 });
  await page.goto("file://" + path.join(root, "tools/logo.html"));
  await page.waitForTimeout(200);
  await page.locator("#logo").screenshot({ path: raw });
  await browser.close();
  const pix = path.join(__dirname, "pixelate.py");
  const icon = path.join(root, "FreeRAMDownloader/Assets.xcassets/AppIcon.appiconset/icon-1024.png");
  const logo = path.join(root, "FreeRAMDownloader/Assets.xcassets/Logo.imageset/logo.png");
  execFileSync("python3", ["-I", pix, raw, icon, "1024"]);
  execFileSync("python3", ["-I", pix, raw, logo, "512"]);
  fs.copyFileSync(logo, path.join(root, "preview/logo.png"));
})();
