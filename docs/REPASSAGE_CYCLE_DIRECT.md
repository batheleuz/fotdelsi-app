# Repassage au comptoir et présentation des tailles

## Cause

Le parcours de vente directe utilisait `needsWasher ? washer : dryer` pour toutes les formules. Une formule de repassage ou pliage sans lavage ni séchage était donc proposée sur les sécheuses ; le parc de sécheuses ne donnait que le choix de 20 kg. Ce parcours exigeait également une machine et un jeton de session au moment du paiement.

## Correction

- Une formule comprenant du lavage ou du séchage conserve le choix d'une machine compatible.
- Toute formule sans lavage ni séchage propose les tailles de lots 12, 15 et 20 kg disposant d'un tarif dans le catalogue, indépendamment des machines.
- La vente au comptoir transmet `sizeKg`, sans `machineId` ni durée de séchage. Le paiement reste attribué à l'agent avec `atCounter: true`.
- Le paiement manuel est suivi via son identifiant, sans jeton de cycle. Après confirmation, l'agent voit la prise en charge au comptoir et le bouton **Terminer**.
- Le QR de paiement au comptoir reste disponible : il sert au client à régler la prestation, sans désigner une machine.
- Les cartes de tailles sont communes à l'agent et au client : capacité, prix, bordure de sélection et témoin visuel. Le client sélectionne sa taille puis appuie sur **Continuer** avant le paiement.
- Les changements de formule effacent les choix incompatibles. Le repassage seul ne reçoit pas l'option de séchage au soleil réservée aux formules comprenant du lavage.

Le backend actuel accepte déjà ces ventes manuelles et crée leur dépôt après confirmation. Cette correction nécessite une nouvelle version de l'application Flutter ; elle ne nécessite pas de modification du backend ou du dashboard.

## Validation

Le 7 octobre 2026 : les **243 tests Flutter passent**, `flutter analyze --no-pub` ne signale aucun problème et `flutter build bundle --debug --no-pub` réussit. La compilation native Android/iOS et la publication d'une nouvelle version restent à effectuer.

Les tests couvrent les trois tailles, les formules repassage/pliage, les achats multiples, le suivi automatique et la vérification du paiement, l'absence de démarrage machine, le changement de formule, les prix et les parcours lavage/séchage existants. Les écrans ont été rendus avec le thème et les polices du projet, à 320 et 390 pixels de largeur.

Deux cas ajoutés par les dépendances déjà présentes dans le projet ont également été pris en charge pour rétablir la compilation : `DioExceptionType.transformTimeout` et `AuthorizationStatus.deniedPermanently`.
