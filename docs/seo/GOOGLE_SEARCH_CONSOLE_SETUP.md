# Phase 7 — Google Search Console Readiness & Setup Runbook

**Date:** 2026-11-28  
**Production Domain:** `https://evendisplay.amulyagupta.in/`  
**Sitemap URL:** `https://evendisplay.amulyagupta.in/sitemap.xml`  
**Robots URL:** `https://evendisplay.amulyagupta.in/robots.txt`

---

## 1. Technical Prerequisites Completed in Repository

- [x] `site/CNAME` configured to `evendisplay.amulyagupta.in`.
- [x] `.github/workflows/pages.yml` fixed to GitHub's 2-job `build` → `deploy` architecture (awaiting push approval to deploy live).
- [x] Self-referencing HTTPS canonical URLs on all 3 indexable routes.
- [x] Valid `robots.txt` allowing public pages & assets and declaring `Sitemap: https://evendisplay.amulyagupta.in/sitemap.xml`.
- [x] Valid `sitemap.xml` listing strictly the 3 canonical indexable URLs with accurate `lastmod`.
- [x] Custom `site/404.html` with `noindex, follow` (excluded from sitemap).
- [x] Environment-driven `<meta name="google-site-verification" ...>` hook built into `scripts/seo_sync.py` (`EVENDISPLAY_GSC_TOKEN`), remaining cleanly omitted until you supply a real token.

---

## 2. Recommended Property Type: Domain Property vs. URL Prefix

| Option | Recommendation | Why |
|---|---|---|
| **Domain Property** (`evendisplay.amulyagupta.in` or root `amulyagupta.in`) | **Recommended (Primary)** | Tracks all protocols (`http`/`https`), subdomains, and redirect behavior in one unified view via a single DNS `TXT` record. |
| **URL Prefix Property** (`https://evendisplay.amulyagupta.in/`) | **Optional Secondary** | Fast verification via `<meta name="google-site-verification">` if you prefer not to edit DNS, or if you want subdomain-isolated Search Console reports. |

---

## 3. Manual Setup Steps (Require Your Google Account / DNS Access)

### Step A — Deploy First
1. Approve pushing the local commits in `EvenDisplay-live` to `origin/main` so GitHub Pages deploys `https://evendisplay.amulyagupta.in/`.
2. Confirm in your browser that `https://evendisplay.amulyagupta.in/`, `https://evendisplay.amulyagupta.in/robots.txt`, and `https://evendisplay.amulyagupta.in/sitemap.xml` return HTTP `200` over HTTPS with a valid TLS certificate.

### Step B — Create & Verify Property in Google Search Console
1. Open https://search.google.com/search-console/ and click **Add property**.
2. **Option 1 (DNS TXT — Recommended):**
   - Enter `evendisplay.amulyagupta.in` under **Domain**.
   - Copy the `google-site-verification=...` `TXT` value from Google.
   - Add a `TXT` record in your `amulyagupta.in` DNS provider for host `evendisplay` (TTL Auto / 300s).
   - Wait 2–10 minutes and click **Verify**.
3. **Option 2 (HTML Meta Tag — URL Prefix):**
   - Enter `https://evendisplay.amulyagupta.in/` under **URL prefix**.
   - Choose **HTML tag**, copy only the `content="..."` token.
   - Run locally: `EVENDISPLAY_GSC_TOKEN="<your-token>" make seo-sync` (or set `site.verification.google` in `site/seo-config.json`), push to `main`, wait for Pages deploy, and click **Verify**.

### Step C — Submit Sitemap & Inspect Priority URLs
1. In Search Console → **Sitemaps**, submit: `https://evendisplay.amulyagupta.in/sitemap.xml` and confirm status **Success** with **3 discovered URLs**.
2. In **URL Inspection**, inspect each priority URL in order:
   - `https://evendisplay.amulyagupta.in/`
   - `https://evendisplay.amulyagupta.in/studio.html`
   - `https://evendisplay.amulyagupta.in/macbook-vertical-bands-guide.html`
3. Click **Test Live URL** to verify Googlebot sees HTTP `200`, your canonical URL, and rendered content, then click **Request Indexing**.
   - *Note:* Requesting indexing adds the URL to Google's crawl queue; it does **not** guarantee immediate indexing or ranking.

---

## 4. Post-Verification Monitoring Checklist (First 30 Days)

- **Page Indexing:** Confirm all 3 canonical URLs transition from *Discovered – currently not indexed* / *Crawled* → *Indexed*; ensure `404.html` and `?selftest=1` remain excluded.
- **HTTPS Report:** Verify 100% of indexed URLs are served over HTTPS (GitHub Pages **Enforce HTTPS** checked).
- **Core Web Vitals:** Monitor field LCP/INP/CLS once CrUX traffic threshold is reached.
- **Enhancements / Structured Data:** Verify zero invalid items in Unparsable Structured Data or Breadcrumbs reports.
- **Search Performance:** Track impressions, CTR, and queries (`MacBook dim vertical bands`, `MacBook screen test`, `EvenDisplay`) and refine title/description copy based on real CTR data.
