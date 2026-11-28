#!/usr/bin/env python3
"""
Centralized SEO metadata, sitemap.xml, and robots.txt generator for EvenDisplay.
Reads site/seo-config.json (plus optional env vars for verification tokens and GA4)
and updates the managed <!-- SEO:START --> ... <!-- SEO:END --> block in each HTML route.
"""
import html
import json
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
CONFIG_PATH = SITE / "seo-config.json"


def esc(val: str) -> str:
    return html.escape(val, quote=True)


def render_head_block(site_cfg: dict, route: dict) -> str:
    base = site_cfg["baseUrl"].rstrip("/")
    social = site_cfg["socialImage"]
    social_url = f"{base}{social['path']}"
    canonical_url = f"{base}{route['path']}"
    is_noindex = "noindex" in route["robots"].lower()

    google_tok = os.environ.get("EVENDISPLAY_GSC_TOKEN", site_cfg["verification"].get("google", "")).strip()
    bing_tok = os.environ.get("EVENDISPLAY_BING_TOKEN", site_cfg["verification"].get("bing", "")).strip()
    meta_tok = os.environ.get("EVENDISPLAY_META_TOKEN", site_cfg["verification"].get("meta", "")).strip()
    ga4_id = os.environ.get("EVENDISPLAY_GA4_ID", site_cfg["analytics"].get("ga4MeasurementId", "")).strip()

    lines = [
        "  <!-- SEO:START -->",
        f"  <title>{esc(route['title'])}</title>",
        f'  <meta name="description" content="{esc(route["description"])}" />',
        f'  <meta name="robots" content="{esc(route["robots"])}" />',
        f'  <meta name="theme-color" content="{esc(route.get("themeColor", site_cfg["themeColorLight"]))}" />',
    ]

    if not is_noindex:
        lines.append(f'  <link rel="canonical" href="{esc(canonical_url)}" />')

    lines.extend([
        '  <link rel="icon" type="image/png" sizes="64x64" href="assets/icon-64.png" />',
        '  <link rel="icon" type="image/png" sizes="512x512" href="assets/icon.png" />',
        '  <link rel="apple-touch-icon" sizes="180x180" href="assets/apple-touch-icon.png" />',
        '  <link rel="manifest" href="site.webmanifest" />',
    ])

    if route["path"] == "/":
        if google_tok:
            lines.append(f'  <meta name="google-site-verification" content="{esc(google_tok)}" />')
        if bing_tok:
            lines.append(f'  <meta name="msvalidate.01" content="{esc(bing_tok)}" />')
        if meta_tok:
            lines.append(f'  <meta name="facebook-domain-verification" content="{esc(meta_tok)}" />')

    if ga4_id:
        lines.append(f'  <meta name="evendisplay-ga4-id" content="{esc(ga4_id)}" />')

    lines.extend([
        f'  <meta property="og:type" content="{esc(route["ogType"])}" />',
        f'  <meta property="og:site_name" content="{esc(site_cfg["name"])}" />',
        f'  <meta property="og:locale" content="{esc(site_cfg["locale"])}" />',
        f'  <meta property="og:title" content="{esc(route["ogTitle"])}" />',
        f'  <meta property="og:description" content="{esc(route["ogDescription"])}" />',
        f'  <meta property="og:url" content="{esc(canonical_url)}" />',
        f'  <meta property="og:image" content="{esc(social_url)}" />',
        f'  <meta property="og:image:width" content="{social["width"]}" />',
        f'  <meta property="og:image:height" content="{social["height"]}" />',
        f'  <meta property="og:image:alt" content="{esc(social["alt"])}" />',
    ])

    if route["ogType"] == "article":
        if route.get("datePublished"):
            lines.append(f'  <meta property="article:published_time" content="{esc(route["datePublished"])}" />')
        if route.get("lastmod"):
            lines.append(f'  <meta property="article:modified_time" content="{esc(route["lastmod"])}" />')

    lines.extend([
        '  <meta name="twitter:card" content="summary_large_image" />',
        f'  <meta name="twitter:title" content="{esc(route["twitterTitle"])}" />',
        f'  <meta name="twitter:description" content="{esc(route["twitterDescription"])}" />',
        f'  <meta name="twitter:image" content="{esc(social_url)}" />',
        f'  <meta name="twitter:image:alt" content="{esc(social["alt"])}" />',
    ])

    if route.get("jsonLd"):
        ld_json = json.dumps(route["jsonLd"], indent=2, ensure_ascii=False)
        indented = "\n".join("  " + ln for ln in ld_json.splitlines())
        lines.append('  <script type="application/ld+json">')
        lines.append(indented)
        lines.append("  </script>")

    lines.append("  <!-- SEO:END -->")
    return "\n".join(lines)


def render_sitemap(site_cfg: dict, routes: list) -> str:
    base = site_cfg["baseUrl"].rstrip("/")
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    ]
    for r in routes:
        if not r.get("inSitemap", False):
            continue
        loc = f"{base}{r['path']}"
        lines.append("  <url>")
        lines.append(f"    <loc>{esc(loc)}</loc>")
        if r.get("lastmod"):
            lines.append(f"    <lastmod>{esc(r['lastmod'])}</lastmod>")
        lines.append("  </url>")
    lines.append("</urlset>")
    return "\n".join(lines) + "\n"


def render_robots(site_cfg: dict) -> str:
    base = site_cfg["baseUrl"].rstrip("/")
    return (
        "User-agent: *\n"
        "Allow: /\n"
        "\n"
        f"Sitemap: {base}/sitemap.xml\n"
    )


def main() -> int:
    cfg = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    site_cfg = cfg["site"]
    routes = cfg["routes"]

    pattern = re.compile(r"  <!-- SEO:START -->[\s\S]*?  <!-- SEO:END -->")
    for route in routes:
        target = SITE / route["file"]
        if not target.exists():
            print(f"ERROR: missing route file {target}", file=sys.stderr)
            return 1
        content = target.read_text(encoding="utf-8")
        if not pattern.search(content):
            print(f"ERROR: missing <!-- SEO:START --> / <!-- SEO:END --> markers in {target}", file=sys.stderr)
            return 1
        block = render_head_block(site_cfg, route)
        updated = pattern.sub(lambda _: block, content, count=1)
        target.write_text(updated, encoding="utf-8")
        print(f"Synced metadata -> site/{route['file']}")

    (SITE / "sitemap.xml").write_text(render_sitemap(site_cfg, routes), encoding="utf-8")
    print("Generated -> site/sitemap.xml")

    (SITE / "robots.txt").write_text(render_robots(site_cfg), encoding="utf-8")
    print("Generated -> site/robots.txt")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
