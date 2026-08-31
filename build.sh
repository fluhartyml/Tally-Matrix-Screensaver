#!/bin/bash
#
# Builds Tally Matrix.saver without an Xcode project.
#
# A .saver is just a bundle: Info.plist plus a Mach-O BUNDLE (not a dylib, not an
# executable) whose NSPrincipalClass the screensaver engine instantiates. Two steps —
# swiftc to an object file, then clang -bundle to link it — because swiftc's own link
# modes emit -dylib or -execute and neither is what a plugin bundle is.
#
set -euo pipefail
cd "$(dirname "$0")"

NAME="TallyMatrixScreensaver"
BUNDLE="build/Tally Matrix.saver"
TARGET="arm64-apple-macos15.0"
SDK="$(xcrun --sdk macosx --show-sdk-path)"

rm -rf build
mkdir -p "$BUNDLE/Contents/MacOS"

echo "==> compiling"
xcrun swiftc -wmo -emit-object \
    -module-name "$NAME" \
    -target "$TARGET" -sdk "$SDK" \
    -O \
    Sources/*.swift \
    -o "build/$NAME.o"

echo "==> linking bundle"
xcrun clang -bundle \
    -target "$TARGET" -isysroot "$SDK" \
    -o "$BUNDLE/Contents/MacOS/$NAME" \
    "build/$NAME.o" \
    -framework ScreenSaver -framework AppKit -framework SwiftUI -framework Foundation \
    -L/usr/lib/swift -Xlinker -rpath -Xlinker /usr/lib/swift

cp Info.plist "$BUNDLE/Contents/Info.plist"

echo "==> signing (ad-hoc; enough to run locally)"
codesign --force --deep --sign - "$BUNDLE"

echo "==> built: $BUNDLE"
file "$BUNDLE/Contents/MacOS/$NAME"
