import Cocoa
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Shared EvenDisplay Profile Schema (1:1 Compatible with Web Calibration Studio)

struct MovableBand: Codable, Equatable, Identifiable {
    var id: Int
    /// Normalized left edge [0.0, 1.0)
    var x: Double
    /// Normalized width [0.015, 1.0]
    var w: Double
    /// Brightness adjustment [-50.0 (darken) ... +50.0 (brighten/lift)]
    var brightness: Double
    /// Color Temperature [-40.0 (cool blue) ... +40.0 (warm amber)]
    var warmth: Double
    /// Tint [-40.0 (green) ... +40.0 (magenta)]
    var tint: Double
    /// Fine per-channel RGB trim [-30.0 ... +30.0]
    var red: Double
    var green: Double
    var blue: Double

    init(
        id: Int,
        x: Double,
        w: Double,
        brightness: Double = 0.0,
        warmth: Double = 0.0,
        tint: Double = 0.0,
        red: Double = 0.0,
        green: Double = 0.0,
        blue: Double = 0.0
    ) {
        self.id = id
        self.x = x
        self.w = w
        self.brightness = brightness
        self.warmth = warmth
        self.tint = tint
        self.red = red
        self.green = green
        self.blue = blue
    }

    // Backwards-compatible decoding for v1.0 profiles without tint/red/green/blue
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(Int.self, forKey: .id)
        self.x = try c.decode(Double.self, forKey: .x)
        self.w = try c.decode(Double.self, forKey: .w)
        self.brightness = try c.decodeIfPresent(Double.self, forKey: .brightness) ?? 0.0
        self.warmth = try c.decodeIfPresent(Double.self, forKey: .warmth) ?? 0.0
        self.tint = try c.decodeIfPresent(Double.self, forKey: .tint) ?? 0.0
        self.red = try c.decodeIfPresent(Double.self, forKey: .red) ?? 0.0
        self.green = try c.decodeIfPresent(Double.self, forKey: .green) ?? 0.0
        self.blue = try c.decodeIfPresent(Double.self, forKey: .blue) ?? 0.0
    }

    mutating func clamp() {
        w = max(0.015, min(1.0, w))
        x = max(0.0, min(1.0 - w, x))
        brightness = max(-50.0, min(50.0, brightness))
        warmth = max(-40.0, min(40.0, warmth))
        tint = max(-40.0, min(40.0, tint))
        red = max(-30.0, min(30.0, red))
        green = max(-30.0, min(30.0, green))
        blue = max(-30.0, min(30.0, blue))
    }
}

struct EvenDisplayProfile: Codable, Equatable {
    var schema: String
    var bands: [MovableBand]
    /// Percentage [0.0 ... 40.0] black overlay applied OUTSIDE the bands (essential on white screens)
    var surroundDim: Double
    /// Edge feather width in points [0.0 ... 20.0]
    var edgeFeather: Double

    init(
        schema: String = "evendisplay.profile.v1",
        bands: [MovableBand],
        surroundDim: Double = 0.0,
        edgeFeather: Double = 0.0
    ) {
        self.schema = schema
        self.bands = bands
        self.surroundDim = max(0.0, min(40.0, surroundDim))
        self.edgeFeather = max(0.0, min(20.0, edgeFeather))
    }

    static func defaultTwoBand() -> EvenDisplayProfile {
        EvenDisplayProfile(
            bands: [
                MovableBand(id: 1, x: 0.00, w: 0.20, brightness: 8.0, warmth: 0.0),
                MovableBand(id: 2, x: 0.40, w: 0.20, brightness: 10.0, warmth: 0.0),
            ],
            surroundDim: 0.0,
            edgeFeather: 0.0
        )
    }

    mutating func normalize() {
        if bands.isEmpty {
            bands = Self.defaultTwoBand().bands
        }
        if bands.count > 6 {
            bands = Array(bands.prefix(6))
        }
        for i in bands.indices {
            bands[i].clamp()
        }
        surroundDim = max(0.0, min(40.0, surroundDim))
        edgeFeather = max(0.0, min(20.0, edgeFeather))
    }

    func toPrettyJSON() throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try enc.encode(self)
    }

    static func fromJSON(_ data: Data) throws -> EvenDisplayProfile {
        var decoded = try JSONDecoder().decode(EvenDisplayProfile.self, from: data)
        decoded.normalize()
        return decoded
    }
}

struct SavedCheckpoint: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date
    var profile: EvenDisplayProfile
}

struct UndoSnapshot: Equatable {
    var label: String
    var profile: EvenDisplayProfile
    var overlayEnabled: Bool
}

// MARK: - Test Colors & Cleaner Modes

enum CalibrationBackdropColor: String, CaseIterable, Identifiable {
    case gray50 = "50% Gray"
    case gray25 = "25% Gray"
    case gray75 = "75% Gray"
    case gray10 = "10% Dark"
    case white = "White"
    case red = "Red"
    case green = "Green"
    case blue = "Blue"
    case black = "Black"

    var id: String { rawValue }

    var nsColor: NSColor {
        switch self {
        case .gray50: return NSColor(white: 0.50, alpha: 1)
        case .gray25: return NSColor(white: 0.25, alpha: 1)
        case .gray75: return NSColor(white: 0.75, alpha: 1)
        case .gray10: return NSColor(white: 0.10, alpha: 1)
        case .white: return .white
        case .red: return NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        case .green: return NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
        case .blue: return NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
        case .black: return .black
        }
    }

    var swiftUIColor: Color { Color(nsColor: nsColor) }
}

enum CleanerMode: String, CaseIterable, Identifiable {
    case sweep = "White & Gray Sweep"
    case rgbCycle = "RGB Subpixel Cycle"
    case softNoise = "Pixel Noise (Snow)"
    case rapidFlash = "Stuck-Pixel Rapid Flash"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .sweep:
            return "Best for temporary IPS image retention. Smooth moving bars and neutral uniform frames."
        case .rgbCycle:
            return "Cycles pure Red, Green, Blue, White, and Black to exercise all subpixels."
        case .softNoise:
            return "High-frequency pixel snow across the built-in display to stimulate sluggish LCD cells."
        case .rapidFlash:
            return "Fast RGB flashing for stubborn stuck pixels. Warning: rapid flashing light (avoid if photosensitive)."
        }
    }
}

// MARK: - App State (Zero Recursive Init, Full Undo/Redo, Checkpoints, JSON Sync)

final class AppState: ObservableObject {
    static let shared = AppState()

    private var isInitialized: Bool = false

    @Published var overlayEnabled: Bool = false {
        didSet {
            guard isInitialized else { return }
            saveState()
            OverlayManager.shared.updateOverlay()
        }
    }
    @Published var compareOriginal: Bool = false {
        didSet {
            guard isInitialized else { return }
            OverlayManager.shared.updateOverlay()
        }
    }
    /// Default false: borders are hover-only (appear ONLY when cursor hovers a band edge, invisible when adjusting sliders!)
    @Published var alwaysShowBorders: Bool = false {
        didSet {
            guard isInitialized else { return }
            OverlayManager.shared.updateOverlay()
        }
    }
    @Published var calibrationBackdropEnabled: Bool = false {
        didSet {
            guard isInitialized else { return }
            // Auto-enable overlay whenever Calibration Backdrop is turned ON so sliders visibly reflect immediately
            if calibrationBackdropEnabled && !overlayEnabled {
                overlayEnabled = true
            }
            OverlayManager.shared.updateCalibrationBackdrop()
            OverlayManager.shared.updateOverlay()
        }
    }
    @Published var backdropColor: CalibrationBackdropColor = .gray50 {
        didSet {
            guard isInitialized else { return }
            OverlayManager.shared.updateCalibrationBackdrop()
        }
    }
    @Published var selectedBandId: Int = 1 {
        didSet {
            guard isInitialized else { return }
            OverlayManager.shared.updateOverlay()
        }
    }
    @Published var profile: EvenDisplayProfile {
        didSet {
            guard isInitialized else { return }
            saveState()
            OverlayManager.shared.updateOverlay()
        }
    }

    @Published var undoStack: [UndoSnapshot] = []
    @Published var redoStack: [UndoSnapshot] = []
    @Published var checkpoints: [SavedCheckpoint] = []
    @Published var statusBanner: String? = nil

    // Cleaner state
    @Published var selectedMode: CleanerMode = .sweep
    @Published var durationMinutes: Int = 15
    @Published var isCleanerRunning: Bool = false
    @Published var remainingSeconds: Int = 0
    @Published var showCleanerHUD: Bool = true

    // Launch at login
    @Published var launchAtLogin: Bool = false

    private var pendingDragSnapshot: UndoSnapshot? = nil
    private let maxUndoEntries = 60

    private let profileKey = "EvenDisplay.Profile.v1"
    private let enabledKey = "EvenDisplay.OverlayEnabled.v1"
    private let checkpointsKey = "EvenDisplay.Checkpoints.v1"

    private init() {
        let initialProfile: EvenDisplayProfile
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? EvenDisplayProfile.fromJSON(data) {
            initialProfile = decoded
        } else {
            initialProfile = EvenDisplayProfile.defaultTwoBand()
        }
        self._profile = Published(initialValue: initialProfile)
        self._selectedBandId = Published(initialValue: initialProfile.bands.first?.id ?? 1)
        self._overlayEnabled = Published(initialValue: UserDefaults.standard.bool(forKey: enabledKey))

        if let cpData = UserDefaults.standard.data(forKey: checkpointsKey),
           let decodedCP = try? JSONDecoder().decode([SavedCheckpoint].self, from: cpData) {
            self._checkpoints = Published(initialValue: decodedCP)
        }

        if #available(macOS 13.0, *) {
            #if !EVENDISPLAY_TEST
            self._launchAtLogin = Published(initialValue: SMAppService.mainApp.status == .enabled)
            #endif
        }

        self.isInitialized = true
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var lastUndoLabel: String? { undoStack.last?.label }
    var lastRedoLabel: String? { redoStack.last?.label }

    // MARK: History

    private func currentSnapshot(label: String) -> UndoSnapshot {
        UndoSnapshot(label: label, profile: profile, overlayEnabled: overlayEnabled)
    }

    func recordUndoPoint(label: String) {
        let entry = currentSnapshot(label: label)
        if undoStack.last?.profile == entry.profile && undoStack.last?.overlayEnabled == entry.overlayEnabled {
            return
        }
        undoStack.append(entry)
        if undoStack.count > maxUndoEntries {
            undoStack.removeFirst(undoStack.count - maxUndoEntries)
        }
        redoStack.removeAll()
    }

    func beginDragUndo(label: String) {
        if pendingDragSnapshot == nil {
            pendingDragSnapshot = currentSnapshot(label: label)
        }
    }

    func commitDragUndo() {
        guard let snap = pendingDragSnapshot else { return }
        pendingDragSnapshot = nil
        if snap.profile != profile || snap.overlayEnabled != overlayEnabled {
            undoStack.append(snap)
            if undoStack.count > maxUndoEntries {
                undoStack.removeFirst(undoStack.count - maxUndoEntries)
            }
            redoStack.removeAll()
        }
    }

    func handleSliderEditing(_ editing: Bool, label: String) {
        if editing { beginDragUndo(label: label) } else { commitDragUndo() }
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(currentSnapshot(label: prev.label))
        profile = prev.profile
        overlayEnabled = prev.overlayEnabled
        if !profile.bands.contains(where: { $0.id == selectedBandId }) {
            selectedBandId = profile.bands.first?.id ?? 1
        }
        flashStatus("Undid: \(prev.label)")
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(currentSnapshot(label: next.label))
        profile = next.profile
        overlayEnabled = next.overlayEnabled
        if !profile.bands.contains(where: { $0.id == selectedBandId }) {
            selectedBandId = profile.bands.first?.id ?? 1
        }
        flashStatus("Redid: \(next.label)")
    }

    // MARK: Band Operations

    func setOverlayEnabledWithUndo(_ value: Bool) {
        guard value != overlayEnabled else { return }
        recordUndoPoint(label: value ? "Enable Compensation" : "Disable Compensation")
        overlayEnabled = value
    }

    func addBand() {
        guard profile.bands.count < 6 else { return }
        recordUndoPoint(label: "Add Band")
        let nextId = (profile.bands.map(\.id).max() ?? 0) + 1
        var newBand = MovableBand(id: nextId, x: 0.65, w: 0.18, brightness: 8.0)
        newBand.clamp()
        profile.bands.append(newBand)
        selectedBandId = nextId
        flashStatus("Added Band \(profile.bands.count)")
    }

    func removeBand(id: Int) {
        guard profile.bands.count > 1 else { return }
        recordUndoPoint(label: "Remove Band")
        profile.bands.removeAll { $0.id == id }
        if !profile.bands.contains(where: { $0.id == selectedBandId }) {
            selectedBandId = profile.bands.first?.id ?? 1
        }
    }

    func resetToDefaultTwoBands() {
        recordUndoPoint(label: "Reset 2 Bands")
        profile = EvenDisplayProfile.defaultTwoBand()
        selectedBandId = 1
        overlayEnabled = true
        flashStatus("Reset to 2 default bands (Cmd+Z to undo)")
    }

    func zeroAllAdjustments() {
        recordUndoPoint(label: "Zero All Bands")
        for i in profile.bands.indices {
            profile.bands[i].brightness = 0.0
            profile.bands[i].warmth = 0.0
            profile.bands[i].tint = 0.0
            profile.bands[i].red = 0.0
            profile.bands[i].green = 0.0
            profile.bands[i].blue = 0.0
        }
        profile.surroundDim = 0.0
        profile.edgeFeather = 0.0
        flashStatus("Zeroed all band adjustments (Cmd+Z to undo)")
    }

    func updateBandGeometry(id: Int, x: Double, w: Double) {
        guard let idx = profile.bands.firstIndex(where: { $0.id == id }) else { return }
        var updated = profile.bands[idx]
        updated.x = x
        updated.w = w
        updated.clamp()
        profile.bands[idx] = updated
    }

    // MARK: Checkpoints & JSON Sync

    func saveCheckpoint(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "Checkpoint \(checkpoints.count + 1)" : trimmed
        let cp = SavedCheckpoint(id: UUID(), name: finalName, createdAt: Date(), profile: profile)
        checkpoints.insert(cp, at: 0)
        saveCheckpoints()
        flashStatus("Saved checkpoint \"\(finalName)\"")
    }

    func restoreCheckpoint(_ cp: SavedCheckpoint) {
        recordUndoPoint(label: "Restore \"\(cp.name)\"")
        profile = cp.profile
        selectedBandId = profile.bands.first?.id ?? 1
        overlayEnabled = true
        flashStatus("Restored \"\(cp.name)\" (Cmd+Z to undo)")
    }

    func deleteCheckpoint(_ cp: SavedCheckpoint) {
        checkpoints.removeAll { $0.id == cp.id }
        saveCheckpoints()
        flashStatus("Deleted checkpoint \"\(cp.name)\"")
    }

    func importProfileData(_ data: Data, sourceName: String = "Profile") throws {
        let imported = try EvenDisplayProfile.fromJSON(data)
        recordUndoPoint(label: "Import \(sourceName)")
        profile = imported
        selectedBandId = imported.bands.first?.id ?? 1
        overlayEnabled = true
        flashStatus("Imported \(sourceName) (\(imported.bands.count) bands) — Cmd+Z to undo")
    }

    // MARK: Instant Revert & Factory Reset

    func panicRevertToStockScreen() {
        if overlayEnabled {
            recordUndoPoint(label: "Revert to Stock Screen")
        }
        CleanerSessionManager.shared.stopCleaner()
        calibrationBackdropEnabled = false
        compareOriginal = false
        overlayEnabled = false
        flashStatus("Stock macOS display restored (Cmd+Z to re-enable)")
    }

    func factoryResetAndClearPreferences() {
        CleanerSessionManager.shared.stopCleaner()
        calibrationBackdropEnabled = false
        compareOriginal = false
        alwaysShowBorders = false
        undoStack.removeAll()
        redoStack.removeAll()
        checkpoints.removeAll()

        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: enabledKey)
        UserDefaults.standard.removeObject(forKey: checkpointsKey)
        UserDefaults.standard.synchronize()

        overlayEnabled = false
        profile = EvenDisplayProfile.defaultTwoBand()
        selectedBandId = 1
        flashStatus("All saved preferences cleared and stock display restored.")
    }

    func toggleLaunchAtLogin(_ enabled: Bool) {
        #if !EVENDISPLAY_TEST
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                launchAtLogin = (SMAppService.mainApp.status == .enabled)
                flashStatus(launchAtLogin ? "Launch at Login enabled" : "Launch at Login disabled")
            } catch {
                launchAtLogin = (SMAppService.mainApp.status == .enabled)
                flashStatus("Move EvenDisplay.app to /Applications to enable Launch at Login.")
            }
        }
        #else
        launchAtLogin = enabled
        #endif
    }

    // MARK: Persistence

    func saveState() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
        UserDefaults.standard.set(overlayEnabled, forKey: enabledKey)
    }

    private func saveCheckpoints() {
        if let data = try? JSONEncoder().encode(checkpoints) {
            UserDefaults.standard.set(data, forKey: checkpointsKey)
        }
    }

    func flashStatus(_ message: String) {
        statusBanner = message
        let captured = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
            if self?.statusBanner == captured {
                self?.statusBanner = nil
            }
        }
    }
}

// MARK: - Interactive Movable-Band Overlay View (Hover-Only Edges + Full Color Calibration)

enum EdgeHitResult: Equatable {
    case none
    case leftEdge(bandId: Int)
    case rightEdge(bandId: Int)
    case body(bandId: Int)

    var bandId: Int? {
        switch self {
        case .none: return nil
        case .leftEdge(let id), .rightEdge(let id), .body(let id): return id
        }
    }

    var isEdge: Bool {
        switch self {
        case .leftEdge, .rightEdge: return true
        default: return false
        }
    }
}

final class BandOverlayView: NSView {
    var profile: EvenDisplayProfile = EvenDisplayProfile.defaultTwoBand()
    var interactiveMode: Bool = false
    var alwaysShowBorders: Bool = false
    var selectedBandId: Int = 1

    /// Only populated when cursor hovers near a band's left/right edge (or while actively dragging)
    private(set) var hoveredBandId: Int? = nil
    private var trackingArea: NSTrackingArea?

    private enum DragMode {
        case move(bandId: Int, startX: CGFloat, origNormX: Double)
        case resizeLeft(bandId: Int, startX: CGFloat, origNormX: Double, origRight: Double)
        case resizeRight(bandId: Int, startX: CGFloat, origNormX: Double, origNormW: Double)

        var bandId: Int {
            switch self {
            case .move(let id, _, _), .resizeLeft(let id, _, _, _), .resizeRight(let id, _, _, _):
                return id
            }
        }
    }
    private var activeDrag: DragMode? = nil

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea { removeTrackingArea(ta) }
        let ta = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(ta)
        trackingArea = ta
    }

    /// Hit-tests cursor X against band edges (within `edgeThreshold` points) and band bodies.
    func hitTestBand(atX x: CGFloat, edgeThreshold: CGFloat = 20.0) -> EdgeHitResult {
        let w = max(1, bounds.width)
        for b in profile.bands.reversed() {
            let x0 = CGFloat(b.x) * w
            let x1 = CGFloat(b.x + b.w) * w
            if abs(x - x0) <= edgeThreshold { return .leftEdge(bandId: b.id) }
            if abs(x - x1) <= edgeThreshold { return .rightEdge(bandId: b.id) }
        }
        for b in profile.bands.reversed() {
            let x0 = CGFloat(b.x) * w
            let x1 = CGFloat(b.x + b.w) * w
            if x >= x0 && x <= x1 { return .body(bandId: b.id) }
        }
        return .none
    }

    /// Exposed for unit testing hover-only border visibility logic
    func updateHover(atX x: CGFloat?) {
        guard interactiveMode, let x = x else {
            if hoveredBandId != nil {
                hoveredBandId = nil
                needsDisplay = true
            }
            return
        }
        let hit = hitTestBand(atX: x, edgeThreshold: 22.0)
        // Show borders ONLY when cursor hovers near a band's left or right edge!
        let nextHover: Int? = hit.isEdge ? hit.bandId : nil
        if nextHover != hoveredBandId {
            hoveredBandId = nextHover
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)

        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }
        let feather = CGFloat(max(0.0, profile.edgeFeather))

        // 1. Optional Surroundings Dim (darkens outside the bands — essential on bright/white screens)
        if profile.surroundDim > 0.05 {
            let dimAlpha = CGFloat(profile.surroundDim / 100.0)
            ctx.saveGState()
            ctx.beginTransparencyLayer(auxiliaryInfo: nil)
            ctx.setFillColor(NSColor.black.withAlphaComponent(dimAlpha).cgColor)
            ctx.fill(bounds)
            ctx.setBlendMode(.destinationOut)
            for b in profile.bands {
                let x0 = floor(CGFloat(b.x) * w)
                let x1 = floor(CGFloat(b.x + b.w) * w)
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: .black, alpha: 1.0)
            }
            ctx.endTransparencyLayer()
            ctx.restoreGState()
        }

        // 2. Per-band full color compensation:
        //    Brightness (-50..+50), Temp Cool↔Warm (-40..+40), Tint Green↔Magenta (-40..+40), Fine R/G/B (-30..+30)
        for b in profile.bands {
            let x0 = floor(CGFloat(b.x) * w)
            let x1 = floor(CGFloat(b.x + b.w) * w)

            // Brightness lift / darken
            if b.brightness > 0.05 {
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: .white, alpha: CGFloat(b.brightness / 100.0))
            } else if b.brightness < -0.05 {
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: .black, alpha: CGFloat(-b.brightness / 100.0))
            }

            // Color Temperature (Warm Amber vs Cool Blue)
            if b.warmth > 0.05 {
                let warmColor = NSColor(srgbRed: 1.0, green: 0.62, blue: 0.12, alpha: 1.0)
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: warmColor, alpha: CGFloat(b.warmth / 100.0))
            } else if b.warmth < -0.05 {
                let coolColor = NSColor(srgbRed: 0.15, green: 0.52, blue: 1.0, alpha: 1.0)
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: coolColor, alpha: CGFloat(-b.warmth / 100.0))
            }

            // Green ↔ Magenta Tint
            if b.tint > 0.05 {
                let magColor = NSColor(srgbRed: 1.0, green: 0.18, blue: 0.82, alpha: 1.0)
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: magColor, alpha: CGFloat(b.tint / 100.0))
            } else if b.tint < -0.05 {
                let grnColor = NSColor(srgbRed: 0.16, green: 0.92, blue: 0.36, alpha: 1.0)
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: grnColor, alpha: CGFloat(-b.tint / 100.0))
            }

            // Fine Per-Channel RGB trim (+ adds channel color, - adds complementary color to suppress channel)
            if abs(b.red) > 0.05 {
                let col = b.red > 0 ? NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1) : NSColor(srgbRed: 0, green: 1, blue: 1, alpha: 1)
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: col, alpha: CGFloat(abs(b.red) / 100.0))
            }
            if abs(b.green) > 0.05 {
                let col = b.green > 0 ? NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1) : NSColor(srgbRed: 1, green: 0, blue: 1, alpha: 1)
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: col, alpha: CGFloat(abs(b.green) / 100.0))
            }
            if abs(b.blue) > 0.05 {
                let col = b.blue > 0 ? NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1) : NSColor(srgbRed: 1, green: 1, blue: 0, alpha: 1)
                drawFeatheredStrip(ctx: ctx, x0: x0, x1: x1, height: h, feather: feather, color: col, alpha: CGFloat(abs(b.blue) / 100.0))
            }
        }

        // 3. Hover-only edge guides: completely INVISIBLE unless hovering a band edge, actively dragging, or Always Show Borders is enabled!
        if interactiveMode {
            let activeDragId = activeDrag?.bandId
            for (idx, b) in profile.bands.enumerated() {
                let shouldShow = alwaysShowBorders || (hoveredBandId == b.id) || (activeDragId == b.id)
                guard shouldShow else { continue }

                let x0 = floor(CGFloat(b.x) * w)
                let x1 = floor(CGFloat(b.x + b.w) * w)
                let isSel = (b.id == selectedBandId)

                ctx.saveGState()
                ctx.setStrokeColor((isSel ? NSColor.systemBlue : NSColor.systemCyan).withAlphaComponent(0.92).cgColor)
                ctx.setLineWidth(1.5)
                ctx.setLineDash(phase: 0, lengths: [6, 4])
                ctx.move(to: CGPoint(x: x0 + 0.5, y: 0))
                ctx.addLine(to: CGPoint(x: x0 + 0.5, y: h))
                ctx.move(to: CGPoint(x: x1 - 0.5, y: 0))
                ctx.addLine(to: CGPoint(x: x1 - 0.5, y: h))
                ctx.strokePath()
                ctx.restoreGState()

                // Side resize grip pills
                let gripH: CGFloat = 46, gripW: CGFloat = 5, gripY = (h - gripH) / 2
                ctx.setFillColor(NSColor.systemCyan.withAlphaComponent(0.95).cgColor)
                ctx.fill(CGRect(x: x0 - gripW / 2, y: gripY, width: gripW, height: gripH))
                ctx.fill(CGRect(x: x1 - gripW / 2, y: gripY, width: gripW, height: gripH))

                // Compact top label pill
                let label = String(format: "Band %d  •  B %+.0f%%  T %+.0f%%  •  %.1f%%–%.1f%%", idx + 1, b.brightness, b.warmth, b.x * 100, (b.x + b.w) * 100)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: NSColor.white
                ]
                let str = NSAttributedString(string: label, attributes: attrs)
                let sz = str.size()
                let cx = (x0 + x1) / 2
                let pill = CGRect(x: max(12, min(w - sz.width - 32, cx - sz.width / 2 - 10)), y: h - 76, width: sz.width + 20, height: sz.height + 10)
                let path = CGPath(roundedRect: pill, cornerWidth: 10, cornerHeight: 10, transform: nil)
                ctx.setFillColor(NSColor.systemBlue.withAlphaComponent(0.86).cgColor)
                ctx.addPath(path)
                ctx.fillPath()
                str.draw(at: CGPoint(x: pill.minX + 10, y: pill.minY + 5))
            }
        }
    }

    private func drawFeatheredStrip(
        ctx: CGContext,
        x0: CGFloat,
        x1: CGFloat,
        height: CGFloat,
        feather: CGFloat,
        color: NSColor,
        alpha: CGFloat
    ) {
        guard alpha > 0.0005, x1 > x0 else { return }
        let bandW = x1 - x0
        if feather <= 0.25 {
            ctx.setFillColor(color.withAlphaComponent(alpha).cgColor)
            ctx.fill(CGRect(x: x0, y: 0, width: bandW, height: height))
            return
        }
        let f = min(feather, bandW * 0.45)
        let core0 = x0 + f
        let core1 = x1 - f
        if core1 > core0 {
            ctx.setFillColor(color.withAlphaComponent(alpha).cgColor)
            ctx.fill(CGRect(x: core0, y: 0, width: core1 - core0, height: height))
        }
        let cs = CGColorSpaceCreateDeviceRGB()
        let clearC = color.withAlphaComponent(0).cgColor
        let fullC = color.withAlphaComponent(alpha).cgColor
        if f > 0, let gL = CGGradient(colorsSpace: cs, colors: [clearC, fullC] as CFArray, locations: [0, 1]) {
            ctx.saveGState()
            ctx.clip(to: CGRect(x: x0, y: 0, width: f, height: height))
            ctx.drawLinearGradient(gL, start: CGPoint(x: x0, y: 0), end: CGPoint(x: core0, y: 0), options: [])
            ctx.restoreGState()
        }
        if f > 0, let gR = CGGradient(colorsSpace: cs, colors: [fullC, clearC] as CFArray, locations: [0, 1]) {
            ctx.saveGState()
            ctx.clip(to: CGRect(x: core1, y: 0, width: f, height: height))
            ctx.drawLinearGradient(gR, start: CGPoint(x: core1, y: 0), end: CGPoint(x: x1, y: 0), options: [])
            ctx.restoreGState()
        }
    }

    // Hover & direct drag/resize events
    override func mouseMoved(with event: NSEvent) {
        guard interactiveMode else { return }
        let pt = convert(event.locationInWindow, from: nil)
        let hit = hitTestBand(atX: pt.x, edgeThreshold: 22.0)
        updateHover(atX: pt.x)
        if hit.isEdge {
            NSCursor.resizeLeftRight.set()
        } else if case .body = hit {
            NSCursor.openHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    override func mouseExited(with event: NSEvent) {
        updateHover(atX: nil)
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        guard interactiveMode else { return }
        let pt = convert(event.locationInWindow, from: nil)
        let hit = hitTestBand(atX: pt.x, edgeThreshold: 22.0)
        switch hit {
        case .leftEdge(let id):
            if let idx = profile.bands.firstIndex(where: { $0.id == id }) {
                let b = profile.bands[idx]
                AppState.shared.selectedBandId = id
                AppState.shared.beginDragUndo(label: "Resize Band \(idx + 1) Left Edge")
                activeDrag = .resizeLeft(bandId: id, startX: pt.x, origNormX: b.x, origRight: b.x + b.w)
                needsDisplay = true
            }
        case .rightEdge(let id):
            if let idx = profile.bands.firstIndex(where: { $0.id == id }) {
                let b = profile.bands[idx]
                AppState.shared.selectedBandId = id
                AppState.shared.beginDragUndo(label: "Resize Band \(idx + 1) Right Edge")
                activeDrag = .resizeRight(bandId: id, startX: pt.x, origNormX: b.x, origNormW: b.w)
                needsDisplay = true
            }
        case .body(let id):
            if let idx = profile.bands.firstIndex(where: { $0.id == id }) {
                let b = profile.bands[idx]
                AppState.shared.selectedBandId = id
                AppState.shared.beginDragUndo(label: "Move Band \(idx + 1)")
                activeDrag = .move(bandId: id, startX: pt.x, origNormX: b.x)
                NSCursor.closedHand.set()
                needsDisplay = true
            }
        case .none:
            break
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard interactiveMode, let drag = activeDrag else { return }
        let pt = convert(event.locationInWindow, from: nil)
        let w = max(1, bounds.width)

        switch drag {
        case let .move(bandId, startX, origNormX):
            let dx = Double((pt.x - startX) / w)
            if let band = AppState.shared.profile.bands.first(where: { $0.id == bandId }) {
                AppState.shared.updateBandGeometry(id: bandId, x: origNormX + dx, w: band.w)
            }
        case let .resizeLeft(bandId, startX, origNormX, origRight):
            let dx = Double((pt.x - startX) / w)
            let newX = max(0.0, min(origRight - 0.015, origNormX + dx))
            AppState.shared.updateBandGeometry(id: bandId, x: newX, w: origRight - newX)
        case let .resizeRight(bandId, startX, origNormX, origNormW):
            let dx = Double((pt.x - startX) / w)
            let newW = max(0.015, min(1.0 - origNormX, origNormW + dx))
            AppState.shared.updateBandGeometry(id: bandId, x: origNormX, w: newW)
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard activeDrag != nil else { return }
        activeDrag = nil
        NSCursor.arrow.set()
        AppState.shared.commitDragUndo()
        needsDisplay = true
    }
}

final class CalibrationBackdropView: NSView {
    var color: NSColor = CalibrationBackdropColor.gray50.nsColor
    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.setFillColor(color.cgColor)
        ctx.fill(bounds)
    }
}

// MARK: - Fullscreen IPS Pixel Cleaner View

final class CleanerCanvasView: NSView {
    var mode: CleanerMode = .sweep
    private var timer: Timer?
    private var phase: Double = 0.0
    private var tickCount: Int = 0
    private var noiseImage: CGImage?
    private var onStop: (() -> Void)?
    private var hudText: String = ""

    init(frame: NSRect, mode: CleanerMode, onStop: @escaping () -> Void) {
        self.mode = mode
        self.onStop = onStop
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onStop?() }
        else if event.charactersIgnoringModifiers?.lowercased() == "h" {
            AppState.shared.showCleanerHUD.toggle()
            needsDisplay = true
        }
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount >= 2 { onStop?() }
    }

    func startAnimation() {
        stopAnimation()
        let interval: TimeInterval = (mode == .sweep) ? (1.0 / 60.0) : (1.0 / 24.0)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.tickCount += 1
            self.phase += interval
            if self.mode == .softNoise {
                self.noiseImage = self.generateNoiseImage(width: 220, height: 140)
            }
            self.needsDisplay = true
        }
    }

    func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }

    func updateHUD(_ text: String) {
        hudText = text
        needsDisplay = true
    }

    private func generateNoiseImage(width: Int, height: Int) -> CGImage? {
        let count = width * height * 4
        var bytes = [UInt8](repeating: 255, count: count)
        var s: UInt64 = UInt64(bitPattern: Int64(tickCount &* 2654435761)) ^ 0x9E3779B97F4A7C15
        for i in stride(from: 0, to: count, by: 4) {
            s ^= s >> 12; s ^= s << 25; s ^= s >> 27
            let val = s &* 0x2545F4914F6CDD1D
            bytes[i] = UInt8(val & 0xFF)
            bytes[i + 1] = UInt8((val >> 8) & 0xFF)
            bytes[i + 2] = UInt8((val >> 16) & 0xFF)
            bytes[i + 3] = 255
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let rect = bounds
        switch mode {
        case .sweep:
            let cyc = phase.truncatingRemainder(dividingBy: 18.0)
            if cyc < 6.0 {
                let t = CGFloat(cyc / 6.0)
                ctx.setFillColor(NSColor(white: 0.15, alpha: 1).cgColor); ctx.fill(rect)
                let barW = rect.width * 0.28, x = (rect.width + barW) * t - barW
                let cols = [NSColor(white: 0.15, alpha: 1).cgColor, NSColor.white.cgColor, NSColor(white: 0.15, alpha: 1).cgColor] as CFArray
                if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cols, locations: [0, 0.5, 1]) {
                    ctx.drawLinearGradient(g, start: CGPoint(x: x, y: 0), end: CGPoint(x: x + barW, y: 0), options: [])
                }
            } else if cyc < 12.0 {
                let t = CGFloat((cyc - 6.0) / 6.0)
                ctx.setFillColor(NSColor(white: 0.85, alpha: 1).cgColor); ctx.fill(rect)
                let barH = rect.height * 0.28, y = (rect.height + barH) * t - barH
                let cols = [NSColor(white: 0.85, alpha: 1).cgColor, NSColor.black.cgColor, NSColor(white: 0.85, alpha: 1).cgColor] as CFArray
                if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cols, locations: [0, 0.5, 1]) {
                    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: y), end: CGPoint(x: 0, y: y + barH), options: [])
                }
            } else if cyc < 15.0 {
                ctx.setFillColor(NSColor.white.cgColor); ctx.fill(rect)
            } else {
                ctx.setFillColor(NSColor(white: 0.5, alpha: 1).cgColor); ctx.fill(rect)
            }
        case .rgbCycle:
            let cols: [NSColor] = [NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1), NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1), NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1), .white, NSColor(white: 0.5, alpha: 1), .black]
            ctx.setFillColor(cols[Int(phase / 1.5) % cols.count].cgColor); ctx.fill(rect)
        case .softNoise:
            if let img = noiseImage { ctx.interpolationQuality = .none; ctx.draw(img, in: rect) }
        case .rapidFlash:
            let cols: [NSColor] = [NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1), NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1), NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1), .white, .black]
            ctx.setFillColor(cols[tickCount % cols.count].cgColor); ctx.fill(rect)
        }

        if AppState.shared.showCleanerHUD && !hudText.isEmpty {
            let corner = Int(phase / 20.0) % 4
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 12.5, weight: .medium), .foregroundColor: NSColor.white]
            let str = NSAttributedString(string: hudText, attributes: attrs)
            let sz = str.size(), boxW = sz.width + 28, boxH = sz.height + 14, m: CGFloat = 28
            let origin: CGPoint = [
                CGPoint(x: m, y: m),
                CGPoint(x: rect.width - boxW - m, y: m),
                CGPoint(x: rect.width - boxW - m, y: rect.height - boxH - m),
                CGPoint(x: m, y: rect.height - boxH - m)
            ][corner]
            let pill = CGRect(origin: origin, size: CGSize(width: boxW, height: boxH))
            let path = CGPath(roundedRect: pill, cornerWidth: 10, cornerHeight: 10, transform: nil)
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.65).cgColor)
            ctx.addPath(path); ctx.fillPath()
            str.draw(at: CGPoint(x: origin.x + 14, y: origin.y + 7))
        }
    }
}

// MARK: - Window & Session Managers

func targetBuiltInScreen() -> NSScreen? {
    for screen in NSScreen.screens {
        if let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            if CGDisplayIsBuiltin(CGDirectDisplayID(num.uint32Value)) != 0 {
                return screen
            }
        }
    }
    return NSScreen.main ?? NSScreen.screens.first
}

final class OverlayManager {
    static let shared = OverlayManager()
    static var updateCallCount: Int = 0

    private var overlayWindow: NSWindow?
    private var overlayView: BandOverlayView?
    private var backdropWindow: NSWindow?
    private var backdropView: CalibrationBackdropView?
    private var temporarilyHidden: Bool = false

    func setTemporarilyHidden(_ hidden: Bool) {
        temporarilyHidden = hidden
        updateOverlay()
    }

    func updateOverlay() {
        Self.updateCallCount += 1
        #if !EVENDISPLAY_TEST
        let state = AppState.shared
        guard state.overlayEnabled, !state.compareOriginal, !temporarilyHidden, let screen = targetBuiltInScreen() else {
            overlayWindow?.orderOut(nil)
            return
        }

        if overlayWindow == nil {
            let win = NSWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            win.isOpaque = false
            win.backgroundColor = .clear
            win.hasShadow = false
            win.acceptsMouseMovedEvents = true
            win.level = .screenSaver
            win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            let view = BandOverlayView(frame: CGRect(origin: .zero, size: screen.frame.size))
            win.contentView = view
            overlayWindow = win
            overlayView = view
        }

        // Capture mouse hover/drag ONLY while Calibration Backdrop is open; otherwise 100% click-through!
        let interactive = state.calibrationBackdropEnabled
        overlayWindow?.ignoresMouseEvents = !interactive
        overlayWindow?.acceptsMouseMovedEvents = interactive
        overlayWindow?.setFrame(screen.frame, display: true)
        overlayView?.frame = CGRect(origin: .zero, size: screen.frame.size)
        overlayView?.profile = state.profile
        overlayView?.interactiveMode = interactive
        overlayView?.alwaysShowBorders = state.alwaysShowBorders
        overlayView?.selectedBandId = state.selectedBandId
        if !interactive {
            overlayView?.updateHover(atX: nil)
        }
        overlayView?.needsDisplay = true
        overlayWindow?.displayIfNeeded()
        overlayWindow?.orderFrontRegardless()
        #endif
    }

    func updateCalibrationBackdrop() {
        #if !EVENDISPLAY_TEST
        let state = AppState.shared
        let mainWin = NSApp?.windows.first(where: { $0.title == "EvenDisplay" })
        guard state.calibrationBackdropEnabled, let screen = targetBuiltInScreen() else {
            backdropWindow?.orderOut(nil)
            mainWin?.level = .normal
            return
        }

        if backdropWindow == nil {
            let win = NSWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            win.isOpaque = true
            win.hasShadow = false
            win.level = .floating
            win.collectionBehavior = [.canJoinAllSpaces, .stationary]
            let view = CalibrationBackdropView(frame: CGRect(origin: .zero, size: screen.frame.size))
            win.contentView = view
            backdropWindow = win
            backdropView = view
        }

        backdropWindow?.setFrame(screen.frame, display: true)
        backdropView?.frame = CGRect(origin: .zero, size: screen.frame.size)
        backdropView?.color = state.backdropColor.nsColor
        backdropView?.needsDisplay = true
        backdropWindow?.displayIfNeeded()
        backdropWindow?.orderFront(nil)
        // Control window floats above overlay so sliders stay crisp, clickable, and clear hover when entered
        mainWin?.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        mainWin?.makeKeyAndOrderFront(nil)
        updateOverlay()
        #endif
    }
}

final class CleanerSessionManager {
    static let shared = CleanerSessionManager()

    private var cleanerWindow: NSWindow?
    private var cleanerView: CleanerCanvasView?
    private var countdownTimer: Timer?
    private var sleepActivity: NSObjectProtocol?

    func startCleaner() {
        stopCleaner()
        #if !EVENDISPLAY_TEST
        guard let screen = targetBuiltInScreen() else { return }
        let state = AppState.shared
        state.calibrationBackdropEnabled = false
        OverlayManager.shared.setTemporarilyHidden(true)

        state.isCleanerRunning = true
        state.remainingSeconds = state.durationMinutes * 60

        sleepActivity = ProcessInfo.processInfo.beginActivity(
            options: [.idleDisplaySleepDisabled, .idleSystemSleepDisabled, .userInitiated],
            reason: "Running EvenDisplay IPS pixel conditioning cycle"
        )

        let win = NSWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        win.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 2)
        win.isOpaque = true
        win.backgroundColor = .black
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = CleanerCanvasView(frame: CGRect(origin: .zero, size: screen.frame.size), mode: state.selectedMode) { [weak self] in
            self?.stopCleaner()
        }
        win.contentView = view
        win.makeKeyAndOrderFront(nil)
        win.makeFirstResponder(view)
        NSApp?.activate(ignoringOtherApps: true)
        NSApp?.presentationOptions = [.hideDock, .hideMenuBar]

        cleanerWindow = win
        cleanerView = view
        view.startAnimation()
        updateHUD()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if state.durationMinutes > 0 {
                state.remainingSeconds -= 1
                if state.remainingSeconds <= 0 {
                    self.stopCleaner()
                    NSSound.beep()
                    return
                }
            }
            self.updateHUD()
        }
        #endif
    }

    private func updateHUD() {
        let state = AppState.shared
        let timeStr = state.durationMinutes == 0
            ? "Continuous"
            : String(format: "%02d:%02d left", max(0, state.remainingSeconds) / 60, max(0, state.remainingSeconds) % 60)
        cleanerView?.updateHUD("\(state.selectedMode.rawValue)  •  \(timeStr)  •  Esc: Stop  •  H: Hide HUD")
    }

    func stopCleaner() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        cleanerView?.stopAnimation()
        cleanerWindow?.orderOut(nil)
        cleanerWindow = nil
        cleanerView = nil
        if let act = sleepActivity {
            ProcessInfo.processInfo.endActivity(act)
            sleepActivity = nil
        }
        NSApp?.presentationOptions = []
        AppState.shared.isCleanerRunning = false
        OverlayManager.shared.setTemporarilyHidden(false)
    }
}

// MARK: - SwiftUI Control Interface

struct ContentView: View {
    @ObservedObject var state = AppState.shared
    @State private var selectedTab = 0
    @State private var newCheckpointName = ""
    @State private var showResetConfirm = false
    @State private var expandedRGBBandIds: Set<Int> = []

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("EvenDisplay")
                                .font(.system(size: 18, weight: .semibold))
                            Text("v1.1 • Reversible")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.green.opacity(0.16)))
                                .foregroundColor(.green)
                        }
                        Text("Hover-Edge Movable Band Compensator, Multi-Color Tester & IPS Conditioner")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $selectedTab) {
                        Text("Band Studio").tag(0)
                        Text("Pixel Sweep").tag(1)
                        Text("Profile & Settings").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 340)
                }

                HStack(spacing: 8) {
                    Button(action: { state.undo() }) {
                        Label(state.canUndo ? "Undo (\(state.undoStack.count))" : "Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(!state.canUndo)
                    .help(state.lastUndoLabel.map { "Undo: \($0) (⌘Z)" } ?? "Nothing to undo")

                    Button(action: { state.redo() }) {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }
                    .disabled(!state.canRedo)

                    Divider().frame(height: 16)

                    Button(action: { state.compareOriginal.toggle() }) {
                        Label(state.compareOriginal ? "Showing Original" : "Compare Original", systemImage: state.compareOriginal ? "eye.slash.fill" : "eye")
                    }
                    .disabled(!state.overlayEnabled)
                    .tint(state.compareOriginal ? .orange : .primary)

                    Spacer()

                    Button(role: .destructive, action: { state.panicRevertToStockScreen() }) {
                        Label("Revert to Stock", systemImage: "arrow.counterclockwise.circle.fill")
                    }
                    .help("Immediately restores stock macOS display (⌘⌥0)")
                }
                .controlSize(.small)

                if let banner = state.statusBanner {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text(banner).font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.10)))
                }
            }
            .padding(14)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            if selectedTab == 0 {
                bandStudioTab
            } else if selectedTab == 1 {
                pixelSweepTab
            } else {
                profileSettingsTab
            }
        }
        .frame(width: 790, height: 680)
        .alert("Clear all saved preferences?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear & Restore Stock", role: .destructive) {
                state.factoryResetAndClearPreferences()
            }
        } message: {
            Text("Removes all saved checkpoints and resets band sliders back to stock macOS. EvenDisplay never modifies system files, ICC profiles, or NVRAM.")
        }
    }

    // MARK: Tab 1 — Interactive Band Studio
    private var bandStudioTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { state.overlayEnabled },
                        set: { state.setOverlayEnabledWithUndo($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Enable Built-In Display Band Compensator")
                                .font(.headline)
                            Text("Click-through overlay locked strictly to your MacBook screen (external monitors untouched).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)

                    Spacer()

                    Button("Reset 2 Bands") { state.resetToDefaultTwoBands() }
                    Button("Zero All") { state.zeroAllAdjustments() }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))

                GroupBox("1. Live Calibration & Multi-Color Test (Borders auto-hide unless hovering a band edge)") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 14) {
                            Toggle("Calibration Backdrop (Hover Edges to Drag/Resize)", isOn: $state.calibrationBackdropEnabled)
                                .font(.callout.weight(.medium))
                            Spacer()
                            Toggle("Always Show Edges", isOn: $state.alwaysShowBorders)
                                .disabled(!state.calibrationBackdropEnabled)
                                .help("Leave OFF so band outlines disappear while matching brightness and color eye-to-eye")
                        }

                        HStack(spacing: 6) {
                            ForEach(CalibrationBackdropColor.allCases) { colorItem in
                                Button(action: {
                                    state.backdropColor = colorItem
                                    if !state.calibrationBackdropEnabled {
                                        state.calibrationBackdropEnabled = true
                                    }
                                    if !state.overlayEnabled {
                                        state.setOverlayEnabledWithUndo(true)
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(colorItem.swiftUIColor)
                                            .frame(width: 10, height: 10)
                                            .overlay(Circle().stroke(Color.primary.opacity(0.35), lineWidth: 0.7))
                                        Text(colorItem.rawValue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(state.calibrationBackdropEnabled && state.backdropColor == colorItem
                                                  ? Color.accentColor.opacity(0.24)
                                                  : Color(nsColor: .controlBackgroundColor))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .stroke(state.calibrationBackdropEnabled && state.backdropColor == colorItem
                                                    ? Color.accentColor : Color.secondary.opacity(0.22), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if state.calibrationBackdropEnabled && state.backdropColor == .white {
                            Text("White screen tip: pixels on Pure White are already at 100% brightness, so raising +Brightness inside a band won't look brighter — raise **Dim Outside Bands** below to lower the surrounding white down to match your 2 dim bands.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("Hover your cursor near a band's left or right edge to reveal & drag its border. Move cursor back to the sliders below and the border vanishes automatically so you can match brightness, temp, and tint eye-to-eye.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(6)
                }

                // Individual Movable Band Controls
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("2. Movable Bands (\(state.profile.bands.count))")
                                .font(.headline)
                            Spacer()
                            Button(action: { state.addBand() }) {
                                Label("Add Band", systemImage: "plus")
                            }
                            .disabled(state.profile.bands.count >= 6)
                            .controlSize(.small)
                        }

                        ForEach(Array(state.profile.bands.enumerated()), id: \.element.id) { idx, band in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Band \(idx + 1)")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(String(format: "%.1f%% – %.1f%% (w %.1f%%)", band.x * 100, (band.x + band.w) * 100, band.w * 100))
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(expandedRGBBandIds.contains(band.id) ? "Hide RGB" : "Fine RGB") {
                                        if expandedRGBBandIds.contains(band.id) {
                                            expandedRGBBandIds.remove(band.id)
                                        } else {
                                            expandedRGBBandIds.insert(band.id)
                                        }
                                    }
                                    .controlSize(.small)
                                    if state.profile.bands.count > 1 {
                                        Button(role: .destructive, action: { state.removeBand(id: band.id) }) {
                                            Image(systemName: "trash")
                                        }
                                        .controlSize(.small)
                                    }
                                }

                                HStack(spacing: 12) {
                                    sliderCell(
                                        title: "Brightness",
                                        valueText: String(format: "%+.1f%%", band.brightness),
                                        value: Binding(
                                            get: { state.profile.bands[idx].brightness },
                                            set: { state.profile.bands[idx].brightness = $0 }
                                        ),
                                        range: -50.0...50.0,
                                        label: "Band \(idx + 1) Brightness"
                                    )
                                    sliderCell(
                                        title: "Temp (Cool ↔ Warm)",
                                        valueText: String(format: "%+.1f%%", band.warmth),
                                        value: Binding(
                                            get: { state.profile.bands[idx].warmth },
                                            set: { state.profile.bands[idx].warmth = $0 }
                                        ),
                                        range: -40.0...40.0,
                                        label: "Band \(idx + 1) Temp"
                                    )
                                    sliderCell(
                                        title: "Tint (Green ↔ Mag)",
                                        valueText: String(format: "%+.1f%%", band.tint),
                                        value: Binding(
                                            get: { state.profile.bands[idx].tint },
                                            set: { state.profile.bands[idx].tint = $0 }
                                        ),
                                        range: -40.0...40.0,
                                        label: "Band \(idx + 1) Tint"
                                    )
                                }

                                if expandedRGBBandIds.contains(band.id) {
                                    HStack(spacing: 12) {
                                        sliderCell(
                                            title: "Red",
                                            valueText: String(format: "%+.1f%%", band.red),
                                            value: Binding(
                                                get: { state.profile.bands[idx].red },
                                                set: { state.profile.bands[idx].red = $0 }
                                            ),
                                            range: -30.0...30.0,
                                            label: "Band \(idx + 1) Red"
                                        )
                                        sliderCell(
                                            title: "Green",
                                            valueText: String(format: "%+.1f%%", band.green),
                                            value: Binding(
                                                get: { state.profile.bands[idx].green },
                                                set: { state.profile.bands[idx].green = $0 }
                                            ),
                                            range: -30.0...30.0,
                                            label: "Band \(idx + 1) Green"
                                        )
                                        sliderCell(
                                            title: "Blue",
                                            valueText: String(format: "%+.1f%%", band.blue),
                                            value: Binding(
                                                get: { state.profile.bands[idx].blue },
                                                set: { state.profile.bands[idx].blue = $0 }
                                            ),
                                            range: -30.0...30.0,
                                            label: "Band \(idx + 1) Blue"
                                        )
                                    }
                                }

                                HStack(spacing: 14) {
                                    sliderCell(
                                        title: "Position X",
                                        valueText: String(format: "%.1f%%", band.x * 100),
                                        value: Binding(
                                            get: { state.profile.bands[idx].x },
                                            set: {
                                                let w = state.profile.bands[idx].w
                                                state.profile.bands[idx].x = max(0, min(1 - w, $0))
                                            }
                                        ),
                                        range: 0.0...max(0.01, 1.0 - band.w),
                                        label: "Move Band \(idx + 1)"
                                    )
                                    sliderCell(
                                        title: "Width",
                                        valueText: String(format: "%.1f%%", band.w * 100),
                                        value: Binding(
                                            get: { state.profile.bands[idx].w },
                                            set: {
                                                let x = state.profile.bands[idx].x
                                                state.profile.bands[idx].w = max(0.015, min(1 - x, $0))
                                            }
                                        ),
                                        range: 0.015...max(0.02, 1.0 - band.x),
                                        label: "Resize Band \(idx + 1)"
                                    )
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(state.selectedBandId == band.id ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(state.selectedBandId == band.id ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.18), lineWidth: 1)
                            )
                            .onTapGesture { state.selectedBandId = band.id }
                        }
                    }
                    .padding(6)
                }

                GroupBox("3. Global Blend & White-Screen Surroundings Dimmer") {
                    HStack(spacing: 16) {
                        sliderCell(
                            title: "Dim Outside Bands (for White screens)",
                            valueText: String(format: "%.1f%%", state.profile.surroundDim),
                            value: $state.profile.surroundDim,
                            range: 0.0...40.0,
                            label: "Adjust Outside Dim"
                        )
                        sliderCell(
                            title: "Edge Feather",
                            valueText: String(format: "%.1f px", state.profile.edgeFeather),
                            value: $state.profile.edgeFeather,
                            range: 0.0...20.0,
                            label: "Adjust Edge Feather"
                        )
                    }
                    .padding(6)
                }
            }
            .padding(16)
        }
    }

    private func sliderCell(title: String, valueText: String, value: Binding<Double>, range: ClosedRange<Double>, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.caption2).foregroundColor(.secondary)
                Spacer()
                Text(valueText).font(.caption2.monospacedDigit())
            }
            Slider(value: value, in: range, onEditingChanged: { editing in
                state.handleSliderEditing(editing, label: label)
            })
        }
    }

    // MARK: Tab 2 — IPS Pixel Sweep
    private var pixelSweepTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GroupBox {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill").foregroundColor(.blue).font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IPS LCD Conditioning vs. Hardware Column Bands").font(.headline)
                            Text("Run a 15–30 minute White & Gray Sweep to test and clear temporary IPS image retention or stuck subpixels. If your dim vertical bands stay identical afterward and on reboot, use **Band Studio** to visually even them out.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(6)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Conditioning Mode").font(.headline)
                    ForEach(CleanerMode.allCases) { mode in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: state.selectedMode == mode ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(state.selectedMode == mode ? .accentColor : .secondary)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue).font(.system(size: 13, weight: .semibold))
                                Text(mode.subtitle).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(state.selectedMode == mode ? Color.accentColor.opacity(0.10) : Color(nsColor: .controlBackgroundColor)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(state.selectedMode == mode ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.18), lineWidth: 1))
                        .contentShape(Rectangle())
                        .onTapGesture { state.selectedMode = mode }
                    }
                }

                HStack {
                    Picker("Duration", selection: $state.durationMinutes) {
                        Text("5 min").tag(5)
                        Text("15 min (Recommended)").tag(15)
                        Text("30 min").tag(30)
                        Text("60 min").tag(60)
                        Text("Continuous").tag(0)
                    }
                    .frame(width: 240)
                    Spacer()
                    Button(action: { CleanerSessionManager.shared.startCleaner() }) {
                        Label("Start Full-Screen Sweep", systemImage: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                Text("Press **Esc** (or double-click) anytime to stop. Press **H** to hide the corner timer.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
    }

    // MARK: Tab 3 — Checkpoints, Web Studio Sync & Settings
    private var profileSettingsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GroupBox("Web Calibration Studio Sync (.evendisplay.json)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export your calibrated bands to back up, or import a `.evendisplay.json` profile exported from EvenDisplay Web Studio.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        HStack(spacing: 10) {
                            Button(action: importJSONDialog) {
                                Label("Import .evendisplay.json…", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.borderedProminent)
                            Button(action: exportJSONDialog) {
                                Label("Export .evendisplay.json…", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                    .padding(6)
                }

                GroupBox("Saved Checkpoints (Switch between Light Mode / Dark Mode profiles)") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Checkpoint name (e.g. Daylight, Dark Mode)", text: $newCheckpointName)
                                .textFieldStyle(.roundedBorder)
                            Button("Save Checkpoint") {
                                state.saveCheckpoint(name: newCheckpointName)
                                newCheckpointName = ""
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if state.checkpoints.isEmpty {
                            Text("No saved checkpoints yet.").font(.caption).foregroundColor(.secondary)
                        } else {
                            ForEach(state.checkpoints) { cp in
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(cp.name).font(.callout.weight(.medium))
                                        Text("\(cp.profile.bands.count) bands • Saved \(cp.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button("Restore") { state.restoreCheckpoint(cp) }.controlSize(.small)
                                    Button(role: .destructive) { state.deleteCheckpoint(cp) } label: {
                                        Image(systemName: "trash")
                                    }.controlSize(.small)
                                }
                            }
                        }
                    }
                    .padding(6)
                }

                GroupBox("macOS Integration & Safety") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Launch EvenDisplay at Login", isOn: Binding(
                            get: { state.launchAtLogin },
                            set: { state.toggleLaunchAtLogin($0) }
                        ))
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("100% User-Space & Reversible").font(.callout.weight(.semibold))
                                Text("Never modifies macOS system files, ICC color profiles, GPU registers, or NVRAM.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Factory Reset…", role: .destructive) { showResetConfirm = true }
                        }
                    }
                    .padding(6)
                }
            }
            .padding(16)
        }
    }

    private func exportJSONDialog() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "my-macbook.evendisplay.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try state.profile.toPrettyJSON()
                try data.write(to: url)
                state.flashStatus("Exported \(url.lastPathComponent)")
            } catch {
                state.flashStatus("Export failed: \(error.localizedDescription)")
            }
        }
    }

    private func importJSONDialog() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                try state.importProfileData(data, sourceName: url.lastPathComponent)
            } catch {
                state.flashStatus("Invalid profile file: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - App Delegate, Menu Bar & Entry Point

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var mainWindow: NSWindow?
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMainMenu()
        setupStatusBar()
        showMainWindow()

        if AppState.shared.overlayEnabled {
            OverlayManager.shared.updateOverlay()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            OverlayManager.shared.updateOverlay()
            OverlayManager.shared.updateCalibrationBackdrop()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        CleanerSessionManager.shared.stopCleaner()
        AppState.shared.calibrationBackdropEnabled = false
        AppState.shared.overlayEnabled = false
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "EvenDisplay")
        let revertItem = NSMenuItem(title: "Revert to Stock Screen", action: #selector(panicRevert), keyEquivalent: "0")
        revertItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(revertItem)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit EvenDisplay", action: #selector(quitApp), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo Adjustment", action: #selector(performUndo), keyEquivalent: "z"))
        let redoItem = NSMenuItem(title: "Redo Adjustment", action: #selector(performRedo), keyEquivalent: "z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem?.button {
            btn.image = NSImage(systemSymbolName: "rectangle.split.3x1", accessibilityDescription: "EvenDisplay")
        }
        let menu = NSMenu()
        menu.delegate = self
        statusMenu = menu
        statusItem?.menu = menu
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) { rebuildMenu() }

    private func rebuildMenu() {
        guard let menu = statusMenu else { return }
        menu.removeAllItems()
        menu.addItem(NSMenuItem(title: "Open EvenDisplay", action: #selector(showMainWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(
            title: AppState.shared.overlayEnabled ? "Disable Band Compensator" : "Enable Band Compensator",
            action: #selector(toggleOverlay),
            keyEquivalent: "b"
        ))
        let revertItem = NSMenuItem(title: "Revert to Stock Screen", action: #selector(panicRevert), keyEquivalent: "0")
        revertItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(revertItem)
        menu.addItem(.separator())
        if AppState.shared.canUndo {
            menu.addItem(NSMenuItem(title: "Undo (\(AppState.shared.lastUndoLabel ?? "Last Change"))", action: #selector(performUndo), keyEquivalent: "z"))
        }
        menu.addItem(NSMenuItem(title: "Start IPS Pixel Sweep", action: #selector(quickStartSweep), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit EvenDisplay (Restores Stock)", action: #selector(quitApp), keyEquivalent: "q"))
    }

    @objc func showMainWindow() {
        if mainWindow == nil {
            let hosting = NSHostingController(rootView: ContentView())
            let win = NSWindow(contentViewController: hosting)
            win.title = "EvenDisplay"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.isReleasedWhenClosed = false
            win.center()
            mainWindow = win
        }
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func toggleOverlay() {
        AppState.shared.setOverlayEnabledWithUndo(!AppState.shared.overlayEnabled)
        rebuildMenu()
    }

    @objc func performUndo() {
        if let tv = mainWindow?.firstResponder as? NSTextView, let um = tv.undoManager, um.canUndo {
            um.undo()
            return
        }
        AppState.shared.undo()
        rebuildMenu()
    }

    @objc func performRedo() {
        if let tv = mainWindow?.firstResponder as? NSTextView, let um = tv.undoManager, um.canRedo {
            um.redo()
            return
        }
        AppState.shared.redo()
        rebuildMenu()
    }

    @objc func panicRevert() {
        AppState.shared.panicRevertToStockScreen()
        rebuildMenu()
    }

    @objc func quickStartSweep() {
        CleanerSessionManager.shared.startCleaner()
    }

    @objc func quitApp() {
        CleanerSessionManager.shared.stopCleaner()
        AppState.shared.calibrationBackdropEnabled = false
        AppState.shared.overlayEnabled = false
        NSApp.terminate(nil)
    }
}

#if !EVENDISPLAY_TEST
@main
struct EvenDisplayEntry {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
#endif
