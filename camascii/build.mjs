// Inlines public/ into a single Worker script so deploys need no asset upload.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";

const files = {
  "/": ["index.html", "text/html; charset=utf-8"],
  "/app.js": ["app.js", "text/javascript; charset=utf-8"],
};
const routes = Object.fromEntries(
  Object.entries(files).map(([path, [file, type]]) => [path, { type, body: readFileSync(new URL(`public/${file}`, import.meta.url), "utf8") }])
);

mkdirSync(new URL("dist/", import.meta.url), { recursive: true });
writeFileSync(new URL("dist/worker.js", import.meta.url), `const ROUTES = ${JSON.stringify(routes)};
const HEADERS = {
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer",
  "permissions-policy": "camera=(self)",
  "cache-control": "public, max-age=300",
};
export default {
  fetch(request) {
    const { pathname } = new URL(request.url);
    const hit = ROUTES[pathname] || ROUTES[pathname.replace(/\\/index\\.html$/, "/")];
    if (!hit) return new Response("not found", { status: 404 });
    return new Response(hit.body, { headers: { ...HEADERS, "content-type": hit.type } });
  },
};
`);
console.log("built dist/worker.js");
