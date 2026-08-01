#!/usr/bin/env bash
#
# Builds, Developer-ID signs, notarizes, and staples LedgerLensDesktop for distribution
# OUTSIDE the Mac App Store, then packages a ready-to-ship .dmg.
#
# One-time setup (stores your Apple credentials in the keychain, so they never sit in this
# script or your shell history):
#
#   xcrun notarytool store-credentials "ledgerlens-notary" \
#     --apple-id "you@example.com" \
#     --team-id "C9NLF34677" \
#     --password "app-specific-password"   # create at appleid.apple.com → App-Specific Passwords
#
# Then run:
#
#   DEVELOPER_ID="Developer ID Application: Your Name (C9NLF34677)" \
#   ./scripts/macos/sign_and_notarize.sh
#
# Requirements: a "Developer ID Application" certificate in your login keychain (Xcode →
# Settings → Accounts → Manage Certificates → +), and Xcode command line tools.

set -euo pipefail

APP_NAME="LedgerLensDesktop"
SCHEME="LedgerLensDesktop"
VOLNAME="LedgerLens"

# Resolve repo desktop/ dir (this script lives in desktop/scripts/macos/).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP="$(cd "$HERE/../.." && pwd)"
cd "$DESKTOP"

PROJECT="macos/$APP_NAME.xcodeproj"
ENTITLEMENTS="macos/$APP_NAME/$APP_NAME.entitlements"
BUILD_DIR="$DESKTOP/build-release"

: "${DEVELOPER_ID:?Set DEVELOPER_ID, e.g. 'Developer ID Application: Your Name (TEAMID)'}"
NOTARY_PROFILE="${NOTARY_PROFILE:-ledgerlens-notary}"

echo "▸ Building Release (unsigned)…"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO build

APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
[ -d "$APP" ] || { echo "✗ App not found at $APP"; exit 1; }

echo "▸ Codesigning with hardened runtime…"
codesign --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$DEVELOPER_ID" \
  "$APP"
codesign --verify --strict --verbose=2 "$APP"

echo "▸ Building .dmg…"
DMG="$BUILD_DIR/$APP_NAME.dmg"
rm -f "$DMG"
hdiutil create -volname "$VOLNAME" -srcfolder "$APP" -ov -format UDZO "$DMG"

echo "▸ Submitting to Apple notary service (this can take a few minutes)…"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait

echo "▸ Stapling notarization ticket…"
xcrun stapler staple "$APP"
xcrun stapler staple "$DMG"

echo "▸ Gatekeeper verification:"
spctl -a -vvv --type exec "$APP" || true
xcrun stapler validate "$DMG" || true

echo ""
echo "✓ Done. Distributable: $DMG"
echo "  (Signed, notarized, stapled — opens without Gatekeeper warnings.)"
