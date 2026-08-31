# Tally Matrix Screensaver

The **Tally Matrix Clock** — already on the App Store for Apple TV — as a real macOS
screensaver. Glyph rain behind, tally matrices in front, no audio.

```
screen saver, not an app that goes full screen
```

## Install

```bash
./build.sh
cp -R "build/Tally Matrix.saver" ~/Library/Screen\ Savers/
```

Then **System Settings → Screen Saver → Other → Tally Matrix**.

If the saver was already selected when you rebuild, quit and reopen System Settings —
the screensaver engine caches the loaded bundle.

## How it reads the time

Each digit is drawn as a **tally**: a 3×3 grid (or 1×3 for the hours-tens place) with as
many squares lit as the digit's value, in random positions that reshuffle when the digit
changes. The top-left 1×3 doubles as the PM indicator in 12-hour mode.

It is not meant to be glanceable like a clock face. It is meant to be *read*, which is
the point of it.

## Layout

| File | Origin |
|---|---|
| `Sources/GlyphRainView.swift` | **copied verbatim** from the tvOS app |
| `Sources/TallyMatrixViews.swift` | **copied verbatim** from the tvOS app |
| `Sources/Models.swift` | **copied verbatim** from the tvOS app |
| `Sources/ClockFaceView.swift` | new — composes the above for a screensaver |
| `Sources/TallyMatrixSaverView.swift` | new — the `ScreenSaverView` the system loads |

**The three copied files must stay copies.** They type-check against macOS unchanged
(measured 2026-08-30: 0 errors, 0.48s). If they need editing, edit them in the tvOS app
and re-copy, so the two products cannot drift apart silently.

## What is deliberately absent

- **Audio.** Removing the CryoTunes playback was the brief, and it is right twice over:
  it drops every audio-licensing entanglement, and savers run inside
  `legacyScreenSaver`'s sandbox where sound is unwelcome anyway.
- **Settings, weather, location.** The tvOS `ContentView` is 774 lines of chrome that a
  screensaver has no use for. **WeatherKit inside the screensaver sandbox is unproven**
  and is not assumed to work.
- **A configure sheet.** Re-theme by changing `colorScheme` and `rainSize` at the top of
  `ClockFaceView.swift`.

## Why there is no Xcode project

A `.saver` is a bundle: an `Info.plist` and a Mach-O **bundle** whose `NSPrincipalClass`
the screensaver engine instantiates. `build.sh` does it in two steps — `swiftc` to an
object file, then `clang -bundle` to link — because swiftc's own link modes emit a dylib
or an executable, and neither is what a plugin bundle is.

## Distribution

**A `.saver` cannot go on the Mac App Store** — Guideline 2.4.5(ii) forbids installing
code into shared locations, and a screensaver has to live in `~/Library/Screen Savers/`.

Outside the store it is Developer ID signing plus notarization, which is the sanctioned
path and not a workaround. `build.sh` currently signs **ad-hoc**, which is enough to run
on the machine that built it.
