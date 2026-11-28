# Phase 1 — Official Technical SEO & Platform Research

**Research Date:** 2026-11-28  
**Methodology:** Grounded strictly in current primary documentation from Google Search Central, Schema.org, Open Graph Protocol, X Developer Docs, and Bing Webmaster Guidelines. Outdated SEO blog myths are explicitly separated from actual engine requirements.

---

## 1. Primary Sources Consulted

- **Google Search Central Documentation:** https://developers.google.com/search/docs
- **Google Search Essentials:** https://developers.google.com/search/docs/essentials
- **Google SEO Starter Guide:** https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- **Google Crawling & Indexing Overview:** https://developers.google.com/search/docs/crawling-indexing
- **Google Sitemaps Overview:** https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview
- **Google Robots.txt Introduction:** https://developers.google.com/search/docs/crawling-indexing/robots/intro
- **Google Canonicalization:** https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
- **Google Structured Data Guidelines:** https://developers.google.com/search/docs/appearance/structured-data/intro-structured-data
- **Google Core Web Vitals & Page Experience:** https://developers.google.com/search/docs/appearance/core-web-vitals
- **Google Search Console Help:** https://support.google.com/webmasters/
- **PageSpeed Insights:** https://pagespeed.web.dev/
- **Schema.org Vocabulary:** https://schema.org/
- **Open Graph Protocol:** https://ogp.me/
- **X (Twitter) Cards Markup:** https://developer.x.com/en/docs/twitter-for-websites/cards/overview/abouts-cards
- **Bing Webmaster Guidelines:** https://www.bing.com/webmasters/help/webmaster-guidelines-30fba23a
- **IndexNow Protocol:** https://www.indexnow.org/

---

## 2. Classification of Practices

### A. Actual Google Indexing & Technical Requirements
1. **Crawlable HTTP 200 HTML with indexable text:** Googlebot must be able to fetch public pages (HTTP `200`), render core text/links, and not encounter `noindex` or accidental `robots.txt` blocks on required assets (CSS/JS/images).
2. **`robots.txt` controls crawling, NOT indexing:** Blocking a page in `robots.txt` prevents Googlebot from reading `<meta name="robots" content="noindex">`. Pages meant to stay out of the index (such as `404.html` or private routes) must return HTTP `404` or carry `noindex` while remaining crawlable.
3. **Truthful, visible-content-matched Structured Data:** Every field in JSON-LD (`SoftwareApplication`, `TechArticle`, `FAQPage`, etc.) must accurately represent content visible to users on the same page. Fabricated `aggregateRating`, `reviewCount`, prices, or hidden text violate Google's spam & structured-data policies.
4. **Self-referencing absolute canonical URLs (`rel="canonical"`):** Each indexable page should declare its exact HTTPS canonical URL on the production domain (`https://evendisplay.amulyagupta.in/...`) to prevent protocol, `www`, trailing-slash, or query-parameter duplication.
5. **Valid XML Sitemap containing only canonical, indexable URLs:** Referenced via `Sitemap:` in `/robots.txt` and submitted in Google Search Console.

### B. Recommended Best Practices
1. **Core Web Vitals targets (75th percentile of real user visits):**
   - **LCP (Largest Contentful Paint):** `<= 2.5s`
   - **INP (Interaction to Next Paint, replaced FID in March 2024):** `<= 200ms`
   - **CLS (Cumulative Layout Shift):** `<= 0.1`
2. **Unique, descriptive `<title>` and `<meta name="description">` per route:** Clear product/problem phrasing without keyword stuffing.
3. **Accurate `lastmod` in XML sitemaps:** Google uses `<lastmod>` **only when consistently accurate** (tied to real content modifications, never auto-bumped daily on unchanged files).
4. **Semantic HTML & Accessibility:** Exactly one primary `<h1>` per page, logical `<h2>`/`<h3>` hierarchy, descriptive link text, `alt` attributes, explicit `width`/`height` on `<img>`, and keyboard/focus accessibility.
5. **Rich Social Preview Cards (Open Graph + X Cards):** `1200×630` PNG/JPG with `og:title`, `og:description`, `og:url`, `og:type`, `og:image`, `og:image:width`, `og:image:height`, `og:image:alt`, `og:site_name`, plus `twitter:card="summary_large_image"` and matching Twitter tags.
6. **Bing + IndexNow:** Bing relies heavily on clean sitemaps, internal links, and IndexNow instant URL notifications (optional for static GitHub Pages once live).

### C. Optional / Nuanced Enhancements
1. **`FAQPage` JSON-LD:** Google restricted expandable FAQ rich results primarily to authoritative government and health sites and removed standard FAQ rich-result reporting from Search Console. However, `FAQPage` remains valid Schema.org markup that aids semantic understanding and AI citation **if and only if** every Q&A matches visible page content verbatim.
2. **`WebSite`, `WebPage`, `BreadcrumbList`, `TechArticle`, `WebApplication` JSON-LD:** Clean entity graph linking the homepage, Web Studio, and diagnostic guide under one publisher/author identity.
3. **`max-image-preview:large` robots directive:** Allows Google Discover and Google Search to display full-width preview thumbnails.
4. **Web App Manifest (`site.webmanifest`) & `apple-touch-icon` (`180×180`):** Improves macOS/iOS Safari bookmarking, pinning, and Apple-ecosystem presentation.

### D. Unsupported Myths & Deprecated Features (Do NOT Implement)
1. **`<meta name="keywords">`:** Explicitly ignored by Google Search for over a decade. Remove it.
2. **Sitemap `<priority>` and `<changefreq>`:** Explicitly ignored by Google's sitemap parser. Omit them to keep the sitemap clean and factual.
3. **`HowTo` JSON-LD for rich results:** Google fully deprecated HowTo rich results across mobile and desktop in 2023. Use `TechArticle` + `BreadcrumbList` for technical troubleshooting guides instead.
4. **Submitting an indexing request in Search Console ≠ guaranteed indexing:** Requesting indexing queues a crawl; Google independently evaluates quality, duplication, and demand.
5. **Fabricated ratings/reviews in `SoftwareApplication`:** Adding fake `aggregateRating` to chase stars violates Google structured-data spam guidelines and risks manual action.
6. **Thin doorway/comparison pages:** Creating auto-generated pages for every MacBook model year (`M1`, `M2`, `M3`, `M4`) with swapped words triggers Google's Scaled Content Abuse / Doorway policies.
