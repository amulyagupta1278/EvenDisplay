# Phase 12 — Bing, IndexNow & Organic Software Discovery Strategy

**Date:** 2026-11-28  
**Goal:** Maximize legitimate, non-spammy organic discovery of EvenDisplay across secondary search engines and high-intent macOS/developer software directories once live.

---

## 1. Bing Webmaster Tools & IndexNow

1. **Bing Webmaster Tools (https://www.bing.com/webmasters/):**
   - Easiest path: After verifying Google Search Console, click **Import from Google Search Console** in Bing Webmaster Tools to import property verification and `https://evendisplay.amulyagupta.in/sitemap.xml` automatically.
   - Alternate path: Supply Bing's verification code via `EVENDISPLAY_BING_TOKEN="<token>" make seo-sync` (emits `<meta name="msvalidate.01">`), push, and verify.
2. **IndexNow (Optional, Post-Launch):**
   - Because EvenDisplay has only 3 static routes that update infrequently, standard `sitemap.xml` submission in Bing Webmaster Tools is sufficient at launch.
   - If you later add new guides/articles and want instant Bing/Yandex/Copilot notification: generate a 32-char hex key, save it as `site/<key>.txt`, deploy, and ping `https://api.indexnow.org/indexnow` from a GitHub Actions post-deploy step.

---

## 2. Apple / macOS & Software Directory Distribution Plan

| Channel | Fit for EvenDisplay | Actionable Listing Details (Truthful Only) |
|---|---|---|
| **GitHub Repository Topics & Releases** | **Highest** | Add topics: `macos`, `macbook`, `display`, `screen-test`, `swift`, `swiftui`, `open-source`, `pixel-cleaner`, `display-calibration`; set Website URL to `https://evendisplay.amulyagupta.in/` in GitHub repo About panel. |
| **Homebrew Cask (`amulyagupta1278/tap/evendisplay`)** | **High** | Publish `Casks/evendisplay.rb` into your tap repo so `brew install --cask amulyagupta1278/tap/evendisplay` works out of the box (currently linked on the homepage). |
| **AlternativeTo** | **High** | Submit EvenDisplay as a free, open-source MIT macOS/Web alternative to EIZO Monitor Test, DeadPixelTest, JScreenFix, and Screen Test: Monitor Checker. |
| **MacUpdate** | **Medium-High** | Submit the free direct GitHub Release `.zip` listing under Utilities → Display / Monitor Tools (explicitly note ad-hoc unsigned open-source build & MIT license). |
| **Product Hunt** | **Medium-High** | Strong visual demo hook: embed the interactive WebGL Retina Simulator link (`https://evendisplay.amulyagupta.in/`), focus on the honest real-world story (built to handle MacBook Pro dim vertical bands & screen diagnostics for `$0`). |
| **Authentic Communities (`r/macapps`, `r/macbookpro`, Hacker News Show HN)** | **Highest Organic Signal** | Share transparently as a `Show HN` / `r/macapps` open-source utility post — emphasize zero telemetry, `CGDisplayIsBuiltin` built-in display lock, and honesty about software vs. hardware limits. Never spam or astroturf. |
| **Setapp / Mac App Store** | **Not Applicable** | App Store sandboxing blocks system-wide overlay windows (`CGWindowLevel`), and EvenDisplay is free MIT open-source rather than a paid subscription. |
