#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/marndiaye/develop/flutter/bin/flutter}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$ROOT_DIR/ios/ExportOptions.plist}"
RELEASE_PATH="${RELEASE_PATH:-/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin}"
UPLOAD=true
SKIP_PREFLIGHT=false
BUILD_NAME=""
BUILD_NUMBER=""

usage() {
  cat <<'EOF'
Construit l'IPA Release puis l'envoie vers App Store Connect.

Usage :
  ./tool/release_ios.sh [options]

Options :
  --build-only            Construit l'IPA sans l'envoyer.
  --build-name VERSION    Remplace la version iOS (ex. 1.2.0).
  --build-number NUMBER   Remplace le numéro de build iOS (ex. 24).
  --skip-preflight        Ignore le contrôle de configuration push iOS.
  -h, --help              Affiche cette aide.

Variables requises pour l'envoi :
  APPLE_ID                         Adresse Apple ID App Store Connect.
  APPLE_APP_SPECIFIC_PASSWORD      Mot de passe spécifique à l'application.

Variables optionnelles :
  FLUTTER_BIN                Chemin du binaire Flutter.
  EXPORT_OPTIONS_PLIST       Chemin du fichier ExportOptions.plist.
  RELEASE_PATH               PATH utilisé pendant le build.
EOF
}

fail() {
  printf '\nErreur : %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-only)
      UPLOAD=false
      shift
      ;;
    --build-name)
      [[ $# -ge 2 ]] || fail "--build-name attend une valeur."
      BUILD_NAME="$2"
      shift 2
      ;;
    --build-number)
      [[ $# -ge 2 ]] || fail "--build-number attend une valeur."
      BUILD_NUMBER="$2"
      shift 2
      ;;
    --skip-preflight)
      SKIP_PREFLIGHT=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "option inconnue : $1"
      ;;
  esac
done

[[ "$(uname -s)" == "Darwin" ]] || fail "la livraison iOS doit être lancée depuis macOS."
[[ -x "$FLUTTER_BIN" ]] || fail "Flutter est introuvable ou non exécutable : $FLUTTER_BIN"
[[ -f "$EXPORT_OPTIONS_PLIST" ]] || fail "ExportOptions.plist est introuvable : $EXPORT_OPTIONS_PLIST"
command -v /usr/bin/xcrun >/dev/null 2>&1 || fail "xcrun est introuvable. Installez Xcode."

if [[ "$UPLOAD" == true ]]; then
  [[ -n "${APPLE_ID:-}" ]] || fail "APPLE_ID n'est pas défini."
  [[ -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]] || \
    fail "APPLE_APP_SPECIFIC_PASSWORD n'est pas défini."
fi

cd "$ROOT_DIR"

if [[ "$SKIP_PREFLIGHT" == false ]]; then
  printf '\n[1/3] Vérification de la configuration iOS\n'
  "$ROOT_DIR/tool/check_push_ios.sh" Release
else
  printf '\n[1/3] Vérification iOS ignorée (--skip-preflight)\n'
fi

build_args=(
  build ipa
  --release
  "--export-options-plist=$EXPORT_OPTIONS_PLIST"
)
[[ -z "$BUILD_NAME" ]] || build_args+=("--build-name=$BUILD_NAME")
[[ -z "$BUILD_NUMBER" ]] || build_args+=("--build-number=$BUILD_NUMBER")

marker="$(mktemp -t fotdelsi-ios-release.XXXXXX)"
trap 'rm -f "$marker"' EXIT

printf '\n[2/3] Construction de l’IPA Release\n'
env PATH="$RELEASE_PATH" "$FLUTTER_BIN" "${build_args[@]}"

IPA_DIR="$ROOT_DIR/build/ios/ipa"
IPA_PATH="$(find "$IPA_DIR" -maxdepth 1 -type f -name '*.ipa' -newer "$marker" -print 2>/dev/null | sed -n '1p')"
[[ -n "$IPA_PATH" && -f "$IPA_PATH" ]] || \
  fail "aucune nouvelle IPA trouvée dans $IPA_DIR."

printf '\nIPA générée : %s\n' "$IPA_PATH"

if [[ "$UPLOAD" == false ]]; then
  printf '\n[3/3] Envoi ignoré (--build-only)\n'
  exit 0
fi

printf '\n[3/3] Envoi vers App Store Connect\n'
/usr/bin/xcrun altool \
  --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --username "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD"

printf '\nLivraison terminée. Le traitement du build continue maintenant dans App Store Connect.\n'
