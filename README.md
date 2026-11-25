# EvenDisplay

**Free, open-source vertical band compensator, 50% gray display uniformity tester, and IPS pixel sweep utility for MacBook displays.**

- **Live Website & Web Studio:** https://evendisplay.amulyagupta.in/
- **Downloads:** https://github.com/amulyagupta1278/EvenDisplay/releases

> **Honest Scope:** No software can physically repair a failing LCD column driver (COF) or worn hinge display flex cable. EvenDisplay gives you a **100% reversible click-through macOS overlay** that visually blends dim vertical columns across grays and light backgrounds—plus full-screen 9-color diagnostics and an IPS pixel sweep—without touching macOS system files, ColorSync ICC profiles, or NVRAM.

---

## Features

- **2 Directly Movable & Resizable Bands:** Drag Band 1 and Band 2 (or up to 6 bands) directly over dim vertical columns on your MacBook display and resize their edges pixel-by-pixel.
- **Persistent Multi-Color Verification:** Keep calibrated bands locked while cycling **50% Gray, 25% Gray, 75% Gray, 10% Dark, White, Red, Green, Blue, and Black** (`1`–`9`).
- **Dual-Mode Compensation:** Lift dim columns on gray (`-25%` to `+25%`), tune warm/cool tint, feather edges (`0–16 px`), and gently dim surroundings (`0–20%`) for pure white screens.
- **Built-In Display Lock:** Uses `CGDisplayIsBuiltin` so external monitors are never tinted.
- **100% Reversible & Safe:** Full Undo/Redo (`Cmd+Z` / `Cmd+Shift+Z`), Compare Original (`C`), named Light/Dark checkpoints, Launch at Login, Panic Revert to Stock (`Cmd+Option+0`), and Factory Reset.
- **Shared `.evendisplay.json` Profiles:** Calibrate in the Web Studio and import straight into `EvenDisplay.app`.

---

## Local Build & Test

```bash
# Build EvenDisplay.app (with generated icon + OG card) & dist/EvenDisplay-v1.0.0.zip
./scripts/build_mac.sh

# Run Swift native tests, headless Chrome Web Studio tests, and SEO checks
./scripts/test_all.sh
```

## Custom Subdomain DNS Setup (`evendisplay.amulyagupta.in`)

At your DNS registrar for `amulyagupta.in`, add one free `CNAME` record:

| Type | Host / Name | Value / Target |
|---|---|---|
| `CNAME` | `evendisplay` | `amulyagupta1278.github.io` |

GitHub Pages automatically reads `site/CNAME`, deploys `site/` via `.github/workflows/pages.yml`, and provisions free HTTPS.

## License

MIT — see [LICENSE](LICENSE).
