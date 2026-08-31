//
//  ClockFaceView.swift
//  Tally Matrix Screensaver
//
//  THE CLOCK, COMPOSED FOR A SCREENSAVER RATHER THAN A TELEVISION.
//
//  Michael, 2026-08-30: "i do like the matrix clock in front of the glyph" — so the
//  rain is the background and the tally matrices sit in front of it. That was his call;
//  the alternative on the table was rain alone.
//
//  WHAT IS DELIBERATELY NOT HERE, and why:
//
//  - NO AUDIO. His instruction was "minus the cryotunes audio". It is right twice over:
//    it removes every audio-licensing entanglement, and screen savers run inside
//    legacyScreenSaver's sandbox where playing sound is unwelcome anyway.
//  - NO WEATHER, NO LOCATION. The tvOS app's ContentView is 774 lines of
//    chrome — focus handling, pickers, transport controls. A screensaver has no UI, so
//    almost none of it has a job. WeatherKit specifically is UNPROVEN inside the
//    screensaver sandbox and is not being assumed to work.
//
//  The three files beside this one — GlyphRainView, TallyMatrixViews, Models — are
//  COPIED VERBATIM from the tvOS app and must stay that way. They type-check against
//  macOS unchanged, measured 2026-08-30: 0 errors in 0.48s. If they ever need editing,
//  edit them in the app and re-copy, so the two products cannot drift apart silently.
//

import SwiftUI
import Combine

/// The tvOS layout uses fixed spacings (60, 40, 120) tuned for a television. A Mac
/// screensaver gets whatever the display is, including a tiny preview thumbnail in
/// System Settings — so the whole face is laid out at a fixed design size and scaled to
/// fit. That keeps the proportions the app already ships rather than reflowing them.
private let designSize = CGSize(width: 1920, height: 1080)

struct ClockFaceView: View {

    /// System Settings renders a small live preview. It gets the same view, scaled.
    var isPreview: Bool = false

    @State private var now = Date()
    @State private var patterns: [Int: Set<Int>] = [:]
    @State private var colors: [Int: [Color]] = [:]

    /// Read once, at construction. The saver is rebuilt when Options is dismissed,
    /// so there is nothing to observe at runtime.
    private let colorScheme = SaverSettings.colorScheme
    private let rainSize = SaverSettings.rainSize
    private let showRain = SaverSettings.showRain
    private let use24Hour = SaverSettings.use24Hour
    private let glow = SaverSettings.glow

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / designSize.width,
                            geo.size.height / designSize.height)
            ZStack {
                Color.black

                if showRain {
                    GlyphRainView(colorScheme: colorScheme, textTargets: [], rainSize: rainSize)
                }

                HStack(spacing: 0) {
                    TallyMatrix1x3(value: hoursTens,
                                   pattern: patterns[0] ?? [],
                                   colors: colors[0] ?? [],
                                   isPMIndicator: !use24Hour,
                                   showPM: isPM,
                                   glow: glow)
                    Spacer().frame(width: 40)
                    TallyMatrix3x3(value: hoursOnes, pattern: patterns[1] ?? [],
                                   colors: colors[1] ?? [], glow: glow)
                    Spacer().frame(width: 120)
                    TallyMatrix3x3(value: minutesTens, pattern: patterns[2] ?? [],
                                   colors: colors[2] ?? [], glow: glow)
                    Spacer().frame(width: 40)
                    TallyMatrix3x3(value: minutesOnes, pattern: patterns[3] ?? [],
                                   colors: colors[3] ?? [], glow: glow)
                }
                .frame(width: designSize.width, height: designSize.height)
                .scaleEffect(scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onAppear { updatePatterns() }
        .onReceive(tick) { t in
            let before = [hoursTens, hoursOnes, minutesTens, minutesOnes]
            now = t
            if [hoursTens, hoursOnes, minutesTens, minutesOnes] != before {
                updatePatterns()
            }
        }
    }

    // MARK: - Digits  (identical arithmetic to the tvOS app)

    private var displayHour: Int {
        let h = Calendar.current.component(.hour, from: now)
        guard !use24Hour else { return h }
        let twelve = h % 12
        return twelve == 0 ? 12 : twelve
    }
    private var isPM: Bool { Calendar.current.component(.hour, from: now) >= 12 }
    private var hoursTens: Int { displayHour / 10 }
    private var hoursOnes: Int { displayHour % 10 }
    private var minutesTens: Int { Calendar.current.component(.minute, from: now) / 10 }
    private var minutesOnes: Int { Calendar.current.component(.minute, from: now) % 10 }

    // MARK: - Pattern and colour generation  (lifted from the app's ContentView)

    private func updatePatterns() {
        patterns[0] = randomPattern(for: hoursTens, totalSquares: 3)
        patterns[1] = randomPattern(for: hoursOnes, totalSquares: 9)
        patterns[2] = randomPattern(for: minutesTens, totalSquares: 9)
        patterns[3] = randomPattern(for: minutesOnes, totalSquares: 9)

        let shared: Color? = colorScheme == .singleColor
            ? [Color.red, .green, .blue].randomElement()! : nil

        colors[0] = generateColors(count: 3, shared: shared)
        colors[1] = generateColors(count: 9, shared: shared)
        colors[2] = generateColors(count: 9, shared: shared)
        colors[3] = generateColors(count: 9, shared: shared)
    }

    private func randomPattern(for value: Int, totalSquares: Int) -> Set<Int> {
        guard value > 0 else { return [] }
        var pattern = Set<Int>()
        while pattern.count < value {
            pattern.insert(Int.random(in: 0..<totalSquares))
        }
        return pattern
    }

    private func generateColors(count: Int, shared: Color? = nil) -> [Color] {
        let primary: [Color] = [.red, .green, .blue]
        switch colorScheme {
        case .randomRGB:
            return (0..<count).map { _ in primary.randomElement()! }
        case .matrixColors:
            let c = primary.randomElement()!
            return Array(repeating: c, count: count)
        case .singleColor:
            return Array(repeating: shared ?? primary.randomElement()!, count: count)
        case .phosphorGreen:
            return Array(repeating: Color(red: 0.0, green: 1.0, blue: 0.0), count: count)
        case .phosphorAmber:
            return Array(repeating: Color(red: 1.0, green: 0.75, blue: 0.0), count: count)
        case .phosphorBlue:
            return Array(repeating: Color(red: 0.2, green: 0.4, blue: 1.0), count: count)
        case .crimson:
            return Array(repeating: Color(red: 0.6, green: 0.0, blue: 0.05), count: count)
        case .cgaPhosphor:
            let cga: [Color] = [
                Color(red: 0.0, green: 0.0, blue: 0.67), Color(red: 0.0, green: 0.67, blue: 0.0),
                Color(red: 0.0, green: 0.67, blue: 0.67), Color(red: 0.67, green: 0.0, blue: 0.0),
                Color(red: 0.67, green: 0.0, blue: 0.67), Color(red: 0.67, green: 0.33, blue: 0.0),
                Color(red: 0.33, green: 0.33, blue: 1.0), Color(red: 0.33, green: 1.0, blue: 0.33),
                Color(red: 0.33, green: 1.0, blue: 1.0), Color(red: 1.0, green: 0.33, blue: 0.33),
                Color(red: 1.0, green: 0.33, blue: 1.0), Color(red: 1.0, green: 1.0, blue: 0.33),
                Color(red: 1.0, green: 1.0, blue: 1.0),
            ]
            return (0..<count).map { _ in cga.randomElement()! }
        }
    }
}
