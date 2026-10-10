#!/bin/zsh
# Builds AIUsage.app signed with Developer ID, notarizes it and produces a
# zip ready for GitHub Releases.
#
# One-time setup:
#   1. Install a "Developer ID Application" certificate (Xcode → Settings →
#      Accounts → Manage Certificates → + → Developer ID Application).
#   2. Save notarization credentials (use an app-specific password from
#      account.apple.com):
#        xcrun notarytool store-credentials AIUsage-notary \
#          --apple-id <apple-id> --team-id <TEAM_ID> --password <app-password>
set -euo pipefail
cd "$(dirname "$0")/.."

PROFILE=${NOTARY_PROFILE:-AIUsage-notary}
IDENTITY=$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' | head -1)
[[ -n "$IDENTITY" ]] || { echo "✗ No hay certificado 'Developer ID Application' en el Keychain"; exit 1; }
TEAM_ID=$(sed -n 's/.*(\([A-Z0-9]*\))$/\1/p' <<< "$IDENTITY")
VERSION=$(sed -n 's/.*MARKETING_VERSION: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/p' project.yml)
OUT=build/release
APP=$OUT/Build/Products/Release/AIUsage.app
ZIP=$OUT/AIUsage-$VERSION.zip

echo "→ $IDENTITY · v$VERSION"
xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1 \
  || { echo "✗ Falta el perfil de notarización '$PROFILE' (ver cabecera de este script)"; exit 1; }

rm -rf "$OUT"
TEAM_ID=$TEAM_ID xcodegen generate --quiet
xcodebuild -project AIUsage.xcodeproj -scheme AIUsage -configuration Release \
  -derivedDataPath "$OUT" -quiet build \
  DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application" OTHER_CODE_SIGN_FLAGS=--timestamp

codesign --verify --deep --strict "$APP"

echo "→ Notarizando (tarda unos minutos)…"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"

# Re-zip so the stapled ticket ships inside the app.
rm "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute -v "$APP"

echo "✓ $ZIP"
echo "  Publicar: gh release create v$VERSION $ZIP --title \"AI Usage $VERSION\""
