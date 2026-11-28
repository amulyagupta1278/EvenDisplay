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
echo "=== 3/3 SEO, Metadata, Sitemap, Schema & HTTP Audit ==="
/opt/homebrew/bin/python3.13 "$ROOT_DIR/scripts/seo_audit.py"
