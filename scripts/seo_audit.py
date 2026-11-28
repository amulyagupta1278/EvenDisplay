#!/usr/bin/env python3
"""
Comprehensive automated Technical SEO, Structured Data, Accessibility & Performance audit
for EvenDisplay (serves site/ over real local HTTP and validates rendered output).
"""
import functools
import html
import http.server
import json
import pathlib
import re
import socketserver
import subprocess
import sys
import tempfile
import threading
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from html.parser import HTMLParser

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
CONFIG_PATH = SITE / "seo-config.json"
CHROME = pathlib.Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")


class PageInspector(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.html_lang = None
        self.title = ""
        self._in_title = False
        self.metas = []
        self.links = []
        self.imgs = []
        self.anchors = []
        self.headings = []
        self._cur_heading = None
        self._heading_buf = []
        self.landmarks = set()
        self.ld_blocks = []
        self._in_ld = False
        self._ld_buf = []
        self.faq_summaries = []
        self._in_summary = False
        self._summary_buf = []
        self.faq_answers = []
        self._in_faq_p = False
        self._faq_p_buf = []
        self.inputs = []
        self.labels_for = set()
        self.scripts = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "html":
            self.html_lang = a.get("lang")
        elif tag == "title":
            self._in_title = True
        elif tag == "meta":
            self.metas.append(a)
        elif tag == "link":
            self.links.append(a)
        elif tag == "img":
            self.imgs.append(a)
        elif tag == "a":
            self.anchors.append(a)
        elif tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            self._cur_heading = tag
            self._heading_buf = []
        elif tag in ("header", "nav", "main", "footer", "article"):
            self.landmarks.add(tag)
        elif tag == "script":
            self.scripts.append(a)
            if a.get("type") == "application/ld+json":
                self._in_ld = True
                self._ld_buf = []
        elif tag == "summary":
            self._in_summary = True
            self._summary_buf = []
        elif tag == "p" and "faq-answer" in (a.get("class") or ""):
            self._in_faq_p = True
            self._faq_p_buf = []
        elif tag == "input":
            self.inputs.append(a)
        elif tag == "label" and a.get("for"):
            self.labels_for.add(a["for"])

    def handle_endtag(self, tag):
        if tag == "title":
            self._in_title = False
        elif tag == self._cur_heading:
            text = re.sub(r"\s+", " ", "".join(self._heading_buf)).strip()
            self.headings.append((tag, text))
            self._cur_heading = None
        elif tag == "script" and self._in_ld:
            self.ld_blocks.append("".join(self._ld_buf).strip())
            self._in_ld = False
        elif tag == "summary" and self._in_summary:
            self.faq_summaries.append(re.sub(r"\s+", " ", "".join(self._summary_buf)).strip())
            self._in_summary = False
        elif tag == "p" and self._in_faq_p:
            self.faq_answers.append(re.sub(r"\s+", " ", "".join(self._faq_p_buf)).strip())
            self._in_faq_p = False

    def handle_data(self, data):
        if self._in_title:
            self.title += data
        if self._cur_heading:
            self._heading_buf.append(data)
        if self._in_ld:
            self._ld_buf.append(data)
        if self._in_summary:
            self._summary_buf.append(data)
        if self._in_faq_p:
            self._faq_p_buf.append(data)


class GitHubPagesHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def send_error(self, code, message=None, explain=None):
        if code == 404:
            not_found = SITE / "404.html"
            if not_found.exists():
                body = not_found.read_bytes()
                self.send_response(404)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return
        super().send_error(code, message, explain)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def http_get(url: str):
    opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(url, timeout=3) as resp:
            return resp.status, dict(resp.headers), resp.read()
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers), e.read()


def fs_get(path: str):
    clean = path.split("?")[0].split("#")[0]
    if clean in ("", "/"):
        target = SITE / "index.html"
    else:
        target = SITE / clean.lstrip("/")
    if target.is_dir():
        target = target / "index.html"
    if target.exists() and target.is_file():
        return 200, {}, target.read_bytes()
    nf = SITE / "404.html"
    if nf.exists():
        return 404, {}, nf.read_bytes()
    return 404, {}, b""


def main() -> int:
    cfg = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    site_cfg = cfg["site"]
    base_prod = site_cfg["baseUrl"].rstrip("/")
    routes = cfg["routes"]

    passed = 0
    failed = 0
    warnings = []

    def check(cond: bool, msg: str):
        nonlocal passed, failed
        if cond:
            passed += 1
            print(f"  [PASS] {msg}")
        else:
            failed += 1
            print(f"  [FAIL] {msg}")

    httpd = None
    use_http = False
    local_base = ""
    try:
        handler = functools.partial(GitHubPagesHandler, directory=str(SITE))
        httpd = socketserver.ThreadingTCPServer(("127.0.0.1", 0), handler)
        port = httpd.server_address[1]
        thread = threading.Thread(target=httpd.serve_forever, daemon=True)
        thread.start()
        local_base = f"http://127.0.0.1:{port}"
        probe_st, _, _ = http_get(f"{local_base}/robots.txt")
        if probe_st == 200:
            use_http = True
    except Exception:
        use_http = False

    def fetch(path: str):
        if use_http:
            return http_get(f"{local_base}{path}")
        return fs_get(path)

    if not use_http:
        print("  [INFO] Loopback HTTP unavailable in sandbox; validating via static route resolver + Chrome file://")

    try:
        # 1. CNAME, robots.txt, sitemap.xml, site.webmanifest
        cname = (SITE / "CNAME").read_text(encoding="utf-8").strip()
        check(f"https://{cname}" == base_prod, f"CNAME matches production domain ({cname})")

        st, _, body = fetch("/robots.txt")
        robots_txt = body.decode("utf-8", errors="replace")
        check(st == 200, "robots.txt responds HTTP 200")
        check("Allow: /" in robots_txt and "Disallow: /assets" not in robots_txt, "robots.txt allows public pages and assets")
        check(f"Sitemap: {base_prod}/sitemap.xml" in robots_txt, "robots.txt references production sitemap.xml")

        st, _, body = fetch("/sitemap.xml")
        check(st == 200, "sitemap.xml responds HTTP 200")
        sitemap_text = body.decode("utf-8", errors="replace")
        check("<priority>" not in sitemap_text and "<changefreq>" not in sitemap_text, "sitemap.xml omits Google-ignored <priority>/<changefreq>")
        root_xml = ET.fromstring(sitemap_text)
        ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
        sitemap_locs = [el.text.strip() for el in root_xml.findall("sm:url/sm:loc", ns)]
        expected_locs = [f"{base_prod}{r['path']}" for r in routes if r.get("inSitemap")]
        check(sitemap_locs == expected_locs, f"sitemap.xml contains exact canonical indexable URLs ({len(sitemap_locs)})")
        check(all("404" not in u and "localhost" not in u and u.startswith("https://") for u in sitemap_locs), "sitemap.xml contains no 404/localhost/non-HTTPS URLs")

        st, _, body = fetch("/site.webmanifest")
        check(st == 200 and json.loads(body.decode("utf-8")).get("short_name") == "EvenDisplay", "site.webmanifest responds HTTP 200 and parses cleanly")

        # 2. Custom 404 behavior
        st_404, _, body_404 = fetch("/nonexistent-seo-audit-check-path")
        p404 = PageInspector()
        p404.feed(body_404.decode("utf-8", errors="replace"))
        robots_404 = next((m.get("content", "") for m in p404.metas if m.get("name") == "robots"), "")
        check(st_404 == 404, "Missing route returns HTTP 404 (not soft-404)")
        check("noindex" in robots_404.lower(), "404.html declares noindex directive")

        # 3. Inspect all indexable routes
        seen_titles = {}
        seen_descs = {}
        secret_patterns = [
            re.compile(r"AIza[0-9A-Za-z\-_]{20,}"),
            re.compile(r"ghp_[0-9A-Za-z]{20,}"),
            re.compile(r"sk-[0-9A-Za-z]{20,}"),
            re.compile(r"YOUR_[A-Z_]+_TOKEN"),
        ]

        for r in routes:
            if not r.get("inSitemap"):
                continue
            path = r["path"]
            st, _, raw = fetch(path)
            text = raw.decode("utf-8", errors="replace")
            check(st == 200, f"{path}: HTTP 200 with zero redirect chain")

            insp = PageInspector()
            insp.feed(text)

            check(insp.html_lang == "en", f"{path}: <html lang=\"en\"> present")
            title = insp.title.strip()
            check(10 <= len(title) <= 72 and "EvenDisplay" in title, f"{path}: clean title ({len(title)} chars)")
            check(title not in seen_titles, f"{path}: unique title")
            seen_titles[title] = path

            meta_map = {m.get("name"): m.get("content", "") for m in insp.metas if m.get("name")}
            og_map = {m.get("property"): m.get("content", "") for m in insp.metas if m.get("property")}

            desc = meta_map.get("description", "").strip()
            check(80 <= len(desc) <= 170, f"{path}: concise meta description ({len(desc)} chars)")
            check(desc not in seen_descs, f"{path}: unique meta description")
            seen_descs[desc] = path

            check("keywords" not in meta_map, f"{path}: no obsolete <meta name=\"keywords\">")
            check("viewport" in meta_map and "width=device-width" in meta_map["viewport"], f"{path}: valid viewport meta")
            robots_val = meta_map.get("robots", "").lower()
            check("index" in robots_val and "noindex" not in robots_val and "follow" in robots_val, f"{path}: valid indexable robots directive")

            canon = next((l.get("href", "") for l in insp.links if l.get("rel") == "canonical"), "")
            expected_canon = f"{base_prod}{path}"
            check(canon == expected_canon, f"{path}: canonical matches {expected_canon}")
            check("localhost" not in canon and "127.0.0.1" not in canon, f"{path}: no localhost in canonical")

            # OpenGraph & Twitter Cards
            req_og = ["og:type", "og:site_name", "og:locale", "og:title", "og:description", "og:url", "og:image", "og:image:width", "og:image:height", "og:image:alt"]
            check(all(og_map.get(k) for k in req_og), f"{path}: complete Open Graph metadata")
            req_tw = ["twitter:card", "twitter:title", "twitter:description", "twitter:image", "twitter:image:alt"]
            check(all(meta_map.get(k) for k in req_tw), f"{path}: complete X/Twitter Card metadata")
            check(og_map.get("og:image", "").startswith(base_prod), f"{path}: og:image uses production HTTPS URL")

            # Icons & Manifest links resolve HTTP 200
            icon_hrefs = [l.get("href") for l in insp.links if l.get("rel") in ("icon", "apple-touch-icon", "manifest") and l.get("href")]
            check(len(icon_hrefs) >= 3, f"{path}: favicon, apple-touch-icon & manifest declared")
            all_icons_ok = True
            for href in icon_hrefs:
                rel_path = urllib.parse.urljoin(path, href)
                ist, _, _ = fetch(rel_path)
                if ist != 200:
                    all_icons_ok = False
            check(all_icons_ok, f"{path}: all icon/manifest references return HTTP 200")

            # HTML Structure & Accessibility basics
            h1s = [h for h in insp.headings if h[0] == "h1"]
            check(len(h1s) == 1 and len(h1s[0][1]) >= 10, f"{path}: exactly one meaningful <h1>")
            check("main" in insp.landmarks, f"{path}: <main> landmark present")

            imgs_ok = all(("alt" in im) and im.get("width") and im.get("height") for im in insp.imgs)
            check(imgs_ok, f"{path}: all <img> elements have alt, width, and height")

            # Verify every internal link resolves HTTP 200
            broken_links = []
            for a in insp.anchors:
                href = (a.get("href") or "").strip()
                if not href or href.startswith("#") or href.startswith("http://") or href.startswith("https://") or href.startswith("mailto:"):
                    continue
                target_path = urllib.parse.urljoin(path, href.split("#")[0])
                lst, _, _ = fetch(target_path)
                if lst != 200:
                    broken_links.append((href, lst))
            check(not broken_links, f"{path}: zero broken internal links" + (f" ({broken_links})" if broken_links else ""))

            # Structured Data JSON-LD validation
            check(len(insp.ld_blocks) >= 1, f"{path}: includes JSON-LD structured data")
            for idx, blk in enumerate(insp.ld_blocks):
                data = json.loads(blk)
                raw_ld = json.dumps(data)
                check('"HowTo"' not in raw_ld, f"{path}: JSON-LD #{idx+1} does not use deprecated HowTo")
                check('"aggregateRating"' not in raw_ld and '"reviewCount"' not in raw_ld, f"{path}: JSON-LD #{idx+1} has no fabricated ratings")
                nodes = data.get("@graph", [data])
                for node in nodes:
                    if node.get("@type") == "FAQPage":
                        ld_qs = [q["name"].strip() for q in node.get("mainEntity", [])]
                        ld_as = [re.sub(r"\s+", " ", q["acceptedAnswer"]["text"]).strip() for q in node.get("mainEntity", [])]
                        check(ld_qs == insp.faq_summaries, f"{path}: FAQPage JSON-LD questions match visible DOM verbatim")
                        check(ld_as == insp.faq_answers, f"{path}: FAQPage JSON-LD answers match visible DOM verbatim")

            # Secret / placeholder leak check
            leaked = any(pat.search(text) for pat in secret_patterns)
            check(not leaked, f"{path}: no exposed secrets or placeholder tokens")

            if path == "/":
                check('id="waitlist-form"' in text and "formsubmit.co/ajax/amulyagupta2001@gmail.com" in text, "/: v2/v3 waitlist form wired to FormSubmit AJAX endpoint")
                check("waitlist-email" in insp.labels_for, "/: waitlist email input has explicit <label>")
                check("mailto:amulyagupta2001@gmail.com" in text, "/: waitlist includes direct mailto fallback")

        # 4. Headless Chrome Rendered DOM Check
        if CHROME.exists():
            for r in routes:
                if not r.get("inSitemap"):
                    continue
                path = r["path"]
                target_url = f"{local_base}{path}" if use_http else f"file://{SITE / r['file']}"
                with tempfile.TemporaryDirectory() as prof:
                    out = subprocess.check_output(
                        [
                            str(CHROME),
                            "--headless=new",
                            "--disable-gpu",
                            "--no-sandbox",
                            f"--user-data-dir={prof}",
                            "--window-size=1440,900",
                            "--virtual-time-budget=1500",
                            "--dump-dom",
                            target_url,
                        ],
                        stderr=subprocess.DEVNULL,
                    ).decode("utf-8", errors="replace")
                    check("<h1" in out and "EvenDisplay" in out, f"{path}: renders <h1> and content in headless Chrome")
        else:
            warnings.append("Chrome binary not found; skipped rendered-DOM check.")

        print(f"\nSEO Audit Summary: {passed} passed, {failed} failed, {len(warnings)} warnings.")
        for w in warnings:
            print(f"  [WARN] {w}")
        return 0 if failed == 0 else 1
    finally:
        if httpd:
            httpd.shutdown()
            httpd.server_close()


if __name__ == "__main__":
    raise SystemExit(main())
