# Phase 5 — Structured Data (Schema.org / JSON-LD) Implementation

**Date:** 2026-11-28  
**Source of Truth:** `site/seo-config.json` (synced via `scripts/seo_sync.py`, validated by `scripts/seo_audit.py`).

---

## 1. Schema Graph Architecture by Route

| Route | Schema Types Implemented | Policy Compliance Notes |
|---|---|---|
| `/` (`index.html`) | `Person` (`#author`), `WebSite` (`#website`), `WebPage` (`#webpage`), `SoftwareApplication` (`#software`), `FAQPage` (`#faq`) | Interlinked via `@id`. `SoftwareApplication` includes only verified truthful fields (`name`, `operatingSystem`, `applicationCategory`, `softwareVersion: 1.0.0`, `downloadUrl`, `codeRepository`, `license: MIT`, `offers: $0 USD`, `author`). Zero fabricated `aggregateRating` or `reviewCount`. Every `FAQPage` question and answer is programmatically verified by `scripts/seo_audit.py` to match the visible `<details>`/`<summary>`/`.faq-answer` DOM verbatim. |
| `/studio.html` | `WebApplication` (`#app`), `BreadcrumbList` | Accurately describes the zero-install HTML5 Canvas browser studio (`price: 0 USD`, `MIT`, `author`), linked via 2-level breadcrumb back to `/`. |
| `/macbook-vertical-bands-guide.html` | `TechArticle` (`#article`), `BreadcrumbList` | **Replaced deprecated `HowTo` schema** (deprecated by Google in 2023) with `TechArticle` featuring truthful `datePublished` (`2026-11-25`), `dateModified` (`2026-11-28`), visible headline match, `author`, `publisher`, `image` (`1200×630`), and `BreadcrumbList`. |
| `/404.html` | None | Intentionally omitted on `noindex, follow` error route. |

---

## 2. Explicit Anti-Fabrication Verification

Automated checks in `scripts/seo_audit.py` enforce:
- **Zero deprecated types:** Rejects `"HowTo"` in any JSON-LD block.
- **Zero fabricated trust signals:** Rejects `"aggregateRating"` and `"reviewCount"` unless backed by verifiable first-party reviews (none exist yet).
- **Verbatim FAQ DOM parity:** Extracts every `<summary>` and `<p class="faq-answer">` from `index.html` and asserts exact string equality with `FAQPage.mainEntity`.

---

## 3. Manual Post-Deploy Validation Tools

Once `origin/main` is pushed and live at `https://evendisplay.amulyagupta.in/`:
1. **Google Rich Results Test:** https://search.google.com/test/rich-results — test `/`, `/studio.html`, and `/macbook-vertical-bands-guide.html`.
2. **Schema.org Validator:** https://validator.schema.org/ — confirm clean `@graph` entity resolution across all 3 canonical URLs.
