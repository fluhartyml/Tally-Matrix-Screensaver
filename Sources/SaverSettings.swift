//
//  SaverSettings.swift
//  Tally Matrix Screensaver
//
//  Preferences for a screensaver do NOT go in UserDefaults.standard. A saver is loaded
//  into whatever process is hosting it — System Settings for the preview, and
//  legacyScreenSaver for the real thing — so "standard" means a different domain
//  depending on who loaded you, and settings appear to vanish between the preview and
//  the running saver. `ScreenSaverDefaults(forModuleWithName:)` pins the
//  domain to this bundle so both hosts read the same file.
//
//  ⭐ THE 12/24-HOUR DEFAULT IS READ FROM THE SYSTEM, NOT ASKED.
//
//  Michael, 2026-08-30: "it does but the system clock is 24hrs and talley is 12hrs."
//  The Mac already knows the answer, so making him set it a second time would be asking
//  him to repeat himself to a machine that could have looked. It stays overridable —
//  the point is the DEFAULT is derived rather than guessed at 12.
//

import Foundation
import ScreenSaver

enum SaverSettings {

    static let bundleID = "com.nightgard.TallyMatrixScreensaver"

    private static var defaults: ScreenSaverDefaults {
        ScreenSaverDefaults(forModuleWithName: bundleID) ?? .init()
    }

    // MARK: - The system's own 12/24-hour answer

    /// True when this Mac's locale + Language & Region setting formats time as 24-hour.
    ///
    /// The template "j" asks the formatter for whichever hour field the user has chosen;
    /// a 12-hour result carries an AM/PM field ("a") and a 24-hour result does not.
    /// This is the documented way to ask, and it is why the code does not look at
    /// `AppleICUForce24HourTime` — that key is unset on a Mac that is 24-hour purely
    /// because of its region.
    static var systemUses24Hour: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0,
                                              locale: .current) ?? ""
        return !format.contains("a")
    }

    // MARK: - Stored values

    private enum Key {
        static let hourMode = "hourMode"        // "system" | "12" | "24"
        static let colorScheme = "colorScheme"
        static let rainSize = "rainSize"
        static let showRain = "showRain"
        static let glow = "glow"
    }

    /// "system" follows Language & Region and is the default.
    static var hourMode: String {
        get { defaults.string(forKey: Key.hourMode) ?? "system" }
        set { defaults.set(newValue, forKey: Key.hourMode); defaults.synchronize() }
    }

    /// The resolved answer the clock actually uses.
    static var use24Hour: Bool {
        switch hourMode {
        case "12": return false
        case "24": return true
        default: return systemUses24Hour
        }
    }

    static var colorScheme: ColorSchemeOption {
        get {
            guard let raw = defaults.string(forKey: Key.colorScheme),
                  let v = ColorSchemeOption(rawValue: raw) else { return .matrixColors }
            return v
        }
        set { defaults.set(newValue.rawValue, forKey: Key.colorScheme); defaults.synchronize() }
    }

    static var rainSize: GlyphRainSize {
        get {
            guard let raw = defaults.string(forKey: Key.rainSize),
                  let v = GlyphRainSize(rawValue: raw) else { return .medium }
            return v
        }
        set { defaults.set(newValue.rawValue, forKey: Key.rainSize); defaults.synchronize() }
    }

    static var showRain: Bool {
        get { defaults.object(forKey: Key.showRain) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showRain); defaults.synchronize() }
    }

    static var glow: Bool {
        get { defaults.object(forKey: Key.glow) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.glow); defaults.synchronize() }
    }
}
