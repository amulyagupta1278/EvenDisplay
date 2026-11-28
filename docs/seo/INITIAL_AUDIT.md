# Phase 0 — Initial Repository Discovery & Baseline SEO Audit

**Audit Date:** 2026-11-28  
**Repository Root:** `/Users/amulyagupta/.gemini/antigravity/scratch/EvenDisplay-live`  
**Git Remote:** `https://github.com/amulyagupta1278/EvenDisplay.git` (branch `main`, 4 local commits ahead of `origin/main` prior to this audit; working tree clean).

---

## 1. Architecture & Stack Discovery

| Property | Observed Value |
|---|---|
| **Product** | **EvenDisplay v1.0.0** — Free, open-source (MIT) native macOS 13+ display utility (`EvenDisplay.app`) + zero-install browser Calibration Studio |
| **Web Framework** | Pure static HTML5 / CSS3 / vanilla JavaScript + WebGL shaders (zero JS framework or bundler overhead) |
| **Package Manager** | None (`package.json` absent; Python 3.13 at `/opt/homebrew/bin/python3.13` and `swiftc` handle build/test automation) |
| **Rendering Strategy** | Static HTML files (SSG/static prerendered) — 100% of primary content and metadata are present in initial HTML without requiring JavaScript execution |
| **Deployment Platform** | GitHub Pages via `.github/workflows/pages.yml` (2-job `build` → `deploy`, publishing `./site`) |
| **Production Domain** | `https://evendisplay.amulyagupta.in/` (confirmed in `site/CNAME`, `site/robots.txt`, `site/sitemap.xml`, and canonical links) |
| **Live Deployment Status** | Remote `origin/main` is at `4c36cc8` (where earlier single-job Pages deploy failed with `Found 0 artifact(s)`). Local commit `e3666e2` fixed `.github/workflows/pages.yml` into a 2-job workflow but has **not been pushed yet** pending owner authorization. |
| **Native macOS Distribution** | GitHub Releases (`EvenDisplay-v1.0.0.zip`) + Homebrew Cask (`Casks/evendisplay.rb`) |
| **Analytics** | None installed |

---

## 2. Public Route Inventory (Baseline)

| Route File | Production URL | Index Policy | Current Role |
|---|---|---|---|
| `site/index.html` | `https://evendisplay.amulyagupta.in/` | **Index (`index, follow`)** | Main product landing page + interactive WebGL MacBook display simulator |
| `site/studio.html` | `https://evendisplay.amulyagupta.in/studio.html` | **Index (`index, follow`)** | Interactive 9-color uniformity tester, IPS ghosting sweep & 2-band movable compensator |
| `site/macbook-vertical-bands-guide.html` | `https://evendisplay.amulyagupta.in/macbook-vertical-bands-guide.html` | **Index (`index, follow`)** | 4-step hardware vs. software MacBook vertical-band diagnostic guide |
| `site/404.html` | *(Missing at baseline)* | **Noindex (`noindex, follow`)** | Custom GitHub Pages 404 handler (not yet created) |

Internal/non-web repository paths (`macos/`, `scripts/`, `Casks/`, `DESIGN.md`, `docs/`) are outside `./site` and are never uploaded to GitHub Pages.

---

## 3. Asset Inventory (Baseline)

| Asset | Dimensions | Format | Size | Usage & Audit Notes |
|---|---|---|---|---|
| `site/assets/icon.png` | `512×512` | PNG | `94,091 B` | Used as favicon and inline `24×24` / `28×28` header logo — oversized by ~25× for navbar display; no `apple-touch-icon` (`180×180`) or compact favicon variant |
| `site/assets/og-card.png` | `1200×630` | PNG | `66,581 B` | Social sharing card (correct 1.91:1 OG dimensions, crisp brand text; copy still focuses narrowly on vertical bands rather than all MacBook screen issues) |

---

## 4. Baseline SEO & Quality Defects Identified

### Critical / High-Impact Findings
1. **Structured Data Policy Mismatch (`site/index.html`):** `FAQPage` JSON-LD questions #3 and #4 (`"How can I tell if my MacBook screen issue is hardware or software?"`, `"Is EvenDisplay safe and completely reversible?"`) do **not** match the visible FAQ questions on the page (`"Will EvenDisplay tint my external monitor?"`, `"How do I undo everything cleanly?"`). Google requires all FAQ JSON-LD to match visible page content.
2. **Deprecated Rich-Result Schema (`site/macbook-vertical-bands-guide.html`):** Uses `@type: HowTo`, which Google deprecated across desktop and mobile in 2023. Should use `TechArticle` + `BreadcrumbList` with truthful dates and author metadata.
3. **Missing `<h1>` and Semantic Landmarks (`site/studio.html`):** No `<h1>` element anywhere in the document; no `<main>` landmark; range inputs `#rng-surround` and `#rng-feather` lack programmatic `<label>` associations; header icon lacks explicit `width`/`height`.
4. **Missing Custom `404.html`:** Unmatched URLs fall through to GitHub's generic 404 page instead of a branded `noindex, follow` recovery page.

### Medium-Impact Findings
5. **Outdated / Ignored SEO Directives:**
   - `site/index.html` contains `<meta name="keywords">` (ignored by Google).
   - `site/sitemap.xml` contains `<changefreq>` and `<priority>` (ignored by Google).
6. **Incomplete Cross-Route Social & Technical Metadata:**
   - `site/studio.html` and `site/macbook-vertical-bands-guide.html` omit `og:site_name`, `og:locale`, `og:image:width`, `og:image:height`, `og:image:alt`, `twitter:title`, `twitter:description`, `twitter:image`, `twitter:image:alt`, `theme-color`, `apple-touch-icon`, and explicit `robots` meta tags.
   - `site/index.html` omits `og:locale`, `og:image:alt`, `twitter:image:alt`, `apple-touch-icon`, `robots`, and `WebSite` / `WebPage` JSON-LD graph linkage.
7. **Uncentralized Metadata Maintenance:** Each HTML page duplicates `<head>` tags manually, making drift (such as mismatched FAQ schema or inconsistent domain/image tags) likely.
8. **Image Payload & CLS Hygiene:**
   - `site/macbook-vertical-bands-guide.html` renders `<img src="assets/icon.png">` without `width`/`height` attributes.
   - All three pages ship a `94 KB` `512×512` PNG for a `24×24` header icon.
9. **No Comprehensive Automated SEO Test Suite:** Existing `scripts/test_all.sh` runs 22 basic string checks without HTTP status validation, broken-link checks, duplicate title/description checks, H1/accessibility checks, or JSON-LD-vs-visible-DOM verification.
10. **No Production Analytics or Verification Documentation:** No optional env-driven GA4 helper, no Google Search Console setup runbook, and no Bing/IndexNow/directory discovery plan.
