# Phase 8 — Analytics & Event Measurement Architecture

**Date:** 2026-11-28  
**Current Status:** Optional privacy-first GA4 loader implemented (`site/assets/analytics.js`), **inactive by default** (`0` external requests, `0` cookies, `0` fabricated IDs) until you explicitly supply a real GA4 Measurement ID.

---

## 1. Implementation Overview

- **Loader:** `site/assets/analytics.js` (`1,777 B` raw / `909 B` gzipped, loaded with `defer`).
- **Activation Gate:** Only initializes `gtag.js` if ALL of the following are true:
  1. A valid `G-XXXXXXXXXX` ID is injected into `<meta name="evendisplay-ga4-id" content="...">` via `EVENDISPLAY_GA4_ID` (environment variable) or `site.analytics.ga4MeasurementId` in `site/seo-config.json`.
  2. Browser `Do Not Track` (`navigator.doNotTrack === "1"`) is NOT enabled.
  3. `window.EVENDISPLAY_CONSENT_DENIED` is NOT `true`.
- **Privacy Configuration:** Explicitly passes `anonymize_ip: true`, `allow_google_signals: false`, and `allow_ad_personalization_signals: false`. Collects zero PII.

---

## 2. Instrumented Product Events (`data-track`)

| Event Name | Trigger Element | Business Meaning |
|---|---|---|
| `open_web_studio` | Header, Hero, and Guide CTAs to `studio.html` | Primary activation into zero-install browser diagnostic |
| `download_mac_app` | Direct `EvenDisplay-v1.0.0.zip` download CTA | Native macOS binary acquisition |
| `copy_homebrew_cmd` | Copy button on `brew install --cask ...` | Developer/power-user macOS install intent |
| `copy_xattr_cmd` | Copy button on `xattr -cr ...` | Unsigned first-launch troubleshooting completion |
| `switch_sim_mode` | Hero WebGL simulator mode buttons (`Dim Bands`, `IPS Ghosting`, `Color Cast`, `Stuck Pixels`) | Reveals which MacBook screen issue drives most visitor interest |
| `read_diagnostic_guide` | Navigation link to `macbook-vertical-bands-guide.html` | Informational research intent |
| `jump_install` | Hero secondary CTA to `#install` | Native Mac app consideration |
| `open_github_repo` | Source on GitHub button | Open-source trust verification |
| `export_profile_json` | Export `.evendisplay.json` in `studio.html` | High-intent Web-to-Mac handoff |
| `toggle_ips_sweep` | Run White/Gray Sweep in `studio.html` | Active IPS ghosting tool usage |

---

## 3. How to Enable GA4 (Optional)

1. Create a GA4 Web Data Stream in Google Analytics for `https://evendisplay.amulyagupta.in/`.
2. Copy the real Measurement ID (`G-...`).
3. Sync locally or in CI:
   ```bash
   EVENDISPLAY_GA4_ID="G-YOURREALID" make seo-sync
   ```
4. **Regional Privacy / Consent Note:** If you expect significant EU/UK/EEA traffic and enable GA4 cookies, add an explicit opt-in consent banner that keeps `window.EVENDISPLAY_CONSENT_DENIED = true` until consent is granted (or alternatively use a cookieless analytics provider such as Plausible or Cloudflare Web Analytics).
