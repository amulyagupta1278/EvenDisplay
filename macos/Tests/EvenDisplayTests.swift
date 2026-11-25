import Cocoa
import Foundation

@main
struct EvenDisplayTestRunner {
    static var passed = 0
    static var failed = 0

    static func expect(_ cond: Bool, _ msg: String) {
        if cond {
            passed += 1
            print("  [PASS] \(msg)")
        } else {
            failed += 1
            print("  [FAIL] \(msg)")
        }
        fflush(stdout)
    }

    static func renderOverlay(profile: EvenDisplayProfile, width: Int = 500, height: Int = 20) -> [UInt8] {
        let view = BandOverlayView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.profile = profile
        view.alwaysShowBorders = false
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let cs = CGColorSpaceCreateDeviceRGB()
        data.withUnsafeMutableBytes { ptr in
            let ctx = CGContext(
                data: ptr.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: cs,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
            view.draw(view.bounds)
            NSGraphicsContext.restoreGraphicsState()
        }
        return data
    }

    static func pixelRGBA(_ data: [UInt8], width: Int, x: Int, y: Int = 10) -> (UInt8, UInt8, UInt8, UInt8) {
        let o = (y * width + x) * 4
        return (data[o], data[o + 1], data[o + 2], data[o + 3])
    }

    static func main() {
        print("Running EvenDisplay Swift Automated Test Suite...")
        let state = AppState.shared
        expect(OverlayManager.updateCallCount == 0, "AppState.shared init does NOT recursively invoke OverlayManager.updateOverlay()")
        state.factoryResetAndClearPreferences()

        // 1. Default 2-band movable setup
        expect(state.profile.bands.count == 2, "Defaults to 2 movable bands")
        expect(state.overlayEnabled == false, "Factory reset leaves overlay off")

        // 2. Band move & clamping
        state.updateBandGeometry(id: 1, x: 0.95, w: 0.20)
        expect(abs(state.profile.bands[0].x - 0.80) < 0.0001, "Band X clamps cleanly to 1.0 - width")
        state.updateBandGeometry(id: 1, x: -0.5, w: 0.001)
        expect(state.profile.bands[0].x == 0.0 && state.profile.bands[0].w >= 0.015, "Band clamps min X=0 and min width=0.015")

        // 3. Undo / Redo coalescing & Add/Remove band
        state.resetToDefaultTwoBands()
        state.beginDragUndo(label: "Move Band 1")
        state.updateBandGeometry(id: 1, x: 0.12, w: 0.18)
        state.updateBandGeometry(id: 1, x: 0.15, w: 0.18)
        state.commitDragUndo()
        expect(abs(state.profile.bands[0].x - 0.15) < 0.0001, "Band 1 moved to 15%")
        state.undo()
        expect(abs(state.profile.bands[0].x - 0.0) < 0.0001, "Undo restores Band 1 position to 0%")
        state.redo()
        expect(abs(state.profile.bands[0].x - 0.15) < 0.0001, "Redo re-applies Band 1 position 15%")

        state.addBand()
        expect(state.profile.bands.count == 3, "Add Band creates Band 3")
        state.undo()
        expect(state.profile.bands.count == 2, "Undo removes added Band 3")

        // 4. Web <-> Mac .evendisplay.json roundtrip compatibility
        let webExportJSON = """
        {
          "schema": "evendisplay.profile.v1",
          "bands": [
            { "id": 1, "x": 0.08, "w": 0.19, "brightness": 6.5, "warmth": -1.5 },
            { "id": 2, "x": 0.44, "w": 0.21, "brightness": 8.0, "warmth": 1.0 }
          ],
          "surroundDim": 4.5,
          "edgeFeather": 3.0
        }
        """.data(using: .utf8)!
        do {
            try state.importProfileData(webExportJSON, sourceName: "web-studio.evendisplay.json")
            expect(state.profile.bands.count == 2, "Imported Web JSON has 2 bands")
            expect(abs(state.profile.bands[0].brightness - 6.5) < 0.001, "Imported Band 1 brightness matches 6.5%")
            expect(abs(state.profile.surroundDim - 4.5) < 0.001, "Imported surroundDim matches 4.5%")
            let reExported = try state.profile.toPrettyJSON()
            let parsedBack = try EvenDisplayProfile.fromJSON(reExported)
            expect(parsedBack == state.profile, "JSON export -> import roundtrip is lossless")
        } catch {
            expect(false, "JSON roundtrip threw error: \(error)")
        }

        // 5. Checkpoints + Panic Revert
        state.saveCheckpoint(name: "Studio Import")
        expect(state.checkpoints.count == 1, "Checkpoint saved")
        state.zeroAllAdjustments()
        expect(state.profile.bands.allSatisfy { $0.brightness == 0 }, "Zero All clears brightness")
        state.restoreCheckpoint(state.checkpoints[0])
        expect(abs(state.profile.bands[1].brightness - 8.0) < 0.001, "Checkpoint restores Band 2 brightness")
        state.panicRevertToStockScreen()
        expect(!state.overlayEnabled && !state.calibrationBackdropEnabled, "Panic revert restores stock immediately")
        state.undo()
        expect(state.overlayEnabled, "Undo after panic revert re-enables overlay")

        // 6. Pixel-level rendering test: positive brightness lifts inside band, surroundDim darkens outside band
        let renderProf = EvenDisplayProfile(
            bands: [MovableBand(id: 1, x: 0.40, w: 0.20, brightness: 20.0, warmth: 0.0)],
            surroundDim: 10.0,
            edgeFeather: 0.0
        )
        let pixels = renderOverlay(profile: renderProf, width: 500)
        let outside = pixelRGBA(pixels, width: 500, x: 50)   // Should be black with ~10% alpha (~25)
        let inside  = pixelRGBA(pixels, width: 500, x: 250)  // Should be white with ~20% alpha (~51)
        expect(outside.0 == 0 && outside.3 >= 22 && outside.3 <= 29, "Outside band has black surroundDim alpha (~25, got rgba=\(outside))")
        expect(inside.0 >= 46 && inside.3 >= 46, "Inside band has white brighten lift (~51, got rgba=\(inside))")

        // 7. Warmth + Tint + RGB channel rendering visibly changes RGB balance
        let warmProf = EvenDisplayProfile(
            bands: [MovableBand(id: 1, x: 0.40, w: 0.20, brightness: 0.0, warmth: 30.0, tint: 0.0)],
            surroundDim: 0.0,
            edgeFeather: 0.0
        )
        let warmPixels = renderOverlay(profile: warmProf, width: 500)
        let warmInside = pixelRGBA(warmPixels, width: 500, x: 250)
        expect(warmInside.0 > warmInside.2 && warmInside.3 >= 65, "Warm +30% visibly boosts red over blue inside band (rgba=\(warmInside))")

        // 8. Hover-only edge visibility: borders appear ONLY on edge hover and hide when away!
        let hoverView = BandOverlayView(frame: CGRect(x: 0, y: 0, width: 500, height: 100))
        hoverView.profile = EvenDisplayProfile.defaultTwoBand() // Band 2 is 200..300
        hoverView.interactiveMode = true
        hoverView.alwaysShowBorders = false
        hoverView.updateHover(atX: 250) // Middle of Band 2 (away from edges) -> hidden!
        expect(hoverView.hoveredBandId == nil, "Hover-only borders stay HIDDEN when cursor is away from band edges")
        hoverView.updateHover(atX: 202) // Within 22px of Band 2 left edge -> visible!
        expect(hoverView.hoveredBandId == 2, "Hover-only borders APPEAR when cursor hovers Band 2 left edge")
        hoverView.updateHover(atX: nil) // Cursor moved to sliders -> hidden!
        expect(hoverView.hoveredBandId == nil, "Hover-only borders DISAPPEAR when cursor leaves to adjust sliders")

        // 9. Calibration Backdrop auto-enables overlay
        state.overlayEnabled = false
        state.calibrationBackdropEnabled = true
        expect(state.overlayEnabled == true, "Turning on Calibration Backdrop auto-enables Band Compensator overlay")

        state.factoryResetAndClearPreferences()
        expect(state.checkpoints.isEmpty && !state.overlayEnabled, "Final factory reset leaves clean state")

        print("Summary: \(passed) passed, \(failed) failed.")
        exit(failed == 0 ? 0 : 1)
    }
}
