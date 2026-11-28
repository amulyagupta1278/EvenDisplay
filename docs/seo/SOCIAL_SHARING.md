# Phase 9 — Social Metadata & Brand Sharing Presentation

**Date:** 2026-11-28  
**Managed By:** `site/seo-config.json` → `scripts/seo_sync.py`.

---

## 1. Implemented Metadata Coverage

Every indexable page (`/`, `/studio.html`, `/macbook-vertical-bands-guide.html`) now emits complete, route-specific Open Graph and X/Twitter Card tags:

- **Open Graph:** `og:type` (`website` on `/` & `/studio.html`, `article` + `article:published_time`/`article:modified_time` on `/macbook-vertical-bands-guide.html`), `og:site_name` (`EvenDisplay`), `og:locale` (`en_US`), `og:title`, `og:description`, `og:url` (canonical HTTPS), `og:image`, `og:image:width` (`1200`), `og:image:height` (`630`), `og:image:alt`.
- **X / Twitter Cards:** `twitter:card` (`summary_large_image`), `twitter:title`, `twitter:description`, `twitter:image`, `twitter:image:alt`.
- **Apple / Browser Icons:** `icon-64.png` (`64×64`), `icon.png` (`512×512`), `apple-touch-icon.png` (`180×180`), `site.webmanifest` (`192×192` + `512×512`).

---

## 2. Social Preview Asset Audit (`site/assets/og-card.png`)

| Check | Measured Value | Status |
|---|---|---|
| Dimensions | `1200 × 630 px` (exact 1.905:1 OG/X ratio) | PASS |
| File Format & Size | PNG · `66,581 B` (`65 KB`) | PASS |
| Visual Inspection | Crisp light aluminum surface, `EvenDisplay` brand heading, `evendisplay.amulyagupta.in` URL, truthful Raw LCD vs. EvenDisplay ON split preview, zero fabricated UI ratings/claims | PASS |
| Public Accessibility | Served at `https://evendisplay.amulyagupta.in/assets/og-card.png` once deployed | PENDING DEPLOY |

---

## 3. Post-Deploy Live Preview Validators

After pushing to GitHub Pages, validate live sharing cards on:
- **Facebook / Meta Sharing Debugger:** https://developers.facebook.com/tools/debug/
- **LinkedIn Post Inspector:** https://www.linkedin.com/post-inspector/
- **X / Twitter Card Validator:** Paste `https://evendisplay.amulyagupta.in/` into X composer preview (or OpenGraph.xyz).
- **Meta Domain Verification (Optional):** Supply your Meta token via `EVENDISPLAY_META_TOKEN="..." make seo-sync` to emit `<meta name="facebook-domain-verification">`.
