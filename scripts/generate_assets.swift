import Cocoa
import Foundation

// Generates crisp macOS squircle iconset + 1200x630 OpenGraph social preview card for EvenDisplay.

func renderIcon(pixels: Int, points: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: points, height: points)

    NSGraphicsContext.saveGraphicsState()
    let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = nsCtx
    let ctx = nsCtx.cgContext
    let s = CGFloat(points)

    let pad = s * 0.08
    let tile = CGRect(x: pad, y: pad, width: s - pad * 2, height: s - pad * 2)
    let corner = tile.width * 0.225
    let squircle = CGPath(roundedRect: tile, cornerWidth: corner, cornerHeight: corner, transform: nil)

    ctx.saveGState()
    ctx.addPath(squircle)
    ctx.clip()

    let cs = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(srgbRed: 0.16, green: 0.18, blue: 0.22, alpha: 1.0).cgColor,
        NSColor(srgbRed: 0.08, green: 0.09, blue: 0.12, alpha: 1.0).cgColor
    ] as CFArray
    if let bgGrad = CGGradient(colorsSpace: cs, colors: bgColors, locations: [0, 1]) {
        ctx.drawLinearGradient(bgGrad, start: CGPoint(x: s / 2, y: tile.maxY), end: CGPoint(x: s / 2, y: tile.minY), options: [])
    }

    let frameW = tile.width * 0.68
    let frameH = tile.height * 0.48
    let frameX = (s - frameW) / 2
    let frameY = (s - frameH) / 2 + s * 0.02
    let screenRect = CGRect(x: frameX, y: frameY, width: frameW, height: frameH)
    let screenPath = CGPath(roundedRect: screenRect, cornerWidth: s * 0.035, cornerHeight: s * 0.035, transform: nil)

    ctx.saveGState()
    ctx.addPath(screenPath)
    ctx.clip()

    let colW = screenRect.width / 5.0
    let shades: [CGFloat] = [0.62, 0.78, 0.68, 0.84, 0.88]
    for i in 0..<5 {
        let colRect = CGRect(x: screenRect.minX + CGFloat(i) * colW, y: screenRect.minY, width: colW + 1, height: screenRect.height)
        ctx.setFillColor(NSColor(srgbRed: shades[i], green: shades[i] + 0.01, blue: shades[i] + 0.03, alpha: 1).cgColor)
        ctx.fill(colRect)
    }

    let lowerRect = CGRect(x: screenRect.minX, y: screenRect.minY, width: screenRect.width, height: screenRect.height * 0.46)
    let sweepColors = [
        NSColor(srgbRed: 0.145, green: 0.388, blue: 0.922, alpha: 0.90).cgColor,
        NSColor(srgbRed: 0.220, green: 0.560, blue: 0.980, alpha: 0.94).cgColor
    ] as CFArray
    if let swGrad = CGGradient(colorsSpace: cs, colors: sweepColors, locations: [0, 1]) {
        ctx.saveGState()
        ctx.clip(to: lowerRect)
        ctx.drawLinearGradient(swGrad, start: CGPoint(x: lowerRect.minX, y: lowerRect.midY), end: CGPoint(x: lowerRect.maxX, y: lowerRect.midY), options: [])
        ctx.restoreGState()
    }

    ctx.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
    ctx.fill(CGRect(x: screenRect.minX, y: lowerRect.maxY - max(1.5, s * 0.008), width: screenRect.width, height: max(2.0, s * 0.012)))
    ctx.restoreGState()

    ctx.addPath(screenPath)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.28).cgColor)
    ctx.setLineWidth(max(1.5, s * 0.014))
    ctx.strokePath()

    let baseW = frameW * 1.12
    let baseH = max(3.0, s * 0.032)
    let baseRect = CGRect(x: (s - baseW) / 2, y: screenRect.minY - baseH - s * 0.025, width: baseW, height: baseH)
    let basePath = CGPath(roundedRect: baseRect, cornerWidth: baseH / 2, cornerHeight: baseH / 2, transform: nil)
    ctx.addPath(basePath)
    ctx.setFillColor(NSColor(white: 0.72, alpha: 0.9).cgColor)
    ctx.fillPath()

    ctx.restoreGState()

    ctx.addPath(squircle)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.14).cgColor)
    ctx.setLineWidth(max(1.0, s * 0.010))
    ctx.strokePath()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func renderOGCard() -> NSBitmapImageRep {
    let w = 1200, h = 630
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: w, height: h)

    NSGraphicsContext.saveGraphicsState()
    let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = nsCtx
    let ctx = nsCtx.cgContext

    // Clean light aluminum paper surface matching site/index.html
    ctx.setFillColor(NSColor(srgbRed: 0.96, green: 0.965, blue: 0.973, alpha: 1).cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

    // Left typography block
    let eyebrow = NSAttributedString(
        string: "OPEN SOURCE  ·  MACOS 13+ & WEB",
        attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .bold),
            .foregroundColor: NSColor(srgbRed: 0.145, green: 0.388, blue: 0.922, alpha: 1)
        ]
    )
    eyebrow.draw(at: CGPoint(x: 74, y: 486))

    let title = NSAttributedString(
        string: "EvenDisplay",
        attributes: [
            .font: NSFont.systemFont(ofSize: 64, weight: .bold),
            .foregroundColor: NSColor(srgbRed: 0.06, green: 0.075, blue: 0.10, alpha: 1)
        ]
    )
    title.draw(at: CGPoint(x: 72, y: 392))

    let subStyle = NSMutableParagraphStyle()
    subStyle.lineSpacing = 8
    let sub = NSAttributedString(
        string: "Even out dim vertical bands on\nyour MacBook display. Free 50% gray\ntester, IPS sweep & reversible overlay.",
        attributes: [
            .font: NSFont.systemFont(ofSize: 27, weight: .regular),
            .foregroundColor: NSColor(srgbRed: 0.32, green: 0.36, blue: 0.42, alpha: 1),
            .paragraphStyle: subStyle
        ]
    )
    sub.draw(in: CGRect(x: 74, y: 170, width: 540, height: 190))

    let urlStr = NSAttributedString(
        string: "evendisplay.amulyagupta.in",
        attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: NSColor(srgbRed: 0.145, green: 0.388, blue: 0.922, alpha: 1)
        ]
    )
    urlStr.draw(at: CGPoint(x: 74, y: 84))

    // Right MacBook display split before/after visual
    let cardRect = CGRect(x: 640, y: 115, width: 492, height: 396)
    let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 24, cornerHeight: 24, transform: nil)
    ctx.setFillColor(NSColor(srgbRed: 0.07, green: 0.08, blue: 0.10, alpha: 1).cgColor)
    ctx.addPath(cardPath)
    ctx.fillPath()

    let screenRect = CGRect(x: 662, y: 158, width: 448, height: 326)
    let screenPath = CGPath(roundedRect: screenRect, cornerWidth: 14, cornerHeight: 14, transform: nil)
    ctx.saveGState()
    ctx.addPath(screenPath)
    ctx.clip()

    // Base 50% gray screen
    ctx.setFillColor(NSColor(white: 0.52, alpha: 1).cgColor)
    ctx.fill(screenRect)
    // Simulated dim vertical columns on left half
    ctx.setFillColor(NSColor.black.withAlphaComponent(0.16).cgColor)
    ctx.fill(CGRect(x: screenRect.minX + 20, y: screenRect.minY, width: 88, height: screenRect.height))
    ctx.fill(CGRect(x: screenRect.minX + 184, y: screenRect.minY, width: 92, height: screenRect.height))

    // Right side uniform compensated curtain
    let splitX = screenRect.minX + screenRect.width * 0.52
    ctx.setFillColor(NSColor(white: 0.52, alpha: 1).cgColor)
    ctx.fill(CGRect(x: splitX, y: screenRect.minY, width: screenRect.maxX - splitX, height: screenRect.height))
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fill(CGRect(x: splitX - 1.5, y: screenRect.minY, width: 3, height: screenRect.height))

    // Pills inside screen
    let leftPill = CGRect(x: screenRect.minX + 14, y: screenRect.maxY - 46, width: 132, height: 30)
    ctx.setFillColor(NSColor.black.withAlphaComponent(0.72).cgColor)
    ctx.addPath(CGPath(roundedRect: leftPill, cornerWidth: 8, cornerHeight: 8, transform: nil))
    ctx.fillPath()
    NSAttributedString(string: "Raw LCD bands", attributes: [.font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold), .foregroundColor: NSColor.white]).draw(at: CGPoint(x: leftPill.minX + 14, y: leftPill.minY + 7))

    let rightPill = CGRect(x: screenRect.maxX - 168, y: screenRect.maxY - 46, width: 154, height: 30)
    ctx.setFillColor(NSColor(srgbRed: 0.145, green: 0.388, blue: 0.922, alpha: 0.95).cgColor)
    ctx.addPath(CGPath(roundedRect: rightPill, cornerWidth: 8, cornerHeight: 8, transform: nil))
    ctx.fillPath()
    NSAttributedString(string: "EvenDisplay ON", attributes: [.font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold), .foregroundColor: NSColor.white]).draw(at: CGPoint(x: rightPill.minX + 18, y: rightPill.minY + 7))

    ctx.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

guard CommandLine.arguments.count >= 2 else {
    fputs("Usage: generate_assets.swift <output.iconset> [og-card.png]\n", stderr)
    exit(1)
}

let outDir = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let specs: [(String, Int, Int)] = [
    ("icon_16x16.png", 16, 16),
    ("icon_16x16@2x.png", 32, 16),
    ("icon_32x32.png", 32, 32),
    ("icon_32x32@2x.png", 64, 32),
    ("icon_128x128.png", 128, 128),
    ("icon_128x128@2x.png", 256, 128),
    ("icon_256x256.png", 256, 256),
    ("icon_256x256@2x.png", 512, 256),
    ("icon_512x512.png", 512, 512),
    ("icon_512x512@2x.png", 1024, 512),
]

for (name, px, pt) in specs {
    let rep = renderIcon(pixels: px, points: pt)
    guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
    try png.write(to: URL(fileURLWithPath: outDir).appendingPathComponent(name))
}

if CommandLine.arguments.count >= 3 {
    let ogPath = CommandLine.arguments[2]
    let ogURL = URL(fileURLWithPath: ogPath)
    try FileManager.default.createDirectory(at: ogURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let ogRep = renderOGCard()
    guard let ogPng = ogRep.representation(using: .png, properties: [:]) else { exit(1) }
    try ogPng.write(to: ogURL)
    print("Generated OG card at \(ogPath)")
}
print("Generated iconset in \(outDir)")
