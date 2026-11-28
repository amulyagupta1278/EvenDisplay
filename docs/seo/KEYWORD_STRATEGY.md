# Phase 3 — Keyword & Content Strategy

**Strategy Date:** 2026-11-28  
**Methodology:** Derived strictly from EvenDisplay's verified implemented capabilities and real user problem phrasing observed in Apple Support Communities, `r/macbookpro`, `r/mac`, `r/macapps`, and macOS display testing searches. No fabricated search volumes or keyword difficulty numbers are invented.

---

## 1. Product Truth & Positioning

- **Product Category:** Free, open-source macOS display diagnostic, pixel conditioning, and visual band compensation utility (`EvenDisplay.app` for macOS 13+ + browser Calibration Studio).
- **Target Audience:**
  1. MacBook Pro & MacBook Air owners experiencing dim vertical bands/stripes, temporary IPS image retention/ghosting, uneven tint/color cast, or stuck/dead pixels.
  2. Used/refurbished MacBook buyers running a pre-purchase display uniformity and lid-angle Flexgate check.
  3. macOS users looking for a free, local, zero-telemetry alternative to ad-heavy browser dead-pixel sites or paid App Store screen checkers.
- **Differentiating Implemented Capabilities:**
  - Zero-install 9-color fullscreen uniformity tester (`50% Gray`, `25% Gray`, `75% Gray`, `10% Dark`, `White`, `Red`, `Green`, `Blue`, `Black`, keys `1–9`).
  - Independent movable vertical band compensator with hover-only alignment edges, Brightness (`±50%`), Temp (`±40%`), Green/Magenta Tint (`±40%`), Fine RGB (`±30%`), Outside Dim (`0–40%`), Edge Feather (`0–20 px`), and double-click slider reset.
  - IPS White & Gray image-retention sweep with display wake lock.
  - Native macOS menu-bar utility locked strictly to the built-in display (`CGDisplayIsBuiltin`), `.evendisplay.json` browser-to-Mac sync, Light/Dark checkpoints, full Undo/Redo, and 1-keystroke panic revert (`Cmd+Option+0`).
  - 100% honest about hardware vs. software limits (zero false claims of soldering COF/flex cables).
- **Observed Alternatives / Context:** EIZO Monitor Test (web), DeadPixelTest.org (web), JScreenFix (web), Screen Test: Monitor Checker (Mac App Store). None combine a MacBook-specific 9-color diagnostic + IPS sweep + built-in-display-locked reversible vertical band compensator as a free MIT open-source macOS utility.

---

## 2. Keyword Clusters

| Cluster | Keyword / Query Pattern | Search Intent | Relevance | Target Page | Content Opportunity | Evidence / Source | Confidence |
|---|---|---|---|---|---|---|---|
| **Primary Product** | `EvenDisplay`, `EvenDisplay macOS` | Navigational | High | `/` | Brand entity consistency across GitHub, website, Cask, schema | Direct brand name | High |
| **Category** | `MacBook screen test`, `MacBook display uniformity test` | Commercial / Tool | High | `/`, `/studio.html` | Above-the-fold browser studio CTA + 9-color fullscreen test | Reddit `r/macbookpro`, web tool queries | High |
| **Problem: Vertical Bands** | `MacBook Pro dim vertical bands fix`, `MacBook vertical stripes on gray screen` | Problem-solving / Informational | Very High | `/macbook-vertical-bands-guide.html`, `/` | Honest 4-step screenshot + lid-angle diagnostic + reversible workaround | Apple Support Communities, `r/macbookpro` | High |
| **Problem: Ghosting** | `MacBook screen ghosting fix`, `MacBook IPS image retention cleaner` | Problem-solving | High | `/`, `/studio.html` | Explain IPS retention vs. OLED burn-in + White & Gray Sweep tool | `r/mac`, `r/macbookpro`, Apple discussions | High |
| **Problem: Pixel Cleaner** | `does MacBook have built in pixel cleaner`, `MacBook pixel cleaner app` | Informational / Tool | High | `/`, `/macbook-vertical-bands-guide.html` | Direct plain-language FAQ answering why macOS lacks a built-in cleaner | Observed user queries & FAQ alignment | High |
| **Problem: Stuck Pixels** | `MacBook stuck pixel test`, `MacBook dead pixel checker free` | Tool | High | `/studio.html`, `/` | Instant 9-color RGB/Black/White check + pixel sweep | Web display checker landscape | High |
| **Problem: Color Cast** | `MacBook screen uneven tint`, `MacBook half screen yellow or green tint` | Problem-solving | Medium-High | `/` | Highlight per-zone Warm/Cool, Green/Magenta & Fine RGB matching | Display uniformity community reports | Medium |
| **Use Case: Used MacBook** | `how to check used MacBook screen before buying` | Informational / Checklist | High | `/`, `/macbook-vertical-bands-guide.html` | 2-minute 9-color + lid-angle flex check in browser with zero install | Buyer checklists on `r/macbookpro` | High |
| **Feature-Specific** | `MacBook screen overlay built-in display only`, `fix dim band without tinting external monitor` | Commercial / Niche | High | `/` | Emphasize `CGDisplayIsBuiltin` hardware lock & zero ICC/system writes | Core technical differentiator | High |
| **Alternative / Comparison** | `free MacBook monitor test alternative`, `open source MacBook screen checker` | Comparison | Medium | `/`, `/studio.html` | Honest open-source MIT positioning (no ads, no telemetry, offline Mac app) | Mac App Store & web tool landscape | Medium |

---

## 3. Content Architecture Evaluation

| Candidate Page | Recommendation | Rationale |
|---|---|---|
| **Homepage (`/`)** | **Keep & Strengthen** | Serves primary product, category, and multi-issue MacBook screen queries with immediate interactive proof |
| **Web Calibration Studio (`/studio.html`)** | **Keep & Add Semantic `<h1>` + Metadata** | High-value interactive utility route targeting tool-intent queries (`MacBook screen test`, `50% gray test`) |
| **Diagnostic Guide (`/macbook-vertical-bands-guide.html`)** | **Keep & Upgrade to `TechArticle`** | Genuine editorial value capturing hardware-vs-software troubleshooting intent |
| **Custom 404 (`/404.html`)** | **Create (`noindex, follow`)** | Proper GitHub Pages recovery experience without polluting the search index |
| **Pricing / Testimonials / Comparison Spam Pages** | **Do NOT Create** | App is 100% free MIT open-source; creating artificial pricing pages or thin keyword-swapped competitor/model pages would add low-value bloat |
| **Future High-Value Editorial Opportunities (Post-Launch)** | **Consider Later Only When Substantive** | Only if genuine depth is authored: (1) *Used MacBook Display Inspection Checklist (Before You Buy)*, (2) *MacBook IPS Image Retention vs. Burn-In Guide* — never thin duplicates |
