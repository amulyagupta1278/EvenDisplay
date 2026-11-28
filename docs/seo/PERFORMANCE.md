# Phase 10 — Performance & Core Web Vitals Audit

**Date:** 2026-11-28  
**Measurement Scope:** Local static asset & browser audit (production live Lighthouse/PageSpeed Insights pending GitHub Pages deploy).

---

## 1. Core Web Vitals Targets (Google Search Central)

- **LCP (Largest Contentful Paint):** `<= 2.5s`
- **INP (Interaction to Next Paint):** `<= 200ms`
- **CLS (Cumulative Layout Shift):** `<= 0.1`

---

## 2. Measured Asset Payload (Before vs. After Optimization)

| Resource | Raw Size | Gzipped Size | Optimization Applied |
|---|---|---|---|
| `site/index.html` (all inline CSS + WebGL shaders + UI JS) | `76,874 B` | `17,692 B` | Zero render-blocking external CSS, zero external font requests, zero third-party JS bundles |
| `site/studio.html` | `56,871 B` | `12,941 B` | Self-contained full-screen Canvas app |
| `site/macbook-vertical-bands-guide.html` | `15,341 B` | `4,596 B` | Lightweight editorial HTML |
| `site/404.html` | `5,538 B` | `1,898 B` | Minimal recovery page |
| `site/assets/analytics.js` | `1,777 B` | `909 B` | Loaded `defer`; makes **0** external network calls when unconfigured |
| Navbar icon (`icon-64.png` vs. previous `icon.png`) | **`3,517 B`** *(was `94,091 B`)* | **`3,383 B`** | **96.3% image payload reduction** while retaining 2× Retina sharpness at `24×24` |
| `site/assets/apple-touch-icon.png` (`180×180`) | `18,361 B` | `18,151 B` | Only fetched by Apple bookmark/home-screen requests |
| `site/assets/og-card.png` (`1200×630`) | `66,581 B` | `54,875 B` | Only fetched by social crawlers, never blocks user page load |

**Total First-Visit Transfer on `/` (Gzipped):** `~22.0 KB` (`index.html` + `icon-64.png` + `analytics.js`).

---

## 3. Architectural Core Web Vitals Protections

- **LCP Protection:** Hero `<h1>` (`Diagnose and balance any MacBook display.`) renders immediately on first paint using native macOS SF Pro / system UI sans-serif with zero webfont network stall and zero hero image bottleneck.
- **CLS Protection (`~0.00`):**
  - Explicit `width` and `height` attributes added to **every `<img>`** across all 4 HTML routes (fixing missing dimensions on `studio.html` and `macbook-vertical-bands-guide.html`).
  - Explicit fixed heights on `.lcd-stage` (`318px` desktop / `264px` mobile) and `.site-header` (`52px`) prevent layout shift as `<canvas>` initializes.
  - Zero dynamic cookie/chat/ad injections shifting first-screen content.
- **INP & Battery Protection:**
  - `IntersectionObserver` pauses both `#webgl-panel` and `#lab-webgl-bg` `requestAnimationFrame` loops whenever off-screen.
  - `prefers-reduced-motion: reduce` disables continuous animation frames completely.
  - `analytics.js` is `defer`-loaded and binds a single lightweight delegated click listener.

---

## 4. Production Verification Needed Post-Deploy

Lighthouse CLI (`npx lighthouse`) could not run locally because Homebrew Node on this machine has a broken `icu4c` dylib, and `https://evendisplay.amulyagupta.in/` has not yet received the fixed 2-job Pages deploy. **Action Required after push:**
- Run https://pagespeed.web.dev/ on `https://evendisplay.amulyagupta.in/` (Mobile & Desktop) and `https://evendisplay.amulyagupta.in/macbook-vertical-bands-guide.html` to record real production Lighthouse scores and CrUX field data.
