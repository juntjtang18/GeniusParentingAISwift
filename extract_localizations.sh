#!/bin/bash
# file: extract_localizations.sh
# Keyless localization export/import for Xcode 15/16.
# - Exports to a temp dir
# - Imports each generated .xcloc bundle
# - Leaves helpful diagnostics if nothing was exported

set -euo pipefail

PROJECT="GeniusParentingAISwift.xcodeproj"   # adjust if needed
OUTDIR="$(mktemp -d)"
EXPORT_DIR="$OUTDIR/xcloc"

echo "📦 Exporting localizations…"
xcodebuild \
  -project "$PROJECT" \
  -exportLocalizations \
  -localizationPath "$EXPORT_DIR"

# Find .xcloc bundles inside the export dir
mapfile -t XCLOCS < <(find "$EXPORT_DIR" -maxdepth 1 -type d -name "*.xcloc" | sort)

if [[ "${#XCLOCS[@]}" -eq 0 ]]; then
  echo "⚠️  No .xcloc bundles were produced."
  echo "   • Make sure your project builds and has at least one localization (e.g., English)."
  echo "   • In Xcode, enable: 'Use Compiler to Extract Swift Strings' (so literals are extracted to the catalog)."
  echo "   • Then re-run this script."
  exit 1
fi

echo "📥 Importing localizations from ${#XCLOCS[@]} bundle(s)…"
for BUNDLE in "${XCLOCS[@]}"; do
  echo "→ Importing: $BUNDLE"
  xcodebuild \
    -project "$PROJECT" \
    -importLocalizations \
    -localizationPath "$BUNDLE"
done

echo "✅ Done. Xcode updated/created your String Catalog (Localizable.xcstrings)."
