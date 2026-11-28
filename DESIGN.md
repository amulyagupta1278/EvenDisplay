# EvenDisplay Design System (`DESIGN.md`)

> **Reference source:** Adapted from Apple's gallery design system (`awesome-design-md/apple/DESIGN.md`) for an open-source macOS display diagnostic & optical calibration toolkit.
> **Distinction:** Core palette (`#ffffff`, `#f5f5f7`, `#000000`, `#1d1d1f`, `#0066cc`, `#0071e3`, `#2997ff`), SF Pro Display/Text typography ladder (`400`/`600`), pill CTA grammar, alternating light/dark full-bleed sections, and single-shadow product elevation come from the Apple reference. EvenDisplay adaptations add the precision-framed interactive WebGL MacBook Pro Display Simulator, tabular-nums optical telemetry (`ΔL`, `ΔE`), CPU-safe 2D WebGL fallback, and direct-distribution utility tiles for macOS Homebrew/Gatekeeper commands.

## Palette
- **Pure White Canvas:** `#ffffff` — Primary hero and direct-distribution surfaces.
- **Parchment Surface:** `#f5f5f7` — Alternating editorial sections, utility panels, FAQ, and footer.
- **Obsidian Void:** `#000000` — Full-bleed dark Calibration Lab showcase backed by subtle WebGL optical light fields.
- **Hardware Bezel:** `#111216` / `#1d1d1f` — MacBook Pro lid bezel framing the interactive WebGL Retina panel.
- **Primary Ink (Light):** `#1d1d1f` · **Secondary Ink (Light):** `#515154` (≥7:1 contrast on `#ffffff` and `#f5f5f7`).
- **Primary Ink (Dark):** `#f5f5f7` · **Secondary Ink (Dark):** `#a1a1a6` (≥7.5:1 contrast on `#000000`).
- **Interactive Accent:** `#0066cc` (Action Blue), `#0071e3` (Focus / Hover Blue), `#2997ff` (Sky Link Blue on dark surfaces).
- **Hairlines:** `rgba(0, 0, 0, 0.09)` on light, `rgba(255, 255, 255, 0.14)` on dark.

## Typography
- **Display & UI:** `-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Inter", system-ui, sans-serif`
- **Code & Telemetry Only:** `ui-monospace, "SF Mono", Menlo, Monaco, monospace` with `font-variant-numeric: tabular-nums` (never used decoratively on headings or labels).
- **Scale:** Hero `clamp(36px, 4.4vw, 56px)` / `600` / `1.07` / `-0.025em`; Section H2 `clamp(28px, 3.2vw, 40px)` / `600` / `1.10` / `-0.018em`; Body `17px` / `400` / `1.47`.

## Craft Rules
- No eyebrows/kickers above headings; headings carry their own weight.
- No decorative section numbers (`01/02/03`) or uniform icon-card grids.
- Exactly one drop-shadow (`0 24px 60px rgba(0, 0, 0, 0.20)`) on the interactive MacBook Pro simulator frame resting on white.
- Drawn `1.5px`-stroke inline SVGs instead of raw Unicode arrows or glyphs.
- Themed browser surfaces (`::selection`, `:focus-visible`, custom range controls, `text-wrap: balance`, `prefers-reduced-motion`).
