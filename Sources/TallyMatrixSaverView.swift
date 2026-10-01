//
//  TallyMatrixSaverView.swift
//  Tally Matrix Screensaver
//
//  THE WRAPPER. This is the only file macOS actually knows about — Info.plist names
//  this class as NSPrincipalClass, the system instantiates it, and everything else is
//  SwiftUI hanging off it.
//
//  ⚠️ @objc(TallyMatrixSaverView) IS LOAD-BEARING. Swift mangles class names; the
//  screensaver engine looks the class up by the plain string in Info.plist. Without the
//  @objc name the bundle loads and then does nothing, with no error anywhere — which is
//  the failure shape this apartment keeps meeting. If the saver ever appears in the list
//  and shows a black rectangle, check this first.
//

import ScreenSaver
import SwiftUI
import AppKit

@objc(TallyMatrixSaverView)
final class TallyMatrixSaverView: ScreenSaverView {

    private var hosting: NSHostingView<ClockFaceView>?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        // SwiftUI drives its own animation and the clock ticks on its own Timer, so the
        // ScreenSaverView animation loop has nothing to do. Left slow deliberately
        // rather than at 30fps, so it is not burning a wake-up every frame for nothing.
        animationTimeInterval = 1.0

        buildFace()

        // The preview in System Settings shares a process with the Options sheet, so a
        // change there reaches it at once instead of after the next start.
        NotificationCenter.default.addObserver(forName: SaverSettings.didChange, object: nil,
                                               queue: .main) { [weak self] _ in
            self?.buildFace()
        }
    }

    /// ClockFaceView reads its settings when it is constructed, so a NEW one is built
    /// every time the saver starts. ⛔ macOS keeps legacyScreenSaver — and this view —
    /// alive between activations; building the face only in init is why a changed
    /// color never appeared (2026-10-01).
    private func buildFace() {
        hosting?.removeFromSuperview()
        let view = NSHostingView(rootView: ClockFaceView(isPreview: isPreview))
        view.frame = bounds
        view.autoresizingMask = [.width, .height]
        addSubview(view)
        hosting = view
    }

    override func startAnimation() {
        super.startAnimation()
        buildFace()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Tally Matrix Screensaver is not loaded from a nib")
    }

    override func draw(_ rect: NSRect) {
        // The SwiftUI subview paints everything. Black underneath so a resize or a
        // first frame never flashes the desktop through.
        NSColor.black.setFill()
        rect.fill()
    }

    override func animateOneFrame() {
        // Intentionally empty. See animationTimeInterval above.
    }

    override var hasConfigureSheet: Bool { true }
    override var configureSheet: NSWindow? { ConfigureSheetController.shared.window }
}
