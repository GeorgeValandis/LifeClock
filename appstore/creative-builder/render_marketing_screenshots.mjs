#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const rootDir = process.cwd();

const slides = [
  {
    file: "01-home.png",
    eyebrow: "LIFECLOCK",
    title: "See Your Life\nat a Glance",
    subtitle:
      "A calm, beautifully simple dashboard for the time you have lived and the time still lies ahead.",
    chips: ["Life dashboard", "Milestones", "Perspective"],
    background:
      "radial-gradient(circle at 18% 18%, rgba(255,176,79,0.34), transparent 26%), radial-gradient(circle at 84% 82%, rgba(55,236,205,0.22), transparent 28%), linear-gradient(180deg, #24180f 0%, #173a3b 100%)",
    accent: "#ffb04f",
    accentSoft: "rgba(255,176,79,0.18)",
    glow: "rgba(68, 227, 205, 0.28)",
    rotation: -1.4,
  },
  {
    file: "02-grid.png",
    eyebrow: "LIFE GRID",
    title: "Switch from\nYears to Seconds",
    subtitle:
      "Move through years, months, weeks, days, hours, minutes, and seconds in one fluid view.",
    chips: ["Years", "Months", "Seconds"],
    background:
      "radial-gradient(circle at 16% 20%, rgba(24,223,255,0.24), transparent 24%), radial-gradient(circle at 82% 84%, rgba(93,255,211,0.14), transparent 28%), linear-gradient(180deg, #062546 0%, #06142b 100%)",
    accent: "#28d7ff",
    accentSoft: "rgba(40,215,255,0.18)",
    glow: "rgba(40, 215, 255, 0.22)",
    rotation: 1.2,
  },
  {
    file: "03-settings.png",
    eyebrow: "PERSONALIZATION",
    title: "Personalize\nEvery Detail",
    subtitle:
      "Adjust your life profile, choose a theme, refine typography, and make the app feel truly yours.",
    chips: ["Themes", "Typography", "Haptics"],
    background:
      "radial-gradient(circle at 18% 22%, rgba(255,140,54,0.28), transparent 24%), radial-gradient(circle at 80% 16%, rgba(255,194,91,0.18), transparent 18%), linear-gradient(180deg, #3a160d 0%, #7a320e 100%)",
    accent: "#ff9a47",
    accentSoft: "rgba(255,154,71,0.18)",
    glow: "rgba(255, 195, 91, 0.18)",
    rotation: -0.8,
  },
  {
    file: "04-onboarding.png",
    eyebrow: "VISUAL STYLE",
    title: "Choose the Theme\nThat Fits You",
    subtitle:
      "Start with a visual style that matches your mood, from warm Aurora to cool Deep Sea.",
    chips: ["Aurora", "Solar Glow", "Deep Sea"],
    background:
      "radial-gradient(circle at 14% 18%, rgba(129,95,255,0.32), transparent 26%), radial-gradient(circle at 82% 86%, rgba(62,236,211,0.16), transparent 30%), linear-gradient(180deg, #0b1028 0%, #14133d 100%)",
    accent: "#9d83ff",
    accentSoft: "rgba(157,131,255,0.18)",
    glow: "rgba(62, 236, 211, 0.18)",
    rotation: 1.6,
  },
  {
    file: "05-paywall.png",
    eyebrow: "LIFETIME ACCESS",
    title: "Unlock Everything\nfor Life",
    subtitle:
      "Get every feature with a single purchase and no recurring subscription.",
    chips: ["One-time purchase", "No subscription", "Full access"],
    background:
      "radial-gradient(circle at 20% 16%, rgba(255,184,69,0.34), transparent 24%), radial-gradient(circle at 82% 84%, rgba(255,123,57,0.18), transparent 28%), linear-gradient(180deg, #4a1d0c 0%, #a24d15 100%)",
    accent: "#ffbe55",
    accentSoft: "rgba(255,190,85,0.18)",
    glow: "rgba(255, 154, 71, 0.22)",
    rotation: -1.1,
  },
];

const devices = {
  iphone: {
    inputDir: path.join(rootDir, ".asc/test-screenshots/iphone"),
    outputDir: path.join(rootDir, ".asc/screenshots/upload/iphone"),
    htmlDir: path.join(rootDir, ".asc/marketing-screenshots/html/iphone"),
    previewWidth: 1320,
    previewHeight: 2868,
    shellWidth: 872,
    shellHeight: 1888,
    screenshotInset: 42,
    shellRadius: 118,
    screenshotRadius: 82,
    shellTop: 844,
    titleTop: 210,
    eyebrowTop: 126,
    subtitleTop: 520,
    chipsTop: 672,
    titleSize: 122,
    subtitleSize: 47,
    eyebrowSize: 28,
    chipSize: 27,
    subtitleWidth: 1030,
    notchWidth: 208,
    notchHeight: 56,
    blobSize: 820,
    blobTop: 1020,
    blobLeft: 250,
    shellBorder: "2px solid rgba(255,255,255,0.28)",
    badgeLabel: "iPhone 6.9\"",
    badgeTop: 126,
    badgeRight: 110,
    framePaddingBottom: 138,
  },
  ipad: {
    inputDir: path.join(rootDir, ".asc/test-screenshots/ipad"),
    outputDir: path.join(rootDir, ".asc/screenshots/upload/ipad"),
    htmlDir: path.join(rootDir, ".asc/marketing-screenshots/html/ipad"),
    previewWidth: 2064,
    previewHeight: 2752,
    shellWidth: 1460,
    shellHeight: 1948,
    screenshotInset: 54,
    shellRadius: 84,
    screenshotRadius: 54,
    shellTop: 692,
    titleTop: 182,
    eyebrowTop: 112,
    subtitleTop: 472,
    chipsTop: 604,
    titleSize: 138,
    subtitleSize: 50,
    eyebrowSize: 30,
    chipSize: 29,
    subtitleWidth: 1240,
    notchWidth: 0,
    notchHeight: 0,
    blobSize: 1180,
    blobTop: 860,
    blobLeft: 450,
    shellBorder: "2px solid rgba(255,255,255,0.22)",
    badgeLabel: "iPad 13\"",
    badgeTop: 112,
    badgeRight: 154,
    framePaddingBottom: 92,
  },
};

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function renderSlide(deviceKey, device, slide, screenshotUrl) {
  const titleHtml = escapeHtml(slide.title).replaceAll("\n", "<br>");
  const chipsHtml = slide.chips
    .map((chip) => `<span class="chip">${escapeHtml(chip)}</span>`)
    .join("");
  const isPhone = deviceKey === "iphone";

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(slide.title.replaceAll("\n", " "))}</title>
  <style>
    :root {
      --w: ${device.previewWidth}px;
      --h: ${device.previewHeight}px;
      --title-top: ${device.titleTop}px;
      --eyebrow-top: ${device.eyebrowTop}px;
      --subtitle-top: ${device.subtitleTop}px;
      --chips-top: ${device.chipsTop}px;
      --shell-top: ${device.shellTop}px;
      --shell-width: ${device.shellWidth}px;
      --shell-height: ${device.shellHeight}px;
      --shell-radius: ${device.shellRadius}px;
      --screenshot-inset: ${device.screenshotInset}px;
      --screenshot-radius: ${device.screenshotRadius}px;
      --title-size: ${device.titleSize}px;
      --subtitle-size: ${device.subtitleSize}px;
      --eyebrow-size: ${device.eyebrowSize}px;
      --chip-size: ${device.chipSize}px;
      --subtitle-width: ${device.subtitleWidth}px;
      --accent: ${slide.accent};
      --accent-soft: ${slide.accentSoft};
      --glow: ${slide.glow};
      --badge-top: ${device.badgeTop}px;
      --badge-right: ${device.badgeRight}px;
      --blob-size: ${device.blobSize}px;
      --blob-top: ${device.blobTop}px;
      --blob-left: ${device.blobLeft}px;
      --rotation: ${slide.rotation}deg;
      --frame-padding-bottom: ${device.framePaddingBottom}px;
    }

    * {
      box-sizing: border-box;
    }

    html,
    body {
      margin: 0;
      width: var(--w);
      height: var(--h);
      overflow: hidden;
      background: #090909;
    }

    body {
      font-family: "SF Pro Rounded", "SF Pro Display", "SF Pro Text", "Avenir Next", -apple-system, BlinkMacSystemFont, sans-serif;
      -webkit-font-smoothing: antialiased;
      text-rendering: geometricPrecision;
    }

    .artboard {
      position: relative;
      width: 100%;
      height: 100%;
      color: #fffef8;
      background: ${slide.background};
      isolation: isolate;
    }

    .artboard::before {
      content: "";
      position: absolute;
      inset: 0;
      background:
        linear-gradient(135deg, rgba(255,255,255,0.04) 0, rgba(255,255,255,0.0) 36%),
        radial-gradient(circle at 50% 0%, rgba(255,255,255,0.06), transparent 44%);
      mix-blend-mode: screen;
      pointer-events: none;
    }

    .artboard::after {
      content: "";
      position: absolute;
      inset: 54px;
      border: 1px solid rgba(255,255,255,0.07);
      border-radius: 44px;
      opacity: 0.55;
      pointer-events: none;
    }

    .grid {
      position: absolute;
      inset: 0;
      background-image:
        linear-gradient(rgba(255,255,255,0.022) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255,255,255,0.022) 1px, transparent 1px);
      background-size: 110px 110px;
      mask-image: linear-gradient(180deg, rgba(0,0,0,0.32), transparent 68%);
      pointer-events: none;
    }

    .blob {
      position: absolute;
      width: var(--blob-size);
      height: var(--blob-size);
      left: var(--blob-left);
      top: var(--blob-top);
      border-radius: 50%;
      background:
        radial-gradient(circle at 30% 30%, var(--glow), rgba(255,255,255,0) 60%),
        radial-gradient(circle at 68% 68%, rgba(255,255,255,0.12), rgba(255,255,255,0) 58%);
      filter: blur(6px);
      opacity: 0.95;
      pointer-events: none;
    }

    .eyebrow {
      position: absolute;
      top: var(--eyebrow-top);
      left: 112px;
      padding: 18px 28px;
      border-radius: 999px;
      background: rgba(255,255,255,0.08);
      border: 1px solid rgba(255,255,255,0.12);
      color: var(--accent);
      font-size: var(--eyebrow-size);
      font-weight: 700;
      letter-spacing: 0.18em;
      backdrop-filter: blur(20px);
      text-transform: uppercase;
    }

    .badge {
      position: absolute;
      top: var(--badge-top);
      right: var(--badge-right);
      padding: 16px 24px;
      border-radius: 999px;
      background: rgba(255,255,255,0.08);
      border: 1px solid rgba(255,255,255,0.12);
      color: rgba(255,255,255,0.78);
      font-size: 26px;
      font-weight: 600;
      letter-spacing: 0.03em;
      backdrop-filter: blur(20px);
    }

    h1 {
      position: absolute;
      top: var(--title-top);
      left: 112px;
      right: 112px;
      margin: 0;
      font-size: var(--title-size);
      line-height: 0.94;
      letter-spacing: -0.05em;
      font-weight: 800;
      color: #fffdf8;
      text-wrap: balance;
    }

    .subtitle {
      position: absolute;
      top: var(--subtitle-top);
      left: 112px;
      width: var(--subtitle-width);
      margin: 0;
      font-size: var(--subtitle-size);
      line-height: 1.16;
      letter-spacing: -0.032em;
      color: rgba(255,255,255,0.82);
      text-wrap: pretty;
    }

    .chips {
      position: absolute;
      top: var(--chips-top);
      left: 112px;
      display: flex;
      gap: 18px;
      flex-wrap: wrap;
    }

    .chip {
      display: inline-flex;
      align-items: center;
      gap: 12px;
      padding: 18px 24px;
      border-radius: 999px;
      background: rgba(255,255,255,0.08);
      border: 1px solid rgba(255,255,255,0.12);
      color: rgba(255,255,255,0.92);
      font-size: var(--chip-size);
      font-weight: 600;
      letter-spacing: -0.03em;
      backdrop-filter: blur(16px);
      box-shadow: inset 0 1px 0 rgba(255,255,255,0.06);
    }

    .chip::before {
      content: "";
      width: 12px;
      height: 12px;
      border-radius: 50%;
      background: var(--accent);
      box-shadow: 0 0 18px var(--accent);
      flex: 0 0 auto;
    }

    .device-shell {
      position: absolute;
      left: 50%;
      top: var(--shell-top);
      width: var(--shell-width);
      height: var(--shell-height);
      transform: translateX(-50%) rotate(var(--rotation));
      border-radius: var(--shell-radius);
      background:
        linear-gradient(180deg, rgba(255,255,255,0.26), rgba(255,255,255,0.08)),
        linear-gradient(180deg, rgba(19,20,24,0.98), rgba(5,6,8,0.98));
      border: ${device.shellBorder};
      box-shadow:
        0 36px 90px rgba(0,0,0,0.28),
        inset 0 1px 0 rgba(255,255,255,0.16),
        inset 0 -2px 0 rgba(0,0,0,0.3);
      padding: var(--screenshot-inset);
      padding-bottom: var(--frame-padding-bottom);
      overflow: hidden;
    }

    .device-shell::before {
      content: "";
      position: absolute;
      inset: 18px;
      border-radius: calc(var(--shell-radius) - 18px);
      border: 1px solid rgba(255,255,255,0.12);
      pointer-events: none;
    }

    ${isPhone ? `
    .device-shell::after {
      content: "";
      position: absolute;
      top: 22px;
      left: 50%;
      width: ${device.notchWidth}px;
      height: ${device.notchHeight}px;
      transform: translateX(-50%);
      border-radius: 999px;
      background: rgba(0,0,0,0.92);
      box-shadow:
        inset 0 -1px 0 rgba(255,255,255,0.1),
        0 8px 24px rgba(0,0,0,0.24);
      z-index: 3;
    }` : ""}

    .screen-wrap {
      position: relative;
      width: 100%;
      height: 100%;
      overflow: hidden;
      border-radius: var(--screenshot-radius);
      background: rgba(255,255,255,0.04);
      box-shadow: inset 0 0 0 1px rgba(255,255,255,0.06);
    }

    .screen {
      width: 100%;
      height: 100%;
      object-fit: cover;
      object-position: center top;
      display: block;
    }

    .screen-gloss {
      position: absolute;
      inset: 0;
      background: linear-gradient(145deg, rgba(255,255,255,0.12) 0%, rgba(255,255,255,0) 28%);
      pointer-events: none;
      mix-blend-mode: screen;
    }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="grid"></div>
    <div class="blob"></div>
    <div class="eyebrow">${escapeHtml(slide.eyebrow)}</div>
    <div class="badge">${escapeHtml(device.badgeLabel)}</div>
    <h1>${titleHtml}</h1>
    <p class="subtitle">${escapeHtml(slide.subtitle)}</p>
    <div class="chips">${chipsHtml}</div>
    <div class="device-shell">
      <div class="screen-wrap">
        <img class="screen" src="${screenshotUrl}" alt="">
        <div class="screen-gloss"></div>
      </div>
    </div>
  </main>
</body>
</html>`;
}

async function ensureDir(dir) {
  await fs.mkdir(dir, { recursive: true });
}

async function writeSlidesForDevice(deviceKey, device) {
  await ensureDir(device.outputDir);
  await ensureDir(device.htmlDir);

  for (const slide of slides) {
    const sourcePath = path.join(device.inputDir, slide.file);
    const sourceExists = await fs
      .access(sourcePath)
      .then(() => true)
      .catch(() => false);

    if (!sourceExists) {
      throw new Error(`Missing source screenshot: ${sourcePath}`);
    }

    const screenshotUrl = pathToFileURL(sourcePath).href;
    const html = renderSlide(deviceKey, device, slide, screenshotUrl);
    const htmlPath = path.join(device.htmlDir, slide.file.replace(/\.png$/, ".html"));
    await fs.writeFile(htmlPath, html, "utf8");
  }
}

async function main() {
  for (const [deviceKey, device] of Object.entries(devices)) {
    await writeSlidesForDevice(deviceKey, device);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
