# Phase 2 — Complete Technical SEO Audit

**Audit Date:** 2026-11-28  
**Scope:** Every public-facing route in `site/` (`index.html`, `studio.html`, `macbook-vertical-bands-guide.html`, plus newly added `404.html`).

---

## 1. Per-Route Audit Matrix (Baseline → Target Remediation)

| Check | `/` (`index.html`) | `/studio.html` | `/macbook-vertical-bands-guide.html` | `/404.html` |
|---|---|---|---|---|
| **Unique `<title>`** | PASS (`74 chars` → tightened to `64 chars`) | PASS (`68 chars` → `62 chars`) | PASS (`66 chars` → `61 chars`) | ADD (`Page Not Found — EvenDisplay`) |
| **Unique `<meta name="description">`** | PASS (`212 chars` → concise `156 chars`) | PASS (`193 chars` → concise `154 chars`) | PASS (`200 chars` → concise `155 chars`) | ADD (clean recovery description) |
| **Canonical URL** | PASS (`https://evendisplay.amulyagupta.in/`) | PASS (`.../studio.html`) | PASS (`.../macbook-vertical-bands-guide.html`) | Omit / self-free (`noindex, follow`) |
| **`html lang="en"` & `viewport`** | PASS | PASS | PASS | ADD |
| **`meta robots`** | MISSING → ADD `index, follow, max-image-preview:large, max-snippet:-1` | MISSING → ADD `index, follow, max-image-preview:large, max-snippet:-1` | MISSING → ADD `index, follow, max-image-preview:large, max-snippet:-1` | ADD `noindex, follow` |
| **Outdated `<meta name="keywords">`** | PRESENT → REMOVE | Absent | Absent | Absent |
| **Open Graph (complete)** | Missing `og:locale`, `og:image:alt` → FIX | Missing `og:site_name`, `og:locale`, image dimensions & alt → FIX | Missing `og:site_name`, `og:locale`, image dims/alt, article times → FIX | Minimal safe OG |
| **X / Twitter Cards (complete)** | Missing `twitter:image:alt` → FIX | Missing `twitter:title/description/image/alt` → FIX | Missing `twitter:title/description/image/alt` → FIX | Minimal |
| **Favicon & Apple Touch Icon** | Missing `apple-touch-icon` & `site.webmanifest` → FIX | Missing `apple-touch-icon` & `site.webmanifest` → FIX | Missing `apple-touch-icon` & `site.webmanifest` → FIX | ADD |
| **Exactly one primary `<h1>`** | PASS | **FAIL (0 `<h1>` tags)** → FIX | PASS | ADD |
| **Logical Heading Hierarchy** | PASS (`H1 → H2 → H3`) | **FAIL (no `<h1>`)** → FIX | PASS (`H1 → H2`) | PASS |
| **Semantic Landmarks** | PASS (`header`, `nav`, `main`, `footer`) | **FAIL (no `<main>`)** → FIX | PASS (`header`, `main`, `article`, `footer`) | PASS |
| **Image `alt`, `width`, `height`** | PASS (`icon-64.png` optimization added) | Missing `width`/`height` on nav icon → FIX | Missing `width`/`height` on nav icon → FIX | PASS |
| **JSON-LD Validity & Policy** | **FAIL (FAQPage Q3/Q4 mismatch visible DOM)** → FIX + add `WebSite`/`WebPage` | PASS (expand with `BreadcrumbList` & publisher) | **FAIL (deprecated `HowTo`)** → Replace with `TechArticle` + `BreadcrumbList` | None needed |

---

## 2. Indexability, URL Architecture & Crawl Hygiene

- **HTTPS & Canonical Domain:** GitHub Pages serves `https://evendisplay.amulyagupta.in/` via `site/CNAME`. All canonical links, OG URLs, `robots.txt`, and `sitemap.xml` standardize on `https://evendisplay.amulyagupta.in` (no `www`, no `http://`, no trailing slash on `.html` files, single trailing slash on root `/`).
- **URL Architecture:** Existing public URLs (`/`, `/studio.html`, `/macbook-vertical-bands-guide.html`) are clean, descriptive, hyphenated, and free of random IDs or query parameters. Kept unchanged to avoid redirect churn.
- **Internal Linking:**
  - `/` links cleanly to `/studio.html`, `/macbook-vertical-bands-guide.html`, `#install`, `#screen-issues`, `#calibration`, and `#faq`.
  - `/studio.html` links back to `/` and adds a subtle unobtrusive link to `/macbook-vertical-bands-guide.html` (without obstructing the full-screen canvas).
  - `/macbook-vertical-bands-guide.html` links directly to `/` (`index.html`), `/studio.html`, and `/#install`.
  - `/404.html` links to all three primary routes so dead links recover cleanly.
- **JavaScript Rendering:** Core copy, headings, FAQ answers, install instructions, and guide steps are static HTML — fully readable without JS execution. Interactive WebGL canvas in `/` and `<canvas>` studio in `/studio.html` progressively enhance static landmarks.
- **Query Parameter Duplication:** `studio.html?selftest=1` is used only by automated tests. Self-referencing `<link rel="canonical" href="https://evendisplay.amulyagupta.in/studio.html" />` consolidates any query-string variants back to the clean canonical URL.

---

## 3. Image & Media Audit

- **Header Icon Optimization:** Replacing inline navbar `<img src="assets/icon.png">` (`512×512`, `94 KB`) with a crisp Retina-ready `site/assets/icon-64.png` (`64×64`, `~3 KB`) reduces initial navbar image transfer by **~96%** while preserving razor-sharp 2× Retina rendering at `24×24` and `28×28`.
- **Apple Touch Icon:** Generate `site/assets/apple-touch-icon.png` (`180×180`) via `sips` from the canonical `512×512` source icon.
- **Social Sharing Image (`site/assets/og-card.png`):** `1200×630` PNG (`66 KB`), explicitly dimensioned (`og:image:width`, `og:image:height`) with descriptive `og:image:alt` and `twitter:image:alt`, regenerated cleanly to reflect EvenDisplay's full MacBook screen diagnostic & calibration positioning.
- **Hero LCP Optimization:** The hero uses pure inline CSS + zero blocking external font/image/JS dependencies; the LCP element on `/` is the pure text `<h1>` headline (zero image network latency, zero lazy-loading conflict).
