#!/usr/bin/env bash
#
# Vérifie que la chaîne du push iOS est cohérente AVANT de produire une archive.
#
# ─── Pourquoi ce script existe ───
#
# Une archive à laquelle il manque un maillon s'installe et fonctionne
# normalement : seules les notifications ne viennent jamais. La panne ne se voit
# donc qu'à l'usage, souvent après la livraison aux testeurs, et rien à l'écran
# ne dit pourquoi. Ce script rend l'incohérence visible en une commande.
#
# Il ne remplace pas les étapes du portail Apple (App ID avec Push, clé APNs
# déposée dans Firebase) — celles-là ne se vérifient pas depuis un poste de
# travail. Voir RESTANT.md § 1.4.
#
# Usage :  ./tool/check_push_ios.sh [Release|Debug|Profile]
set -uo pipefail

CONFIG="${1:-Release}"
IOS_DIR="$(cd "$(dirname "$0")/../ios" && pwd)"
PLIST="$IOS_DIR/Runner/GoogleService-Info.plist"
ENTITLEMENTS="$IOS_DIR/Runner/Runner.entitlements"

problemes=0
signaler() {
  printf '  ✗ %s\n' "$1"
  problemes=$((problemes + 1))
}
valider() { printf '  ✓ %s\n' "$1"; }

printf '\nChaîne du push iOS — configuration %s\n\n' "$CONFIG"

# 1. Identifiant de bundle DE CETTE CONFIGURATION.
#
#    Les trois configurations divergent volontairement : Debug et Profile
#    restent sur « …app.dev » pour rester signables sous l'équipe personnelle,
#    Release porte l'identifiant définitif. Lire la première ligne venue
#    rendrait donc un verdict sur la mauvaise configuration — un contrôle qui
#    ment coûte plus cher que pas de contrôle du tout.
#
#    On interroge `xcodebuild` plutôt que de lire le pbxproj : le fichier
#    contient les configurations du PROJET puis celles de la CIBLE, et une
#    lecture naïve répondait sur les premières — donc sur la mauvaise. Xcode
#    résout aussi les xcconfig hérités, ce qu'aucune lecture de texte ne fait.
reglages=$(cd "$IOS_DIR" && xcodebuild -project Runner.xcodeproj -target Runner \
  -configuration "$CONFIG" -showBuildSettings 2>/dev/null)

lire() { printf '%s\n' "$reglages" | awk -v cle=" $1 =" 'index($0, cle){print $3; exit}'; }

bundle=$(lire PRODUCT_BUNDLE_IDENTIFIER)

if [ -z "$bundle" ]; then
  signaler "identifiant de bundle introuvable pour la configuration $CONFIG"
  printf '      xcodebuild n'"'"'a rien rendu : configuration inconnue, ou Xcode absent ?\n'
else
  valider "bundle en $CONFIG : $bundle"
fi

# Seule Release livre aux utilisateurs. Debug et Profile tournent sous l'équipe
# personnelle, qui n'a pas droit au push : les écarts y sont attendus, et les
# signaler comme des fautes apprendrait à ignorer ce script.
livraison=false
attendu_aps="development"
if [ "$CONFIG" = "Release" ]; then
  livraison=true
  attendu_aps="production"
fi

# 2. Le bundle DOIT être celui du plist Firebase, sinon le SDK s'initialise pour
#    une autre application et aucun jeton n'est jamais émis.
plist_bundle=$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$PLIST" 2>/dev/null)
if [ "$plist_bundle" = "$bundle" ]; then
  valider "GoogleService-Info.plist concorde"
elif [ "$livraison" = true ]; then
  signaler "GoogleService-Info.plist déclare « $plist_bundle » — la livraison construit « $bundle »"
  printf '      Firebase s'"'"'initialise alors pour une autre application : aucun jeton FCM.\n'
else
  printf '  · GoogleService-Info.plist vise « %s » : normal en %s, le push y est muet\n' \
    "$plist_bundle" "$CONFIG"
fi

# 3. Release doit référencer le fichier d'entitlements. Sans lui, iOS ne délivre
#    aucun jeton APNs — et rien ne le signale. Seule Release le référence : un
#    `grep` sur le pbxproj répondrait donc « oui » pour les trois.
if [ -n "$(lire CODE_SIGN_ENTITLEMENTS)" ]; then
  valider "Runner.entitlements est référencé"
elif [ "$livraison" = true ]; then
  signaler "aucune configuration ne référence Runner.entitlements"
  printf '      L'"'"'archive s'"'"'installera et ne recevra jamais de notification.\n'
else
  printf '  · entitlements non rattachés : normal en %s (équipe personnelle)\n' "$CONFIG"
fi

# 4. `aps-environment` doit correspondre à la signature : `development` pour un
#    build signé en développement, `production` pour une archive TestFlight.
#    Ne se contrôle que là où le fichier est effectivement rattaché — ailleurs,
#    sa valeur n'a aucun effet et juger dessus serait un faux verdict.
aps=$(/usr/libexec/PlistBuddy -c 'Print :aps-environment' "$ENTITLEMENTS" 2>/dev/null)
if [ -z "$(lire CODE_SIGN_ENTITLEMENTS)" ]; then
  printf '  · aps-environment (« %s ») sans effet en %s : fichier non rattaché\n' "$aps" "$CONFIG"
elif [ "$aps" != "$attendu_aps" ]; then
  signaler "aps-environment vaut « $aps », attendu « $attendu_aps » pour $CONFIG"
  printf '      Se tromper ne casse pas le build : ça donne une app muette.\n'
else
  valider "aps-environment : $aps"
fi

printf '\n'
if [ "$problemes" -gt 0 ]; then
  printf '%s point(s) à corriger avant de livrer — voir RESTANT.md § 1.4\n\n' "$problemes"
  exit 1
fi
printf 'Chaîne cohérente côté projet.\n'
printf 'Reste à vérifier hors du poste : App ID avec la capacité Push, et clé APNs déposée dans Firebase.\n\n'
