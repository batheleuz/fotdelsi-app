#!/usr/bin/env bash
#
# Captures d'écran pour la fiche Google Play. Pendant Android de
# `screenshots.sh`, avec trois différences qui viennent toutes des règles de
# Play Console.
#
# ─── 1. L'écran de l'émulateur ne fait PAS la bonne forme ───
#
# Play refuse une capture dont le grand côté dépasse deux fois le petit. Un
# Pixel 9 rend en 1080x2424, soit 2,24 : refusé. On force donc l'écran à
# 1080x1920 — le format recommandé, 9:16 — au lancement :
#
#     ~/Library/Android/sdk/emulator/emulator -avd Pixel_9 -skin 1080x1920
#
# Plutôt qu'un AVD dédié : rien à créer, rien à maintenir, et l'AVD habituel
# garde sa définition réelle pour le développement.
#
# ─── 2. La barre d'état se fige par « demo mode » ───
#
# L'équivalent de `simctl status_bar`. Sans lui, la fiche montre 3:12, une
# pile à moitié vide et les notifications système de l'émulateur.
#
# Une réserve : `notifications -e visible false` n'a AUCUN effet sur Android 16
# — les icônes de notification restent. D'où la découpe ci-dessous.
#
# ─── 3. La barre d'état est découpée, et l'alpha retiré ───
#
# Découpée parce que les icônes système de l'émulateur (roue dentée, info,
# bouclier) n'ont rien à faire sur une fiche : ce n'est pas ce que verra le
# client. Le résultat fait 1080x1850 — toujours dans les clous (1,71).
#
# L'alpha, lui, ferait rejeter le fichier : Play n'accepte que du PNG 24 bits
# sans transparence, et `screencap` produit du RGBA.
#
# Usage :
#   ./tool/screenshots_android.sh prepare            fige la barre d'état
#   ./tool/screenshots_android.sh shot accueil       -> captures/android/accueil.png
#   ./tool/screenshots_android.sh bilan              ce qui est pris, et s'il passe
#   ./tool/screenshots_android.sh reset              rend sa barre d'état
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SORTIE="$APP_DIR/captures/android"

ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"

# Hauteur de la zone à découper, en pixels.
#
# Elle se DEMANDE à l'appareil au lieu d'être écrite en dur : la barre d'état
# ne fait pas 24 dp ici mais 142 px, parce que l'émulateur simule un poinçon
# de caméra et que le système réserve toute la hauteur de l'encoche. Un 70 en
# dur — la valeur théorique — laissait les icônes système en place, et ça ne
# se voyait qu'en regardant les captures de près.
hauteur_barre() {
  "$ADB" shell dumpsys window displays 2>/dev/null \
    | sed -n 's/.*type=displayCutout frame=\[0,0\]\[[0-9]*,\([0-9]*\)\].*/\1/p' \
    | head -1
}

usage() {
  printf 'Usage : %s {prepare|shot <nom>|bilan|reset}\n' "$(basename "$0")" >&2
  exit 64
}

exiger_emulateur() {
  [ -x "$ADB" ] || { printf 'adb introuvable : %s\n' "$ADB" >&2; exit 1; }

  local etat
  etat=$("$ADB" get-state 2>/dev/null | tr -d '\r' || true)
  if [ "$etat" != "device" ]; then
    printf 'Aucun émulateur prêt.\n' >&2
    printf '  Lancez-le AVEC la définition de Play :\n' >&2
    printf '     ~/Library/Android/sdk/emulator/emulator -avd Pixel_9 -skin 1080x1920 &\n' >&2
    exit 1
  fi

  local taille
  taille=$("$ADB" shell wm size 2>/dev/null | tr -d '\r' | awk '{print $NF}')
  if [ "$taille" != "1080x1920" ]; then
    printf 'Écran en %s, attendu 1080x1920.\n' "$taille" >&2
    printf '  Relancez l'"'"'émulateur avec « -skin 1080x1920 » (voir l'"'"'en-tête).\n' >&2
    exit 1
  fi
}

demo() {
  "$ADB" shell am broadcast -a com.android.systemui.demo "$@" >/dev/null 2>&1
}

cmd_prepare() {
  exiger_emulateur

  "$ADB" shell settings put global sysui_demo_allowed 1
  demo -e command enter
  # 9:30 plutôt que le 9:41 d'Apple : c'est l'heure des captures de Google.
  demo -e command clock -e hhmm 0930
  demo -e command battery -e level 100 -e plugged false
  demo -e command network -e wifi show -e level 4
  demo -e command network -e mobile show -e datatype none -e level 4

  mkdir -p "$SORTIE"

  printf '\nÉmulateur prêt (1080x1920, barre figée sur 9:30).\n\n'
  printf 'Installez la vitrine :\n'
  printf '    flutter build apk --release -t lib/main_showcase.dart\n'
  printf '    %s install -r build/app/outputs/flutter-apk/app-release.apk\n\n' "$ADB"
  printf 'Puis, écran par écran :\n'
  printf '    ./tool/screenshots_android.sh shot accueil\n\n'
}

cmd_shot() {
  local nom="${1:-}"
  [ -n "$nom" ] || usage
  exiger_emulateur

  mkdir -p "$SORTIE"
  local brut cible
  brut="$(mktemp -t fotdelsi-shot).png"
  cible="$SORTIE/$nom.png"

  "$ADB" exec-out screencap -p > "$brut"

  local barre
  barre=$(hauteur_barre)
  [ -n "$barre" ] || barre=0

  # `crop` retire la barre d'état ; `format=rgb24` retire l'alpha. Les deux
  # dans la même passe : une capture qui sort d'ici est téléversable telle
  # quelle.
  ffmpeg -v error -y -i "$brut" \
    -vf "crop=iw:ih-$barre:0:$barre,format=rgb24" "$cible"
  rm -f "$brut"

  printf '  ✓ %s\n' "${cible#"$APP_DIR"/}"
}

cmd_bilan() {
  [ -d "$SORTIE" ] || { printf 'Aucune capture.\n'; exit 0; }

  local n=0
  for f in "$SORTIE"/*.png; do
    [ -e "$f" ] || continue
    n=$((n + 1))

    local dims pix l h ratio verdict
    dims=$(ffprobe -v error -show_entries stream=width,height,pix_fmt -of csv=p=0 "$f")
    l=${dims%%,*}
    h=$(printf '%s' "$dims" | cut -d, -f2)
    pix=$(printf '%s' "$dims" | cut -d, -f3)

    # Les trois règles de Play, dans l'ordre où elles font échouer l'envoi.
    verdict="ok"
    ratio=$(awk -v a="$h" -v b="$l" 'BEGIN{printf "%.2f", (a>b? a/b : b/a)}')
    awk -v r="$ratio" 'BEGIN{exit !(r > 2)}' && verdict="ratio $ratio > 2:1"
    [ "$pix" = "rgb24" ] || verdict="$pix — alpha refusé par Play"
    { [ "$l" -ge 320 ] && [ "$h" -le 3840 ]; } || verdict="hors bornes 320–3840"

    if [ "$verdict" = "ok" ]; then
      printf '  ✓ %-16s %sx%s\n' "$(basename "$f" .png)" "$l" "$h"
    else
      printf '  ✗ %-16s %sx%s — %s\n' "$(basename "$f" .png)" "$l" "$h" "$verdict"
    fi
  done

  printf '\n%d capture(s). Play en veut 2 au minimum, 8 au maximum.\n' "$n"
  [ "$n" -ge 2 ] || printf 'Il en manque au moins %d.\n' $((2 - n))
}

cmd_reset() {
  exiger_emulateur
  demo -e command exit
  printf 'Barre d'"'"'état rendue à l'"'"'émulateur.\n'
}

case "${1:-}" in
  prepare) cmd_prepare ;;
  shot)    shift; cmd_shot "$@" ;;
  bilan)   cmd_bilan ;;
  reset)   cmd_reset ;;
  *)       usage ;;
esac
