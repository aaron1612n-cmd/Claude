(() => {
  "use strict";

  const RAMPS = [
    { id: "classic", label: " .:-=+*#%@", chars: " .:-=+*#%@" },
    { id: "fine", label: " .'`^\",:;Il!i", chars: " .'`^\",:;Il!i><~+_-?][}{1)(|\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$" },
    { id: "block", label: " ░▒▓█", chars: " ░▒▓█" },
    { id: "bits", label: " 01", chars: "  0011" },
  ];
  const INKS = [
    { id: "paper", label: "paper", bg: "#ece6d8", fg: "#1b1a17" },
    { id: "safelight", label: "safelight", bg: "#120b09", fg: "#e2412b" },
    { id: "colour", label: "colour", bg: "#0e0d0b", fg: null },
  ];
  const CELL_RATIO = 0.6; // glyph width / line height for the mono face

  const $ = (id) => document.getElementById(id);
  const out = $("out"), ctx = out.getContext("2d");
  const video = $("cam");
  const finder = $("finder");
  const sample = document.createElement("canvas");
  const sctx = sample.getContext("2d", { willReadFrequently: true });
  const idle = document.createElement("canvas");
  const ictx = idle.getContext("2d");

  const isTouch = matchMedia("(pointer: coarse)").matches || "ontouchstart" in window;
  document.body.classList.toggle("touch", isTouch);

  const state = {
    grain: isTouch ? 72 : 120,
    ramp: 0,
    ink: 0,
    contrast: 1.2,
    bright: 0,
    invert: false,
    mirror: true,
    hold: false,
    live: false,
    stream: null,
    facing: "user",
    torch: false,
    shots: [],
    viewing: -1,
    lastText: "",
  };

  // ---------- controls ----------
  const rampsEl = $("ramps"), inksEl = $("inks");
  RAMPS.forEach((r, i) => {
    const b = document.createElement("button");
    const lbl = r.label.trim(); b.type = "button"; b.textContent = lbl.length > 10 ? lbl.slice(0, 10) + "…" : lbl;
    b.setAttribute("aria-label", r.id);
    b.onclick = () => setRamp(i);
    rampsEl.appendChild(b);
  });
  INKS.forEach((k, i) => {
    const b = document.createElement("button");
    b.type = "button"; b.textContent = k.label;
    b.onclick = () => setInk(i);
    inksEl.appendChild(b);
  });

  function syncUI() {
    [...rampsEl.children].forEach((b, i) => b.setAttribute("aria-pressed", i === state.ramp));
    [...inksEl.children].forEach((b, i) => b.setAttribute("aria-pressed", i === state.ink));
    $("grain").value = state.grain; $("grainVal").textContent = state.grain;
    $("contrast").value = state.contrast; $("contrastVal").textContent = (+state.contrast).toFixed(2).replace(/0$/, "");
    $("bright").value = state.bright; $("brightVal").textContent = (state.bright > 0 ? "+" : "") + (+state.bright).toFixed(2).replace(/\.?0+$/, "");
    $("invert").setAttribute("aria-pressed", state.invert);
    $("mirror").setAttribute("aria-pressed", state.mirror);
    $("freeze").setAttribute("aria-pressed", state.hold);
    $("torch").setAttribute("aria-pressed", !!state.torch); $("torchM").setAttribute("aria-pressed", !!state.torch);
    $("torch").disabled = $("torchM").disabled = !state.live;
    $("rampCycle").textContent = RAMPS[state.ramp].chars.trim().slice(-2);
    const live = state.live;
    $("shutter").disabled = !live; $("shutterM").disabled = !live;
    $("rec").textContent = live ? (state.hold ? "■" : "●") : "○";
    $("edgeBL").lastChild.textContent = live ? (state.hold ? " held" : " live") : " standby";
    try { localStorage.setItem("camascii", JSON.stringify({ grain: state.grain, ramp: state.ramp, ink: state.ink, contrast: state.contrast, bright: state.bright, invert: state.invert, mirror: state.mirror })); } catch (e) {}
  }
  try {
    const saved = JSON.parse(localStorage.getItem("camascii") || "null");
    if (saved) Object.assign(state, saved);
  } catch (e) {}

  const setRamp = (i) => { state.ramp = (i + RAMPS.length) % RAMPS.length; syncUI(); };
  const setInk = (i) => { state.ink = (i + INKS.length) % INKS.length; syncUI(); };
  const setGrain = (g) => { state.grain = Math.max(40, Math.min(240, Math.round(g / 2) * 2)); syncUI(); };

  $("grain").oninput = (e) => setGrain(+e.target.value);
  $("contrast").oninput = (e) => { state.contrast = +e.target.value; syncUI(); };
  $("bright").oninput = (e) => { state.bright = +e.target.value; syncUI(); };
  $("invert").onclick = () => { state.invert = !state.invert; syncUI(); };
  $("mirror").onclick = () => { state.mirror = !state.mirror; syncUI(); };
  $("freeze").onclick = () => { state.hold = !state.hold; syncUI(); };
  $("rampCycle").onclick = () => setRamp(state.ramp + 1);
  $("tune").onclick = () => {
    const open = $("controls").classList.toggle("open");
    $("tune").setAttribute("aria-pressed", open);
  };
  finder.addEventListener("click", () => {
    if ($("controls").classList.contains("open")) { $("controls").classList.remove("open"); $("tune").setAttribute("aria-pressed", "false"); }
  });

  // wheel + pinch change grain
  finder.addEventListener("wheel", (e) => { e.preventDefault(); setGrain(state.grain + (e.deltaY > 0 ? -4 : 4)); }, { passive: false });
  const touches = new Map(); let pinch0 = 0, grain0 = 0;
  finder.addEventListener("pointerdown", (e) => { touches.set(e.pointerId, e); if (touches.size === 2) { pinch0 = spread(); grain0 = state.grain; } });
  finder.addEventListener("pointermove", (e) => {
    if (!touches.has(e.pointerId)) return; touches.set(e.pointerId, e);
    if (touches.size === 2 && pinch0) setGrain(grain0 * pinch0 / spread());
  });
  const lift = (e) => { touches.delete(e.pointerId); if (touches.size < 2) pinch0 = 0; };
  finder.addEventListener("pointerup", lift); finder.addEventListener("pointercancel", lift);
  function spread() { const [a, b] = [...touches.values()]; return Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY) || 1; }

  // keyboard
  addEventListener("keydown", (e) => {
    if (e.target.tagName === "INPUT" && e.key !== " ") return;
    if (!$("viewer").hidden) {
      if (e.key === "Escape") closeViewer();
      if (e.key === "ArrowLeft") step(-1);
      if (e.key === "ArrowRight") step(1);
      return;
    }
    const k = e.key.toLowerCase();
    if (k === " ") { e.preventDefault(); if (state.live) expose(); else start(); }
    else if (k === "[") setGrain(state.grain - 6);
    else if (k === "]") setGrain(state.grain + 6);
    else if (k === "r") setRamp(state.ramp + (e.shiftKey ? -1 : 1));
    else if (k === "i") setInk(state.ink + (e.shiftKey ? -1 : 1));
    else if (k === "v") $("invert").click();
    else if (k === "m") $("mirror").click();
    else if (k === "f") $("freeze").click();
    else if (k === "l") toggleTorch();
  });

  // ---------- camera ----------
  let cameras = 0;
  async function start() {
    const msg = $("gateMsg");
    if (!navigator.mediaDevices?.getUserMedia) { msg.textContent = "This browser has no camera access. Try over https in a current browser."; return; }
    try {
      if (state.stream) state.stream.getTracks().forEach((t) => t.stop());
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: state.facing, width: { ideal: 1280 }, height: { ideal: 720 } }, audio: false,
      });
      state.stream = stream;
      video.srcObject = stream;
      await video.play().catch(() => {});
      state.live = true; state.hold = false;
      $("gate").hidden = true;
      try {
        cameras = (await navigator.mediaDevices.enumerateDevices()).filter((d) => d.kind === "videoinput").length;
      } catch (e) {}
      $("flip").hidden = $("flipM").hidden = cameras < 2;
      if (state.torch && !(await applyTorch(true))) state.torch = false;
      syncUI();
    } catch (err) {
      msg.textContent = err && err.name === "NotAllowedError"
        ? "Camera blocked. Allow it in the address bar, then try again."
        : "No camera found.";
      $("open").textContent = "Try again";
    }
  }
  $("open").onclick = start;
  const flip = () => { state.facing = state.facing === "user" ? "environment" : "user"; state.mirror = state.facing === "user"; start(); };
  $("flip").onclick = flip; $("flipM").onclick = flip;

  // ---------- flashlight ----------
  async function applyTorch(on) {
    const track = state.stream && state.stream.getVideoTracks()[0];
    if (!track) return false;
    // some phones only report torch once frames are flowing
    for (let i = 0; i < 5; i++) {
      const caps = track.getCapabilities ? track.getCapabilities() : {};
      if (caps.torch) {
        try { await track.applyConstraints({ advanced: [{ torch: on }] }); return true; } catch (e) { return false; }
      }
      await new Promise((r) => setTimeout(r, 150));
    }
    return false;
  }
  let noteTimer = 0;
  function note(text) {
    const el = $("edgeTL");
    el.textContent = text; el.classList.add("warn");
    clearTimeout(noteTimer);
    noteTimer = setTimeout(() => { el.textContent = "camascii"; el.classList.remove("warn"); }, 2200);
  }
  async function toggleTorch() {
    if (!state.live) return;
    const on = !state.torch;
    if (on && state.facing === "user" && cameras > 1) {
      // the flash sits beside the rear lens
      state.facing = "environment"; state.mirror = false; state.torch = true;
      await start();
      if (!state.torch) note("no flashlight");
      return;
    }
    if (await applyTorch(on)) state.torch = on;
    else { state.torch = false; if (on) note("no flashlight"); }
    syncUI();
  }
  $("torch").onclick = toggleTorch; $("torchM").onclick = toggleTorch;

  // ---------- render ----------
  let W = 0, H = 0, dpr = 1, cols = 0, rows = 0, cellW = 0, cellH = 0, fontPx = 0, glyphW = 0.6;
  function measureGlyph() {
    ctx.font = `100px "DM Mono", ui-monospace, monospace`;
    glyphW = ctx.measureText("M").width / 100 || 0.6;
  }
  function layout() {
    const r = finder.getBoundingClientRect();
    dpr = Math.min(devicePixelRatio || 1, 2);
    W = Math.max(1, Math.round(r.width * dpr)); H = Math.max(1, Math.round(r.height * dpr));
    if (out.width !== W || out.height !== H) { out.width = W; out.height = H; }
    cols = state.grain;
    cellW = W / cols;
    cellH = cellW / CELL_RATIO;
    rows = Math.max(1, Math.floor(H / cellH));
    cellH = H / rows;
    fontPx = cellW / glyphW;
    if (fontPx > cellH * 1.05) fontPx = cellH * 1.05;
    sample.width = cols; sample.height = rows;
  }
  new ResizeObserver(() => { layout(); }).observe(finder);
  document.fonts && document.fonts.ready.then(() => { measureGlyph(); layout(); });
  measureGlyph();

  function drawIdle(t) {
    // slow test card: drifting rings, so the empty finder still speaks ASCII
    idle.width = 160; idle.height = 120;
    const g = ictx.createRadialGradient(80 + Math.sin(t / 1700) * 30, 60 + Math.cos(t / 2300) * 18, 4, 80, 60, 110);
    for (let i = 0; i <= 10; i++) g.addColorStop(i / 10, `hsl(${20 + i * 3},40%,${(Math.sin(i * 1.7 + t / 900) * 0.5 + 0.5) * 70 + 10}%)`);
    ictx.fillStyle = g; ictx.fillRect(0, 0, 160, 120);
    return idle;
  }

  function cover(srcW, srcH) {
    // crop source to the finder's aspect ratio
    const target = (cols * cellW) / (rows * cellH);
    let sw = srcW, sh = srcH;
    if (srcW / srcH > target) sw = srcH * target; else sh = srcW / target;
    return [(srcW - sw) / 2, (srcH - sh) / 2, sw, sh];
  }

  let last = performance.now(), fps = 0, frames = 0, fpsT = 0;
  function frame(t) {
    requestAnimationFrame(frame);
    if (state.hold) return;
    if (cols !== state.grain) layout();
    let src, sw, sh;
    if (state.live && video.readyState >= 2 && video.videoWidth) { src = video; sw = video.videoWidth; sh = video.videoHeight; }
    else { src = drawIdle(t); sw = idle.width; sh = idle.height; }

    const [cx, cy, cw, ch] = cover(sw, sh);
    sctx.save();
    if (state.mirror && src === video) { sctx.translate(cols, 0); sctx.scale(-1, 1); }
    sctx.drawImage(src, cx, cy, cw, ch, 0, 0, cols, rows);
    sctx.restore();
    const px = sctx.getImageData(0, 0, cols, rows).data;

    const ramp = RAMPS[state.ramp].chars, n = ramp.length - 1;
    const ink = INKS[state.ink];
    const light = ink.id === "paper";
    // on paper, dark pixels get dense glyphs; on dark grounds, bright pixels do
    const flipDensity = light !== state.invert;
    const c = state.contrast, b = state.bright;
    const lines = new Array(rows);
    for (let y = 0; y < rows; y++) {
      let s = "";
      for (let x = 0; x < cols; x++) {
        const i = (y * cols + x) * 4;
        let l = (px[i] * 0.2126 + px[i + 1] * 0.7152 + px[i + 2] * 0.0722) / 255;
        l = (l - 0.5) * c + 0.5 + b;
        if (l < 0) l = 0; else if (l > 1) l = 1;
        if (flipDensity) l = 1 - l;
        s += ramp[Math.round(l * n)];
      }
      lines[y] = s;
    }
    state.lastText = lines.join("\n");

    ctx.globalCompositeOperation = "source-over";
    // colour mode needs a transparent ground so only the glyphs take the tint
    if (ink.fg) { ctx.fillStyle = ink.bg; ctx.fillRect(0, 0, W, H); } else ctx.clearRect(0, 0, W, H);
    ctx.font = `500 ${fontPx}px "DM Mono", ui-monospace, monospace`;
    ctx.textBaseline = "middle";
    ctx.fillStyle = ink.fg || "#fff";
    const stretch = cellW / (fontPx * glyphW);
    ctx.save();
    ctx.scale(stretch, 1);
    for (let y = 0; y < rows; y++) ctx.fillText(lines[y], 0, (y + 0.5) * cellH);
    ctx.restore();
    if (!ink.fg) {
      // colour mode: tint the glyphs with the sampled image itself
      ctx.globalCompositeOperation = "source-in";
      ctx.imageSmoothingEnabled = false;
      ctx.drawImage(sample, 0, 0, W, H);
      ctx.globalCompositeOperation = "destination-over";
      ctx.fillStyle = ink.bg; ctx.fillRect(0, 0, W, H);
      ctx.globalCompositeOperation = "source-over";
    }

    frames++;
    if (t - fpsT > 500) { fps = Math.round(frames * 1000 / (t - fpsT)); frames = 0; fpsT = t; $("edgeBR").textContent = String(fps).padStart(2, "0") + " fps"; $("edgeTR").textContent = `${cols} × ${rows}`; }
  }
  requestAnimationFrame(frame);

  // ---------- exposures ----------
  function expose() {
    if (!state.live) return;
    const data = out.toDataURL("image/png");
    const shot = { url: data, text: state.lastText, n: state.shots.length + 1 };
    state.shots.push(shot);
    const sw = $("sweep");
    sw.classList.remove("go"); void sw.offsetWidth; sw.classList.add("go");
    if (navigator.vibrate) navigator.vibrate(12);
    renderSheet(true);
  }
  $("shutter").onclick = expose; $("shutterM").onclick = expose;

  const label = (n) => String(n).padStart(2, "0") + "A";
  function renderSheet(fresh) {
    const box = $("frames");
    box.textContent = "";
    state.shots.forEach((s, i) => {
      const b = document.createElement("button");
      b.type = "button";
      b.setAttribute("aria-label", "Exposure " + label(s.n));
      const img = new Image(); img.src = s.url; img.alt = "";
      const tag = document.createElement("span"); tag.textContent = label(s.n);
      b.append(img, tag);
      b.onclick = () => openViewer(i);
      if (fresh && i === state.shots.length - 1) b.classList.add("new");
      box.prepend(b);
    });
    const n = state.shots.length;
    $("empty").hidden = n > 0;
    $("sheetCount").textContent = n;
    $("frameNo").textContent = "No. " + String(n).padStart(3, "0");
    const lastBtn = $("lastShot");
    lastBtn.querySelector("img")?.remove();
    if (n) { const im = new Image(); im.src = state.shots[n - 1].url; im.alt = ""; lastBtn.prepend(im); }
    $("countM").textContent = n ? label(state.shots[n - 1].n) : "";
  }
  $("lastShot").onclick = () => { if (state.shots.length) openViewer(state.shots.length - 1); };

  let opener = null;
  function openViewer(i) {
    opener = document.activeElement;
    state.viewing = i;
    const s = state.shots[i];
    $("viewImg").src = s.url;
    $("viewImg").alt = "Exposure " + label(s.n);
    $("viewNote").textContent = label(s.n);
    $("viewer").hidden = false;
    $("savePng").focus();
  }
  function closeViewer() { $("viewer").hidden = true; state.viewing = -1; opener && opener.focus && opener.focus(); }
  function step(d) {
    if (!state.shots.length) return;
    openViewer((state.viewing + d + state.shots.length) % state.shots.length);
  }
  $("closeView").onclick = closeViewer;
  $("prevShot").onclick = () => step(-1);
  $("nextShot").onclick = () => step(1);
  $("viewer").addEventListener("click", (e) => { if (e.target.id === "viewer") closeViewer(); });

  function download(href, name) {
    const a = document.createElement("a"); a.href = href; a.download = name;
    document.body.appendChild(a); a.click(); a.remove();
  }
  $("savePng").onclick = () => { const s = state.shots[state.viewing]; download(s.url, `camascii-${label(s.n)}.png`); };
  $("saveTxt").onclick = () => {
    const s = state.shots[state.viewing];
    const url = URL.createObjectURL(new Blob([s.text + "\n"], { type: "text/plain" }));
    download(url, `camascii-${label(s.n)}.txt`);
    setTimeout(() => URL.revokeObjectURL(url), 2000);
  };
  $("copyTxt").onclick = async () => {
    const s = state.shots[state.viewing];
    try { await navigator.clipboard.writeText(s.text); $("viewNote").textContent = "copied"; }
    catch (e) { $("viewNote").textContent = "copy unavailable"; }
  };
  $("delShot").onclick = () => {
    state.shots.splice(state.viewing, 1);
    renderSheet(false);
    if (!state.shots.length) closeViewer(); else openViewer(Math.min(state.viewing, state.shots.length - 1));
  };

  syncUI();
  renderSheet(false);
})();
