//
//  ConfigureSheet.swift
//  Tally Matrix Screensaver
//
//  The Options… sheet System Settings shows next to the saver.
//
//  ⚠️ THE WINDOW MUST BE HELD SOMEWHERE. `configureSheet` is a getter; if it builds a
//  window and returns it without a strong reference, the window is deallocated out from
//  under the sheet and the Options button appears to do nothing. Hence the singleton.
//

import AppKit
import SwiftUI
import ScreenSaver

final class ConfigureSheetController {

    static let shared = ConfigureSheetController()

    private(set) lazy var window: NSWindow = {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 330),
            styleMask: [.titled],
            backing: .buffered,
            defer: false)
        w.title = "Tally Matrix"
        w.contentView = NSHostingView(rootView: OptionsView { [weak w] in
            guard let w else { return }
            w.sheetParent?.endSheet(w)
        })
        return w
    }()

    private init() {}
}

private struct OptionsView: View {

    let done: () -> Void

    @State private var hourMode = SaverSettings.hourMode
    @State private var colorScheme = SaverSettings.colorScheme
    @State private var rainSize = SaverSettings.rainSize
    @State private var showRain = SaverSettings.showRain
    @State private var glow = SaverSettings.glow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Picker("Hours", selection: $hourMode) {
                    Text(systemLabel).tag("system")
                    Text("12-hour").tag("12")
                    Text("24-hour").tag("24")
                }

                Picker("Colors", selection: $colorScheme) {
                    ForEach(ColorSchemeOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }

                Section {
                    Toggle("Glyph rain", isOn: $showRain)
                    Picker("Rain size", selection: $rainSize) {
                        ForEach(GlyphRainSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .disabled(!showRain)
                    Toggle("Glow", isOn: $glow)
                }
            }
            .formStyle(.grouped)
            // Saved the moment a choice changes, not only on Done — a sheet closed any
            // other way must not silently drop what was picked.
            .onChange(of: hourMode) { _, v in SaverSettings.hourMode = v }
            .onChange(of: colorScheme) { _, v in SaverSettings.colorScheme = v }
            .onChange(of: rainSize) { _, v in SaverSettings.rainSize = v }
            .onChange(of: showRain) { _, v in SaverSettings.showRain = v }
            .onChange(of: glow) { _, v in SaverSettings.glow = v }

            Divider()

            HStack {
                // Readable out loud, so two installs can be told apart at a glance.
                Text(buildLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Spacer()
                Button("Done") {
                    SaverSettings.hourMode = hourMode
                    SaverSettings.colorScheme = colorScheme
                    SaverSettings.rainSize = rainSize
                    SaverSettings.showRain = showRain
                    SaverSettings.glow = glow
                    done()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(width: 420, height: 330)
    }

    /// Stamped into Info.plist by build.sh from git — never typed by hand.
    private var buildLabel: String {
        let info = Bundle(for: TallyMatrixSaverView.self).infoDictionary ?? [:]
        let build = info["CFBundleVersion"] as? String ?? "?"
        let commit = info["TMBuildCommit"] as? String ?? "?"
        let time = info["TMBuildTime"] as? String ?? "?"
        return "Build \(build) · \(commit) · \(time)"
    }

    /// Says what "Follow the Mac" currently resolves to, so the choice is not a mystery.
    private var systemLabel: String {
        "Follow the Mac (" + (SaverSettings.systemUses24Hour ? "24-hour" : "12-hour") + ")"
    }
}
