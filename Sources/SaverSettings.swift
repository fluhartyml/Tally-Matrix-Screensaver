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
import os

enum SaverSettings {

    static let bundleID = "com.nightgard.TallyMatrixScreensaver"

    // ⛔ ScreenSaverDefaults WAS NEVER WRITING. Measured 2026-10-01: after Michael chose
    // "blue phosphor" and pressed Done, no Tally Matrix preference file existed anywhere
    // in ~/Library/Preferences, any container or any group container — every folder was
    // readable, so the null result is real. The Options sheet only LOOKED saved because
    // it is a singleton and kept the choice in memory; the running saver read its default
    // (rainbow) every time.
    //
    // So the settings now live in an explicit plist whose path is logged on every read
    // and write. Inside the sandbox, Application Support resolves to the host's
    // container, so the file can be found and read back rather than trusted.
    // Watch it live:  log stream --predicate 'subsystem == "com.nightgard.TallyMatrixScreensaver"'

    static let didChange = Notification.Name("TallyMatrixSettingsDidChange")

    private static let log = Logger(subsystem: bundleID, category: "settings")

    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        return base.appendingPathComponent(bundleID, isDirectory: true)
                   .appendingPathComponent("settings.plist")
    }

    /// Read fresh from disk every time — never cached, so a new value is seen the next
    /// time anything asks.
    private static func load() -> [String: Any] {
        let url = fileURL
        guard let data = try? Data(contentsOf: url) else {
            log.info("no settings file yet at \(url.path, privacy: .public)")
            return [:]
        }
        do {
            let obj = try PropertyListSerialization.propertyList(from: data, format: nil)
            return obj as? [String: Any] ?? [:]
        } catch {
            log.error("unreadable settings at \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return [:]
        }
    }

    private static func save(_ key: String, _ value: Any) {
        var dict = load()
        dict[key] = value
        let url = fileURL
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(fromPropertyList: dict,
                                                          format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
            log.info("saved \(key, privacy: .public)=\(String(describing: value), privacy: .public) to \(url.path, privacy: .public)")
        } catch {
            log.error("FAILED to save \(key, privacy: .public) to \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
        NotificationCenter.default.post(name: didChange, object: nil)
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
        get { load()[Key.hourMode] as? String ?? "system" }
        set { save(Key.hourMode, newValue) }
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
            guard let raw = load()[Key.colorScheme] as? String,
                  let v = ColorSchemeOption(rawValue: raw) else { return .matrixColors }
            return v
        }
        set { save(Key.colorScheme, newValue.rawValue) }
    }

    static var rainSize: GlyphRainSize {
        get {
            guard let raw = load()[Key.rainSize] as? String,
                  let v = GlyphRainSize(rawValue: raw) else { return .medium }
            return v
        }
        set { save(Key.rainSize, newValue.rawValue) }
    }

    static var showRain: Bool {
        get { load()[Key.showRain] as? Bool ?? true }
        set { save(Key.showRain, newValue) }
    }

    static var glow: Bool {
        get { load()[Key.glow] as? Bool ?? true }
        set { save(Key.glow, newValue) }
    }
}
