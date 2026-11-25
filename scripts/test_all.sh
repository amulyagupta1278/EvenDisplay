#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== 1/3 Native macOS Swift Test Suite ==="
TMP_BIN="/tmp/evendisplay_tests_$$"
swiftc -parse-as-library -DEVENDISPLAY_TEST \
    -framework Cocoa \
    -framework SwiftUI \
    -framework ServiceManagement \
    -framework UniformTypeIdentifiers \
    "$ROOT_DIR/macos/Sources/main.swift" \
    "$ROOT_DIR/macos/Tests/EvenDisplayTests.swift" \
    -o "$TMP_BIN"
"$TMP_BIN"
rm -f "$TMP_BIN"

echo ""
echo "=== 2/3 Web Calibration Studio (Headless Chrome) ==="
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [ -x "$CHROME" ]; then
    TMP_PROFILE="/tmp/evendisplay_chrome_$$"
    rm -rf "$TMP_PROFILE"
    "$CHROME" --headless=new --disable-gpu --no-sandbox \
        --user-data-dir="$TMP_PROFILE" \
        --window-size=1280,820 \
        --dump-dom "file://$ROOT_DIR/site/studio.html?selftest=1" 2>/dev/null \
    | /opt/homebrew/bin/python3.13 -c '
import sys, re, json
dom = sys.stdin.read()
m = re.search(r"<pre id=\"selftest-result\">([\s\S]*?)</pre>", dom)
if not m:
    print("FAIL: selftest-result missing")
    sys.exit(1)
data = json.loads(m.group(1).replace("&gt;", ">").replace("&lt;", "<").replace("&amp;", "&"))
for r in data["results"]:
    status = "PASS" if r["pass"] else "FAIL"
    print(f"  [{status}] " + r["name"])
p, f = data["passed"], data["failed"]
print(f"Summary: {p} passed, {f} failed.")
sys.exit(0 if f == 0 else 1)
'
    rm -rf "$TMP_PROFILE"
else
    echo "Chrome not found — skipping browser check."
fi

echo ""
echo "=== 3/3 SEO, Metadata & JSON-LD Validation ==="
/opt/homebrew/bin/python3.13 - "$ROOT_DIR/site" <<'PY'
import sys, re, json, pathlib

site = pathlib.Path(sys.argv[1])
passed = 0
failed = 0

def expect(cond, msg):
    global passed, failed
    if cond:
        passed += 1
        print(f"  [PASS] {msg}")
    else:
        failed += 1
        print(f"  [FAIL] {msg}")

expect((site / "CNAME").read_text().strip() == "evendisplay.amulyagupta.in", "CNAME points to evendisplay.amulyagupta.in")
expect("sitemap.xml" in (site / "robots.txt").read_text(), "robots.txt references sitemap.xml")
sitemap = (site / "sitemap.xml").read_text()
expect("https://evendisplay.amulyagupta.in/" in sitemap and "studio.html" in sitemap and "macbook-vertical-bands-guide.html" in sitemap, "sitemap.xml lists all 3 pages")
expect((site / "assets/icon.png").exists() and (site / "assets/og-card.png").exists(), "icon.png and og-card.png assets exist")

for page in ["index.html", "studio.html", "macbook-vertical-bands-guide.html"]:
    html = (site / page).read_text()
    expect("<title>" in html and "EvenDisplay" in html, f"{page}: has EvenDisplay <title>")
    expect('name="description"' in html, f"{page}: has meta description")
    expect('rel="canonical"' in html, f"{page}: has canonical URL")
    expect('property="og:image"' in html, f"{page}: has og:image social card")
    ld_blocks = re.findall(r'<script type="application/ld\+json">([\s\S]*?)</script>', html)
    expect(len(ld_blocks) >= 1, f"{page}: includes JSON-LD structured data")
    for block in ld_blocks:
        try:
            json.loads(block)
            expect(True, f"{page}: JSON-LD parses cleanly")
        except Exception as e:
            expect(False, f"{page}: JSON-LD invalid: {e}")

print(f"Summary: {passed} passed, {failed} failed.")
sys.exit(0 if failed == 0 else 1)
PY
