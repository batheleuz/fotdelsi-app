#!/usr/bin/env bash
#
# Prépare le simulateur pour une séance de captures, et capture à la demande.
#
# ─── Ce que ce script fait, et pourquoi ───
#
# Une capture d'App Store ratée l'est presque toujours pour une raison bête :
# une barre d'état qui affiche 14:03, 23 % de batterie et « Carrier ». Apple ne
# la refuse pas — elle donne juste à la fiche un air d'amateur, sur le seul
# écran que voit un client avant de télécharger.
#
# `simctl status_bar` fige les trois. Et comme le simulateur rend déjà en
# résolution native, la capture sort directement à la taille exigée : aucun
# redimensionnement, donc aucune perte.
#
# ─── Il faut DEUX formats, pas un ───
#
# Ce script affirmait qu'un 6,9" couvrait à lui seul toute la fiche. C'est
# faux : App Store Connect a des emplacements distincts, et téléverser un
# 6,9" dans celui du 6,5" fait échouer l'envoi avec
# « Les dimensions d'au moins une capture d'écran sont incorrectes ».
#
#   6,9"   iPhone 17 Pro Max    1320 x 2868
#   6,5"   Fotdelsi 6.5         1284 x 2778   (iPhone 14 Plus)
#
# L'appareil « Fotdelsi 6.5 » se crée une fois :
#
#   xcrun simctl create "Fotdelsi 6.5" \
#     com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus \
#     com.apple.CoreSimulator.SimRuntime.iOS-26-5
#
# Les captures se rangent seules dans `captures/<format>/`, d'après leurs
# dimensions réelles. Impossible donc de mélanger les deux séries, même en
# oubliant quel simulateur tourne.
#
# Usage :
#   ./tool/screenshots.sh prepare              prépare le simulateur démarré
#   ./tool/screenshots.sh shot accueil         capture -> captures/<format>/accueil.png
#   ./tool/screenshots.sh bilan                ce qui est pris, ce qui manque
#   ./tool/screenshots.sh reset                rend sa barre d'état au simulateur
#
#   FOTDELSI_SIM="Fotdelsi 6.5" ./tool/screenshots.sh prepare
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SORTIE="$APP_DIR/captures"

APPAREIL="${FOTDELSI_SIM:-iPhone 17 Pro Max}"

# Les seules dimensions qu'App Store Connect accepte pour un iPhone. Tout le
# reste est refusé au téléversement — autant le dire ici plutôt que là-bas.
format_de() {
  case "$1" in
    1320x2868|2868x1320|1290x2796|2796x1290) printf '6.9' ;;
    1284x2778|2778x1284|1242x2688|2688x1242) printf '6.5' ;;
    *) printf '' ;;
  esac
}

usage() {
  printf 'Usage : %s {prepare|shot <nom>|bilan|reset}\n' "$(basename "$0")" >&2
  exit 64
}

udid_booted() {
  xcrun simctl list devices booted \
    | awk -v cible="$APPAREIL" '
        index($0, cible) { if (match($0, /[0-9A-F-]{36}/)) { print substr($0, RSTART, RLENGTH); exit } }
      '
}

exiger_booted() {
  local udid
  udid=$(udid_booted)
  if [ -z "$udid" ]; then
    printf 'Aucun « %s » démarré.\n' "$APPAREIL" >&2
    printf '  Démarrez-le, puis relancez :\n' >&2
    printf '     xcrun simctl boot "%s"\n' "$APPAREIL" >&2
    printf '  (autre modèle : FOTDELSI_SIM="Fotdelsi 6.5" %s …)\n' "$(basename "$0")" >&2
    exit 1
  fi
  printf '%s' "$udid"
}

cmd_prepare() {
  local udid
  udid=$(exiger_booted)

  # 9:41 — l'heure de toutes les présentations Apple depuis 2007, et celle de
  # toutes les fiches App Store soignées.
  #
  # `discharging` et non `charged` : `charged` dessine l'éclair de charge dans
  # la pile. Un téléphone branché au mur pendant qu'on lave son linge, ça ne
  # veut rien dire — et Apple montre toujours une pile pleine, sans éclair.
  # (`simctl` n'accepte que `charging`, `charged` ou `discharging`.)
  xcrun simctl status_bar "$udid" override \
    --time "09:41" \
    --batteryState discharging \
    --batteryLevel 100 \
    --cellularMode active \
    --cellularBars 4 \
    --operatorName "" \
    --wifiMode active \
    --wifiBars 3

  mkdir -p "$SORTIE"

  printf '\nSimulateur prêt : %s\n' "$APPAREIL"
  printf '  Barre d'"'"'état figée sur 9:41, batterie pleine, sans opérateur.\n\n'
  printf 'Lancez la vitrine dans un autre terminal :\n'
  printf '    flutter run -t lib/main_showcase.dart -d %s\n\n' "$udid"
  printf 'Puis, écran par écran :\n'
  printf '    ./tool/screenshots.sh shot accueil\n\n'
}

cmd_shot() {
  local nom="${1:-}"
  [ -n "$nom" ] || usage

  local udid
  udid=$(exiger_booted)

  local brut
  brut=$(mktemp -t fotdelsi-shot).png
  xcrun simctl io "$udid" screenshot --type png "$brut" >/dev/null 2>&1

  local dims
  dims=$(sips -g pixelWidth -g pixelHeight "$brut" 2>/dev/null \
    | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w"x"h}')

  local format
  format=$(format_de "$dims")

  # Une capture hors format ne sera pas rangée : la garder parmi les bonnes
  # ferait échouer un téléversement des semaines plus tard, sans indice.
  if [ -z "$format" ]; then
    rm -f "$brut"
    printf '  ✗ %s : %s — format refusé par App Store Connect\n' "$nom" "$dims" >&2
    printf '      Attendu 1320x2868 (6,9") ou 1284x2778 (6,5").\n' >&2
    printf '      Mauvais simulateur : voir l'"'"'en-tête de ce script.\n' >&2
    exit 1
  fi

  mkdir -p "$SORTIE/$format"
  mv "$brut" "$SORTIE/$format/$nom.png"
  printf '  ✓ %-22s %-10s %s\n' "$nom.png" "$dims" "captures/$format/"
}

cmd_bilan() {
  printf '\nCaptures par format\n\n'
  local manque=0
  for format in 6.9 6.5; do
    local n=0
    [ -d "$SORTIE/$format" ] && n=$(find "$SORTIE/$format" -name '*.png' | wc -l | tr -d ' ')
    if [ "$n" -eq 0 ]; then
      printf '  ✗ %-5s  aucune capture\n' "$format\""
      manque=$((manque + 1))
    else
      printf '  ✓ %-5s  %s capture(s)\n' "$format\"" "$n"
      find "$SORTIE/$format" -name '*.png' | sort | sed 's|.*/|        |'
    fi
  done
  printf '\n'
  if [ "$manque" -gt 0 ]; then
    printf 'App Store Connect a un emplacement par format : les deux séries\n'
    printf 'sont à fournir. Voir l'"'"'en-tête de ce script.\n\n'
    return 1
  fi
}

cmd_reset() {
  local udid
  udid=$(exiger_booted)
  xcrun simctl status_bar "$udid" clear
  printf 'Barre d'"'"'état rendue au simulateur.\n'
}

case "${1:-}" in
  prepare) cmd_prepare ;;
  shot)    shift; cmd_shot "$@" ;;
  bilan)   cmd_bilan ;;
  reset)   cmd_reset ;;
  *)       usage ;;
esac
