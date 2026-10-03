# app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Livraison iOS vers App Store Connect

Le script `tool/release_ios.sh` vérifie la configuration iOS, construit l'IPA
Release avec `ios/ExportOptions.plist`, détecte automatiquement le fichier
généré puis l'envoie vers App Store Connect.

```bash
export APPLE_ID="votre-adresse@exemple.com"
read -s APPLE_APP_SPECIFIC_PASSWORD
export APPLE_APP_SPECIFIC_PASSWORD

./tool/release_ios.sh
```

Le mot de passe spécifique reste dans une variable locale et n'est jamais
écrit dans le projet ou ajouté au dépôt Git.

Il est aussi possible de tout lancer en une seule commande locale :

```bash
APPLE_ID="votre-adresse@exemple.com" \
APPLE_APP_SPECIFIC_PASSWORD="votre-mot-de-passe-spécifique" \
./tool/release_ios.sh
```

Pour construire sans envoyer :

```bash
./tool/release_ios.sh --build-only
```

Pour imposer une version et un numéro de build sans modifier `pubspec.yaml` :

```bash
./tool/release_ios.sh --build-name 1.1.0 --build-number 24
```
