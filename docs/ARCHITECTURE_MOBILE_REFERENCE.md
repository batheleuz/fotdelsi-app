# Architecture mobile Flutter de référence

> Document d'architecture basé sur l'application FOT DELSI existante, puis renforcé pour servir de fondation à une application mobile plus grande, plus durable et plus facile à faire évoluer.

## Sommaire

1. [Objectif du document](#1-objectif-du-document)
2. [Résumé exécutif](#2-résumé-exécutif)
3. [Architecture actuelle de FOT DELSI](#3-architecture-actuelle-de-fot-delsi)
4. [Architecture cible recommandée](#4-architecture-cible-recommandée)
5. [Organisation complète des dossiers](#5-organisation-complète-des-dossiers)
6. [Règles de dépendances](#6-règles-de-dépendances)
7. [Démarrage et cycle de vie de l'application](#7-démarrage-et-cycle-de-vie-de-lapplication)
8. [Configuration et environnements](#8-configuration-et-environnements)
9. [Injection des dépendances](#9-injection-des-dépendances)
10. [Navigation et router](#10-navigation-et-router)
11. [Gestion d'état](#11-gestion-détat)
12. [Couche réseau REST](#12-couche-réseau-rest)
13. [Authentification et sessions](#13-authentification-et-sessions)
14. [Connectivité et mode hors ligne](#14-connectivité-et-mode-hors-ligne)
15. [WebSocket et temps réel](#15-websocket-et-temps-réel)
16. [Notifications push](#16-notifications-push)
17. [Deep links et liens universels](#17-deep-links-et-liens-universels)
18. [Persistance locale et cache](#18-persistance-locale-et-cache)
19. [Organisation d'une feature](#19-organisation-dune-feature)
20. [Design system et thème](#20-design-system-et-thème)
21. [Animations et mouvement](#21-animations-et-mouvement)
22. [Widgets réutilisables](#22-widgets-réutilisables)
23. [Fonctions utilitaires](#23-fonctions-utilitaires)
24. [Gestion des erreurs](#24-gestion-des-erreurs)
25. [Observabilité, logs et diagnostic](#25-observabilité-logs-et-diagnostic)
26. [Sécurité](#26-sécurité)
27. [Performance](#27-performance)
28. [Accessibilité et internationalisation](#28-accessibilité-et-internationalisation)
29. [Stratégie de tests](#29-stratégie-de-tests)
30. [Qualité, CI/CD et livraison](#30-qualité-cicd-et-livraison)
31. [Conventions de développement](#31-conventions-de-développement)
32. [Modèle complet d'une nouvelle feature](#32-modèle-complet-dune-nouvelle-feature)
33. [Décisions à conserver et améliorations prioritaires](#33-décisions-à-conserver-et-améliorations-prioritaires)
34. [Checklist de démarrage du prochain projet](#34-checklist-de-démarrage-du-prochain-projet)

---

## 1. Objectif du document

Ce document poursuit trois objectifs :

1. décrire précisément la manière dont l'application Flutter FOT DELSI est structurée aujourd'hui ;
2. identifier ce qui fonctionne bien, ce qui présente une limite et ce qui doit être renforcé ;
3. fournir une architecture directement réutilisable pour une application plus grande, sans recopier les défauts ou les compromis liés à la taille actuelle du projet.

Ce n'est pas seulement une arborescence de dossiers. L'architecture couvre :

- la séparation des responsabilités ;
- les règles de dépendances ;
- le démarrage de l'application ;
- la configuration des environnements ;
- le réseau, l'authentification et les erreurs ;
- la connectivité, le cache et le hors-ligne ;
- le temps réel par WebSocket ;
- les notifications push et les deep links ;
- l'injection des dépendances ;
- la navigation ;
- la gestion d'état ;
- le design system, les animations et les composants partagés ;
- les tests, la sécurité, l'observabilité et la livraison.

Le terme **architecture actuelle** désigne ce qui existe réellement dans FOT DELSI. Le terme **architecture cible** désigne la version recommandée pour le prochain projet.

---

## 2. Résumé exécutif

FOT DELSI utilise déjà une base saine :

- organisation par feature ;
- séparation `data`, `domain` et `presentation` ;
- BLoC/Cubit pour l'état ;
- GetIt pour l'injection ;
- Dio pour REST ;
- une connexion Socket.IO partagée ;
- GoRouter pour la navigation ;
- Firebase Messaging abstrait derrière une interface ;
- stockage sécurisé des sessions ;
- thème, espacements, rayons et mouvements centralisés ;
- tests de logique, d'intercepteur réseau et de widgets.

Pour une application plus grande, il faut conserver ces principes mais renforcer plusieurs points :

- remplacer le service locator monolithique par des modules d'injection par feature ;
- générer les modèles JSON immuables et fortement typés ;
- séparer les clients HTTP public, authentifié et upload ;
- ajouter une configuration typée par environnement et par flavor ;
- formaliser les politiques de cache, de retry et d'idempotence ;
- rendre le WebSocket authentifié, observable et capable de resynchroniser après reconnexion ;
- introduire une couche d'observabilité structurée avec corrélation REST/WebSocket/push ;
- découper les routes par feature et utiliser des routes typées ;
- ajouter une vraie stratégie d'internationalisation et d'accessibilité ;
- imposer des règles de dépendances et des lints plus stricts dans la CI ;
- organiser les tests selon une pyramide claire ;
- prévoir dès le début les migrations de stockage, les feature flags et les mécanismes de rollback.

Architecture cible résumée :

```text
UI
  ↓ événements utilisateur
Presentation (Page + Bloc/Cubit/ViewModel)
  ↓ cas d'usage
Domain (Use cases + Entities + Repository ports)
  ↓ contrats
Data (Repository implementations + DTO + mappers)
  ↓
Infrastructure (HTTP, WebSocket, DB, secure storage, push, analytics)
```

Le domaine reste indépendant de Flutter, de Dio, de Firebase, du stockage et des formats JSON.

---

## 3. Architecture actuelle de FOT DELSI

### 3.1 Point d'entrée

Le démarrage de production se trouve dans `lib/main.dart` :

1. initialisation du binding Flutter ;
2. initialisation de Firebase ;
3. configuration de GetIt avec `setupLocator()` ;
4. récupération du `AuthCubit` global ;
5. création du `GoRouter` dépendant de l'état d'authentification ;
6. initialisation du service de notifications push ;
7. lancement de `FotDelsiApp`.

Un deuxième point d'entrée, `lib/main_showcase.dart`, permet de lancer la vraie application avec un adaptateur HTTP simulé, un push neutre et des données fictives. C'est une excellente couture de test et de démonstration : l'interface, les Cubits, le mapping et les repositories de production continuent de fonctionner.

### 3.2 Composition racine

`lib/app.dart` assemble les services globaux :

- `AuthCubit` ;
- `ClientSessionCubit` ;
- `ServiceStatusCubit` ;
- `WsConnectionCubit` ;
- `ConnectivityCubit` ;
- `WashSessionCubit`.

La racine gère également :

- le cycle de vie Flutter avec `WidgetsBindingObserver` ;
- le rafraîchissement du statut des services au retour au premier plan ;
- la nouvelle tentative d'enregistrement FCM ;
- le service de deep links ;
- le `ScaffoldMessenger` global ;
- le bandeau global hors ligne ;
- le `MaterialApp.router` et le thème.

### 3.3 Core transversal

Le dossier `lib/core` contient les mécanismes partagés :

```text
core/
├── auth/          stockage et coordination des sessions
├── connectivity/  état réseau et bandeau hors ligne
├── constants/     icônes et chemins d'assets
├── deeplink/      liens entrants et retour de paiement
├── di/            composition GetIt
├── motion/        règles et composants d'animation
├── network/       Dio, endpoints, erreurs et intercepteurs
├── onboarding/    persistance du statut d'onboarding
├── push/          abstraction et implémentation FCM
├── router/        routes, redirections et construction du router
├── showcase/      environnement simulé pour captures
├── theme/         couleurs, typo, espacements, rayons, durées
├── utils/         formatage et normalisation purs
├── websocket/     connexion Socket.IO partagée
└── widgets/       composants réellement transversaux
```

### 3.4 Features actuelles

Les fonctionnalités principales sont isolées dans `lib/features` :

```text
features/
├── auth/
├── catalog/
├── client_auth/
├── counter_sale/
├── dropoffs/
├── machines/
├── notifications/
├── onboarding/
├── payment/
├── service_status/
├── splash/
└── wash_session/
```

La majorité suit cette structure :

```text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   └── repositories/
└── presentation/
    ├── bloc/ ou cubit/
    ├── pages/
    ├── widgets/
    └── utils/
```

### 3.5 Flux réel d'une donnée machine

Exemple `machines` :

1. `MachineApiDataSource` appelle `GET /machines` avec Dio ;
2. la réponse JSON est convertie en `MachineModel` ;
3. `MachineRepositoryImpl` convertit le DTO en entité `Machine` ;
4. le repository transforme les exceptions en `Failure` ;
5. `MachinesBloc` charge l'état REST initial ;
6. `MachineSocketDataSource` écoute `machine.state` ;
7. les mises à jour WebSocket sont fusionnées par identifiant ;
8. l'UI observe `MachinesState`.

Ce flux illustre correctement la séparation transport → mapping → métier → présentation.

### 3.6 Forces actuelles

- Le domaine ne dépend pas de Dio ou de Flutter dans les features les mieux structurées.
- Les sources REST et WebSocket sont séparées.
- Une seule connexion Socket.IO est partagée par référence.
- Les tokens sont préchargés en mémoire pour éviter les blocages du Keychain iOS.
- Le refresh token est sérialisé afin que plusieurs réponses 401 ne déclenchent qu'un refresh.
- Les écritures HTTP ne sont pas réessayées arbitrairement.
- Les animations respectent `MediaQuery.disableAnimations`.
- Les notifications sont abstraites derrière `PushMessaging`.
- Le mode showcase remplace l'infrastructure plutôt que l'UI.
- Plusieurs bugs métier sensibles possèdent un test de non-régression ciblé.

### 3.7 Limites actuelles à ne pas recopier

- `service_locator.dart` connaît toutes les features et grossira rapidement.
- `ApiEndpoints` centralise tous les endpoints dans un seul fichier.
- `ApiResponse` et plusieurs parsings utilisent encore `dynamic` et des casts manuels.
- Quelques features ne suivent pas entièrement la même séparation en couches.
- Les use cases ne sont pas matérialisés : certains Cubits appellent directement les repositories.
- Les logs reposent encore en partie sur `debugPrint` ou `print`.
- Le client WebSocket transporte des payloads bruts `dynamic`.
- `connectivity_plus` détecte une interface réseau, pas la disponibilité réelle du backend.
- Le router central contient de nombreuses routes et casts de `state.extra`.
- Les lints restent proches des valeurs Flutter par défaut.
- Les tests sont tous à la racine de `test/`, ce qui deviendra difficile à parcourir.
- Le thème global est encore minimal : plusieurs styles restent codés dans les widgets.

---

## 4. Architecture cible recommandée

### 4.1 Style architectural

Utiliser une **Clean Architecture pragmatique organisée par feature**.

Pragmatique signifie :

- ne pas créer une classe vide pour chaque opération triviale ;
- créer un use case dès qu'une règle métier, une orchestration ou plusieurs dépendances sont impliquées ;
- éviter que les pages contiennent de la logique métier ;
- éviter que les repositories connaissent Flutter ;
- privilégier la lisibilité à la pureté théorique.

### 4.2 Couches

#### Presentation

Contient :

- pages et écrans ;
- widgets spécifiques à la feature ;
- BLoC/Cubit et états ;
- modèles de présentation ;
- formatage exclusivement visuel ;
- coordination de navigation propre à l'écran.

Ne contient pas :

- appels Dio ;
- lecture directe du secure storage ;
- parsing JSON ;
- règles métier tarifaires ;
- noms d'événements WebSocket ;
- connaissance de Firebase.

#### Domain

Contient :

- entités métier ;
- value objects ;
- use cases ;
- contrats de repositories ;
- erreurs métier ;
- politiques métier pures.

Le domaine ne doit importer ni Flutter, ni Dio, ni Firebase, ni une base locale.

#### Data

Contient :

- DTO réseau et stockage ;
- mappers DTO ↔ domaine ;
- implémentations des repositories ;
- sources de données distantes et locales ;
- stratégies de cache propres à la feature.

#### Infrastructure

Contient les mécanismes génériques :

- clients HTTP ;
- WebSocket ;
- base locale ;
- secure storage ;
- Firebase ;
- système de fichiers ;
- analytics ;
- crash reporting ;
- logger ;
- horloge système ;
- génération d'identifiants.

Dans un projet simple, cette couche peut rester dans `core`. Dans un grand projet, il est plus clair de l'appeler explicitement `infrastructure`.

### 4.3 Sens des dépendances

```text
presentation ───────→ domain
data ───────────────→ domain
infrastructure ─────→ interfaces core/domain
app/bootstrap ──────→ toutes les implémentations pour les assembler

domain ─X→ presentation
domain ─X→ data
domain ─X→ infrastructure
feature A ─X→ internals de feature B
```

Quand une feature a besoin d'une capacité d'une autre, elle dépend d'un contrat public, d'un use case partagé ou d'un événement métier, jamais d'un fichier interne arbitraire.

---

## 5. Organisation complète des dossiers

Arborescence cible recommandée :

```text
lib/
├── main.dart
├── main_dev.dart
├── main_staging.dart
├── main_prod.dart
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   ├── app_lifecycle_observer.dart
│   └── app_bloc_observer.dart
├── config/
│   ├── app_config.dart
│   ├── app_environment.dart
│   ├── build_info.dart
│   ├── feature_flags.dart
│   └── flavors/
│       ├── dev_config.dart
│       ├── staging_config.dart
│       └── prod_config.dart
├── core/
│   ├── analytics/
│   ├── auth/
│   ├── cache/
│   ├── clock/
│   ├── connectivity/
│   ├── database/
│   ├── deeplink/
│   ├── errors/
│   ├── extensions/
│   ├── logging/
│   ├── network/
│   ├── permissions/
│   ├── push/
│   ├── realtime/
│   ├── result/
│   ├── security/
│   ├── storage/
│   ├── telemetry/
│   └── utils/
├── design_system/
│   ├── assets/
│   ├── components/
│   ├── foundations/
│   │   ├── colors.dart
│   │   ├── motion.dart
│   │   ├── radius.dart
│   │   ├── shadows.dart
│   │   ├── spacing.dart
│   │   └── typography.dart
│   ├── icons/
│   ├── theme/
│   └── tokens/
├── navigation/
│   ├── app_router.dart
│   ├── app_routes.dart
│   ├── guards/
│   ├── observers/
│   └── transitions/
├── di/
│   ├── injector.dart
│   ├── core_module.dart
│   ├── infrastructure_module.dart
│   └── test_overrides.dart
├── features/
│   ├── authentication/
│   ├── home/
│   ├── notifications/
│   └── ...
├── l10n/
│   ├── app_fr.arb
│   ├── app_en.arb
│   └── l10n.dart
└── generated/

test/
├── core/
├── design_system/
├── features/
│   └── feature_name/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── helpers/
├── fixtures/
└── golden/

integration_test/
├── authentication_flow_test.dart
├── critical_payment_flow_test.dart
└── helpers/

tool/
├── ci/
├── release/
├── codegen/
└── checks/
```

### 5.1 Pourquoi séparer `design_system` de `core`

Le design system a un rôle visuel et peut être extrait plus tard dans un package interne. `core` contient les capacités techniques. Cette séparation évite de transformer `core` en dossier fourre-tout.

### 5.2 Pourquoi une feature reste autonome

Une feature doit pouvoir être comprise sans explorer tout le projet. Elle possède :

- son contrat métier ;
- ses modèles ;
- ses sources de données ;
- sa gestion d'état ;
- ses pages ;
- ses tests ;
- son module d'injection ;
- son module de routes si elle expose plusieurs écrans.

---

## 6. Règles de dépendances

### 6.1 Règles obligatoires

1. Une page ne dépend jamais de Dio.
2. Un Cubit ne parse jamais de JSON.
3. Une entité domaine n'importe jamais Flutter.
4. Un repository domaine est une interface.
5. Son implémentation vit dans `data/repositories`.
6. Un data source lève des erreurs techniques typées ; le repository les convertit.
7. Un widget partagé ne doit pas dépendre d'une feature métier.
8. Une feature ne lit pas directement le secure storage d'une autre feature.
9. La navigation inter-feature passe par des routes publiques.
10. Les constantes métier vivent dans le domaine ou dans la configuration serveur, pas dans l'UI.

### 6.2 API publique d'une feature

Pour les grandes applications, ajouter un fichier public explicite :

```text
features/orders/orders.dart
```

Il exporte uniquement ce que les autres features peuvent utiliser :

```dart
export 'domain/entities/order_summary.dart';
export 'domain/usecases/watch_active_orders.dart';
export 'presentation/routes/order_routes.dart';
```

Les imports vers `features/orders/data/...` depuis une autre feature sont interdits.

### 6.3 Contrôle automatique

Ajouter dans la CI un contrôle d'architecture :

- lints d'import ;
- script vérifiant les dépendances interdites ;
- éventuellement `dependency_validator` ou un outil interne ;
- conventions contrôlées dans les revues de code.

---

## 7. Démarrage et cycle de vie de l'application

### 7.1 Pipeline de démarrage cible

Le `main` doit rester très court :

```dart
Future<void> main() async {
  await bootstrap(environment: AppEnvironment.production);
}
```

Le bootstrap orchestre :

1. `WidgetsFlutterBinding.ensureInitialized()` ;
2. zone d'erreur globale avec `runZonedGuarded` ;
3. configuration de `FlutterError.onError` ;
4. chargement de la configuration ;
5. initialisation du logger ;
6. initialisation des SDK obligatoires ;
7. ouverture de la base locale ;
8. préchargement minimal de session ;
9. composition de l'injection ;
10. construction du router ;
11. lancement de l'application ;
12. initialisations non bloquantes après le premier frame.

### 7.2 Initialisation critique et différée

Ne pas bloquer le splash pour tout initialiser.

**Critique avant `runApp` :**

- environnement ;
- stockage indispensable à la session ;
- DI minimale ;
- handler d'erreurs ;
- Firebase si son absence empêche réellement le démarrage.

**Différable après le premier frame :**

- analytics ;
- remote config ;
- enregistrement push ;
- préchauffage de cache ;
- synchronisation non essentielle.

### 7.3 Orchestrateur de cycle de vie

Pour une grande application, remplacer les appels dispersés par un `AppLifecycleCoordinator` qui notifie des participants :

```dart
abstract interface class AppLifecycleParticipant {
  Future<void> onResumed();
  Future<void> onPaused();
}
```

Le push, le WebSocket, la session, le cache et la connectivité peuvent alors réagir sans être directement connus de `App`.

---

## 8. Configuration et environnements

### 8.1 Ne pas limiter la configuration à `String.fromEnvironment`

FOT DELSI centralise déjà les URL avec `--dart-define`. Pour le prochain projet, créer un objet immuable :

```dart
final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.webSocketUrl,
    required this.enableHttpLogs,
    required this.sentryDsn,
  });
}
```

### 8.2 Environnements recommandés

- `dev` : backend de développement, logs verbeux, données réinitialisables ;
- `staging` : miroir de production, services externes de test ;
- `prod` : logs restreints, sécurité et télémétrie activées.

Chaque environnement doit avoir :

- un bundle ID/application ID distinct ;
- un projet Firebase distinct ;
- ses propres URL ;
- ses propres clés publiques ;
- ses propres deep links ;
- une icône ou un suffixe visuel en dev/staging.

### 8.3 Secrets

Ne jamais embarquer de secret serveur dans l'application. Tout ce qui est dans l'IPA ou l'APK peut être extrait.

Peuvent être embarqués :

- identifiants publics Firebase ;
- DSN public de télémétrie ;
- clés publiques ;
- flags non sensibles.

Doivent rester côté serveur ou dans la CI :

- secret d'API ;
- mot de passe ;
- clé privée ;
- credentials de signature ;
- mot de passe App Store Connect.

### 8.4 Feature flags

Créer une interface :

```dart
abstract interface class FeatureFlags {
  bool isEnabled(FeatureFlag flag);
  Stream<bool> watch(FeatureFlag flag);
}
```

Les flags permettent :

- activation progressive ;
- rollback fonctionnel sans publier une nouvelle version ;
- expérimentation ;
- désactivation d'une intégration externe défaillante.

Un flag ne doit pas remplacer une règle métier permanente.

---

## 9. Injection des dépendances

### 9.1 Ce que fait FOT DELSI

FOT DELSI utilise GetIt avec :

- singletons paresseux pour l'infrastructure et les repositories ;
- factories pour les Cubits propres aux écrans ;
- singletons pour les états réellement globaux ;
- overrides explicites pour le showcase et les tests.

Le choix est cohérent. La limite est que toutes les inscriptions se trouvent dans un seul fichier.

### 9.2 Architecture DI cible

Chaque feature expose son module :

```dart
abstract final class OrdersModule {
  static void register(GetIt getIt) {
    getIt
      ..registerLazySingleton<OrdersApi>(
        () => OrdersApi(getIt<AuthenticatedHttpClient>()),
      )
      ..registerLazySingleton<OrderRepository>(
        () => OrderRepositoryImpl(getIt(), getIt()),
      )
      ..registerFactory(() => OrdersCubit(getIt()));
  }
}
```

L'injecteur racine ne fait qu'appeler les modules :

```dart
void configureDependencies(AppConfig config) {
  CoreModule.register(getIt, config);
  AuthenticationModule.register(getIt);
  OrdersModule.register(getIt);
  PaymentsModule.register(getIt);
}
```

### 9.3 Durées de vie

**Singleton :**

- configuration ;
- logger ;
- clients HTTP ;
- base locale ;
- secure storage ;
- socket partagée ;
- repository sans état de présentation ;
- coordinateur de session.

**Factory :**

- Cubit/BLoC d'un écran ;
- use case léger si sa construction n'est pas coûteuse ;
- contrôleur de formulaire.

**Scoped :**

- dépendances liées à une session utilisateur ;
- panier, assistant multi-étapes ou workflow temporaire ;
- navigation imbriquée d'un espace authentifié.

### 9.4 Règle importante

Éviter d'appeler directement `getIt<T>()` dans les widgets profonds. Injecter les dépendances au niveau de la route ou du `BlocProvider`. Cela rend l'arbre testable et montre explicitement ce dont l'écran dépend.

### 9.5 Code generation ou manuel

Deux options valides :

- **GetIt manuel modulaire** : plus explicite, moins de magie, adapté à l'équipe actuelle ;
- **GetIt + injectable** : réduit le boilerplate, intéressant lorsque les dépendances deviennent très nombreuses.

Ne pas changer d'outil uniquement pour suivre une mode. La modularité et les scopes sont plus importants que la bibliothèque.

---

## 10. Navigation et router

### 10.1 État actuel

GoRouter gère :

- les routes client et agent ;
- les redirections selon `AuthCubit` ;
- l'onboarding ;
- les paramètres dynamiques ;
- certains arguments via `state.extra` ;
- les routes vers paiements, cycles et dépôts.

### 10.2 Architecture cible

Découper les routes :

```text
navigation/
├── app_router.dart
├── guards/
│   ├── auth_guard.dart
│   ├── onboarding_guard.dart
│   └── role_guard.dart
└── observers/

features/orders/presentation/routes/
├── order_routes.dart
└── order_route_data.dart
```

### 10.3 Routes typées

Préférer `go_router_builder` ou des classes `GoRouteData` afin d'éviter :

- les chaînes dupliquées ;
- les casts fragiles de `state.extra` ;
- les erreurs de paramètre au runtime ;
- les changements de route non détectés par le compilateur.

### 10.4 Shells

Pour une grande app à navigation principale persistante :

- `StatefulShellRoute` pour les onglets ;
- un `NavigatorKey` par branche ;
- conservation indépendante de la pile de chaque onglet ;
- routes modales au-dessus du shell.

### 10.5 Guards et permissions

Les redirections doivent reposer sur un état de session explicite :

```text
unknown → splash
anonymous → espace public/login
authenticated + onboarding incomplet → onboarding
authenticated + rôle insuffisant → forbidden/home autorisé
authenticated + session expirée → login avec intention de retour
```

Un guard doit être pur et déterministe. Il ne doit pas déclencher directement un appel réseau.

### 10.6 Navigation depuis push et deep link

Tous les liens entrants doivent être convertis en une intention typée :

```dart
sealed class NavigationIntent {}
final class OpenOrderIntent extends NavigationIntent { ... }
final class OpenPaymentIntent extends NavigationIntent { ... }
```

Un `NavigationIntentCoordinator` attend si nécessaire :

- que le router soit prêt ;
- que la session soit restaurée ;
- que l'utilisateur soit authentifié ;
- que les données minimales soient chargées.

Cela évite de perdre un tap sur notification au lancement à froid.

### 10.7 Page d'erreur

Configurer une `errorBuilder` ou `onException` avec :

- une page 404 lisible ;
- un bouton retour accueil ;
- un identifiant de diagnostic ;
- aucun détail technique sensible.

---

## 11. Gestion d'état

### 11.1 Choix recommandé

Conserver BLoC/Cubit : l'application actuelle l'utilise correctement et l'équipe dispose déjà de tests et de conventions.

### 11.2 Quand utiliser Cubit

Cubit convient pour :

- chargement d'une page ;
- formulaire ;
- état simple avec quelques actions ;
- orchestration séquentielle ;
- pagination simple.

### 11.3 Quand utiliser BLoC

BLoC convient pour :

- événements concurrents ;
- flux temps réel ;
- debounce/restartable/droppable ;
- workflows où l'origine de l'événement est importante ;
- machines d'état explicites.

### 11.4 Forme des états

Éviter un unique état rempli de champs nullable ambigus. Préférer des états scellés ou un état immuable avec statut explicite :

```dart
sealed class OrdersState {
  const OrdersState();
}

final class OrdersInitial extends OrdersState {}
final class OrdersLoading extends OrdersState {}
final class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders, {this.isRefreshing = false});
  final List<Order> orders;
  final bool isRefreshing;
}
final class OrdersFailure extends OrdersState {
  const OrdersFailure(this.failure);
  final Failure failure;
}
```

### 11.5 Effets ponctuels

Les SnackBars, navigations et dialogues ne doivent pas être des booléens persistants dans l'état. Options :

- état avec identifiant d'effet consommable ;
- `BlocListener` sur transition précise ;
- flux séparé d'effets UI ;
- retour de méthode uniquement pour une action locale très simple.

### 11.6 État global

Limiter l'état global à ce qui est réellement transversal :

- session ;
- configuration distante ;
- thème/langue ;
- connectivité ;
- état de synchronisation ;
- compteur global de notifications si nécessaire.

Les états d'écran doivent être détruits avec leur route.

### 11.7 Concurrence

Pour chaque événement réseau, définir volontairement sa politique :

- `restartable` pour une recherche ;
- `droppable` pour un bouton déjà en traitement ;
- `sequential` pour une file d'actions ;
- concurrent uniquement si l'ordre n'a aucune importance.

---

## 12. Couche réseau REST

### 12.1 Composition recommandée

```text
core/network/
├── clients/
│   ├── public_api_client.dart
│   ├── authenticated_api_client.dart
│   └── upload_api_client.dart
├── interceptors/
│   ├── auth_interceptor.dart
│   ├── correlation_interceptor.dart
│   ├── locale_interceptor.dart
│   ├── retry_interceptor.dart
│   ├── telemetry_interceptor.dart
│   └── redacting_log_interceptor.dart
├── policies/
│   ├── retry_policy.dart
│   ├── timeout_policy.dart
│   └── cache_policy.dart
├── models/
│   ├── api_envelope.dart
│   ├── api_error_dto.dart
│   └── page_dto.dart
└── network_info.dart
```

### 12.2 Plusieurs clients plutôt qu'un client universel

Utiliser au minimum :

- client public sans token ;
- client authentifié avec refresh ;
- client upload avec timeouts adaptés et progression ;
- éventuellement client isolé pour refresh afin d'éviter la récursion.

### 12.3 Ordre des intercepteurs

Ordre recommandé :

1. métadonnées : request ID, version, plateforme, langue ;
2. authentification ;
3. idempotency key si applicable ;
4. télémétrie ;
5. retry contrôlé ;
6. logs redacted en développement.

Le comportement exact de Dio sur `onError` doit être testé, car l'ordre des intercepteurs influence refresh, retry et logs.

### 12.4 DTO générés

Pour la prochaine app, utiliser `freezed` + `json_serializable`, ou des classes générées équivalentes :

```dart
@freezed
class OrderDto with _$OrderDto {
  const factory OrderDto({
    required String id,
    required String status,
    required int totalAmount,
  }) = _OrderDto;

  factory OrderDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDtoFromJson(json);
}
```

Bénéfices :

- immutabilité ;
- parsing uniforme ;
- erreurs détectées plus tôt ;
- `copyWith`, égalité et unions générés ;
- réduction des casts `dynamic`.

### 12.5 Mappers explicites

Ne pas faire du DTO une entité métier :

```dart
extension OrderDtoMapper on OrderDto {
  Order toDomain() => Order(
    id: OrderId(id),
    status: OrderStatus.fromApi(status),
    total: Money.cfa(totalAmount),
  );
}
```

Les changements d'API restent ainsi confinés à `data`.

### 12.6 Timeouts

Définir par catégorie :

- lecture standard : courte ;
- action critique : raisonnable mais pas infinie ;
- upload : plus longue ;
- refresh de session : courte ;
- health check : très courte.

Un timeout ne signifie pas que le serveur n'a pas exécuté l'opération. Pour les paiements ou démarrages de machine, il faut ensuite vérifier l'état avec un identifiant idempotent.

### 12.7 Retry

Règles :

- GET : retry possible avec backoff et jitter ;
- PUT/DELETE : uniquement si l'API garantit l'idempotence ;
- POST : jamais automatiquement sans idempotency key ;
- 400/401/403/404 : pas de retry générique ;
- 408/429/5xx : selon politique ;
- réseau indisponible : attendre le retour de connectivité.

### 12.8 Idempotence

Pour chaque action sensible, générer côté mobile un identifiant stable :

```text
Idempotency-Key: uuid-de-la-tentative
X-Correlation-Id: uuid-du-parcours
```

Le backend doit conserver la clé et retourner le même résultat si l'action est répétée. C'est indispensable pour :

- paiement ;
- démarrage de machine ;
- création de commande ;
- validation d'un dépôt ;
- envoi d'un document.

### 12.9 Annulation

Utiliser `CancelToken` quand :

- une page est fermée ;
- une nouvelle recherche remplace l'ancienne ;
- l'utilisateur annule un upload ;
- une session est déconnectée.

### 12.10 Logs réseau

Ne jamais journaliser en clair :

- `Authorization` ;
- cookies ;
- refresh tokens ;
- mots de passe et OTP ;
- numéros complets ;
- données bancaires ;
- URLs de paiement contenant un token.

Créer un redactor central qui masque les clés sensibles récursivement.

---

## 13. Authentification et sessions

### 13.1 Modèle actuel utile

FOT DELSI sépare :

- session agent JWT avec access/refresh token ;
- session client opaque liée au téléphone.

L'intercepteur choisit le bon token, et le refresh agent est sérialisé. La mémoire est la source chaude et le secure storage assure la persistance.

### 13.2 Architecture cible

Créer un `SessionCoordinator` :

```dart
abstract interface class SessionCoordinator {
  Stream<SessionState> get states;
  SessionState get current;
  Future<void> restore();
  Future<String?> validAccessToken();
  Future<void> signOut(SignOutReason reason);
}
```

États possibles :

```text
unknown
anonymous
restoring
authenticated
refreshing
expired
locked
```

### 13.3 Refresh token

Le refresh doit :

- être mutualisé entre requêtes concurrentes ;
- utiliser un client HTTP isolé ;
- faire tourner access et refresh token ensemble ;
- conserver la session sur panne réseau ou 5xx ;
- déconnecter uniquement sur refus authentique 401/403 du refresh ;
- rejouer une seule fois la requête d'origine ;
- empêcher les boucles infinies ;
- produire un événement de télémétrie sans exposer le token.

### 13.4 Expiration proactive

Si le JWT contient une expiration :

- rafraîchir légèrement avant l'échéance ;
- tenir compte d'une marge d'horloge ;
- ne pas attendre le 401 au milieu d'une opération critique ;
- ne jamais considérer l'expiration lue côté client comme une preuve de sécurité.

### 13.5 Déconnexion

La déconnexion doit :

1. stopper ou réinitialiser les flux authentifiés ;
2. désenregistrer le device si l'API le prévoit ;
3. fermer les rooms WebSocket privées ;
4. supprimer tokens et données locales privées ;
5. réinitialiser les Cubits globaux ;
6. invalider la pile de navigation ;
7. conserver uniquement les préférences non sensibles.

### 13.6 Changement de mot de passe ou révocation

Le backend doit révoquer les sessions ou incrémenter une version de session. Le mobile ne peut pas garantir seul qu'un ancien token cesse de fonctionner. Le prochain projet doit prévoir :

- révocation serveur ;
- liste/session version ;
- événement push ou WebSocket de révocation si possible ;
- contrôle sur les appels suivants ;
- écran de reconnexion explicite.

---

## 14. Connectivité et mode hors ligne

### 14.1 Différence essentielle

`connectivity_plus` indique qu'une interface Wi-Fi/mobile existe. Il ne garantit pas :

- l'accès à Internet ;
- la résolution DNS ;
- la disponibilité du backend ;
- la validité du portail captif ;
- la disponibilité d'un service externe.

### 14.2 États cibles

Utiliser un état plus riche :

```dart
enum NetworkReachability {
  unknown,
  offline,
  internetAvailable,
  backendUnavailable,
  degraded,
}
```

### 14.3 Stratégie

Combiner :

- état des interfaces ;
- health check léger du backend ;
- résultat des derniers appels ;
- état WebSocket ;
- éventuel statut des services externes fourni par le backend.

### 14.4 UX hors ligne

- Conserver les données déjà chargées.
- Afficher un bandeau non bloquant.
- Montrer la fraîcheur des données si elle est importante.
- Désactiver clairement les actions impossibles.
- Ne pas remplacer systématiquement tout l'écran par une erreur.
- Relancer silencieusement les lectures au retour en ligne.

### 14.5 File d'actions hors ligne

N'introduire une file que pour des actions compatibles :

- favoris ;
- brouillons ;
- lecture/ack ;
- formulaires explicitement sauvegardés.

Éviter la file automatique pour :

- paiements ;
- commandes de machine ;
- actions dépendant d'une disponibilité instantanée ;
- opérations sans idempotence serveur.

### 14.6 Synchronisation

Chaque objet synchronisable doit porter :

- identifiant local stable ;
- version serveur ou `updatedAt` ;
- statut de synchronisation ;
- stratégie de conflit ;
- dernière erreur ;
- nombre de tentatives.

---

## 15. WebSocket et temps réel

### 15.1 Bonne décision actuelle

FOT DELSI possède une seule connexion Socket.IO partagée. Les features consomment des événements via leurs data sources. C'est préférable à une socket par écran.

### 15.2 Architecture cible

```text
RealtimeTransport
  ├── connect(session)
  ├── disconnect()
  ├── subscribe<T>(RealtimeTopic<T>)
  ├── emit<T>(RealtimeCommand<T>)
  └── connectionStates

FeatureRealtimeDataSource
  ├── mappe les payloads
  ├── rejoint les rooms métier
  ├── déduplique les événements
  └── expose des entités/DTO typés
```

### 15.3 Authentification socket

La socket doit envoyer l'identité à la connexion et se reconnecter quand la session change. Ne pas placer le token dans une URL loggable. Utiliser les options d'authentification du protocole Socket.IO ou un handshake sécurisé.

### 15.4 Cycle de vie

Définir clairement :

- connexion au premier besoin ou après authentification ;
- maintien en arrière-plan selon les contraintes OS ;
- déconnexion à la fin de session ;
- reconnexion avec backoff exponentiel et jitter ;
- resouscription aux rooms ;
- resynchronisation REST après reconnexion.

### 15.5 REST reste la source d'autorité

Le WebSocket notifie un changement mais ne garantit pas que tous les événements ont été reçus. Après reconnexion :

1. récupérer un snapshot REST ;
2. fusionner selon version/horodatage ;
3. reprendre le flux temps réel ;
4. ignorer les événements déjà appliqués.

### 15.6 Événements typés et versionnés

Éviter `Stream<dynamic>`. Définir une enveloppe :

```json
{
  "eventId": "uuid",
  "eventType": "machine.state.changed",
  "version": 2,
  "occurredAt": "2026-10-06T10:00:00Z",
  "entityId": "machine-1",
  "sequence": 1542,
  "correlationId": "uuid",
  "payload": {}
}
```

Cette enveloppe permet :

- déduplication ;
- ordre ;
- compatibilité ascendante ;
- diagnostic ;
- corrélation avec une commande REST.

### 15.7 Fusion d'état

Le comportement de `MachinesBloc` est une bonne règle : une mise à jour d'une machine ne doit pas remplacer toute la liste. Pour chaque flux, documenter :

- snapshot complet ou delta ;
- clé de fusion ;
- règle de suppression ;
- autorité de l'événement ;
- gestion des événements anciens.

### 15.8 Observabilité temps réel

Mesurer :

- durée de connexion ;
- nombre de reconnexions ;
- dernier événement reçu ;
- retard entre `occurredAt` et réception ;
- erreurs de parsing ;
- rooms actives ;
- séquence manquante ;
- taille des payloads.

---

## 16. Notifications push

### 16.1 Architecture actuelle

FOT DELSI sépare correctement :

- `PushMessaging` : port indépendant de Firebase ;
- `FirebasePushMessaging` : intégration FCM/APNs et notification locale ;
- `PushNotificationService` : permission, enregistrement du device, ack et navigation ;
- `NotificationPayload` : conversion des données FCM ;
- repository REST pour device token et acquittement.

### 16.2 Architecture cible

Séparer davantage les responsabilités :

```text
PushTransport              SDK FCM/APNs
DeviceRegistrationService token, rotation, identité
PushPayloadParser          validation et version du payload
NotificationCoordinator   décision métier
NavigationIntentQueue     navigation au bon moment
NotificationPreferences   préférences utilisateur
```

### 16.3 Cycle du token

Enregistrer le token :

- après permission ;
- après authentification ;
- après changement d'identité ;
- après rotation FCM ;
- au retour au premier plan si l'enregistrement précédent a échoué ;
- après réinstallation/restauration si nécessaire.

Le backend doit associer :

- token ;
- utilisateur ;
- plateforme ;
- version app ;
- locale ;
- environnement ;
- date de dernière confirmation.

### 16.4 Payload versionné

```json
{
  "schemaVersion": "2",
  "notificationId": "...",
  "kind": "ORDER_READY",
  "entityId": "...",
  "route": "/orders/...",
  "correlationId": "..."
}
```

Le mobile doit tolérer les kinds inconnus et ouvrir une destination sûre.

### 16.5 Premier plan, arrière-plan, app tuée

Tester séparément :

- message reçu au premier plan ;
- tap depuis arrière-plan ;
- tap lançant l'app à froid ;
- permission refusée ;
- token APNs retardé ;
- token FCM renouvelé ;
- utilisateur déconnecté ;
- notification d'un compte précédent.

### 16.6 Confidentialité

Le texte système d'une notification peut être visible sur écran verrouillé. Ne pas y inclure de donnée sensible. Utiliser un message générique et charger le détail après authentification.

---

## 17. Deep links et liens universels

### 17.1 État actuel

FOT DELSI utilise `app_links` et un schéma custom `fotdelsi://payment/...` pour les retours de paiement.

### 17.2 Recommandation

Supporter en priorité :

- Universal Links iOS ;
- Android App Links ;
- schéma custom uniquement comme repli.

Les liens HTTPS sont plus sûrs, ouvrables sur le web et vérifiables par domaine.

### 17.3 Parsing

Centraliser dans un parseur pur :

```dart
NavigationIntent? parseIncomingUri(Uri uri)
```

Le parseur :

- valide le host ;
- valide la version du lien ;
- rejette les paramètres inattendus ;
- ne déclenche aucune navigation ;
- retourne une intention typée.

### 17.4 Sécurité

Un deep link n'est jamais une preuve qu'un paiement est terminé ou qu'une action est autorisée. Il déclenche une vérification serveur authentifiée.

### 17.5 Attribution et campagnes

Si le nouveau projet utilise des campagnes :

- conserver les paramètres autorisés ;
- éviter les données personnelles dans l'URL ;
- ajouter une expiration ou un nonce aux liens sensibles ;
- journaliser la source sans enregistrer le token complet.

---

## 18. Persistance locale et cache

### 18.1 Types de stockage

Utiliser le bon stockage pour le bon besoin :

| Besoin | Stockage recommandé |
|---|---|
| Access/refresh token | Secure storage |
| Petit réglage utilisateur | SharedPreferences |
| Données structurées/cache | SQLite/Drift ou Isar selon décision |
| Fichier ou média | Répertoire applicatif géré |
| État purement temporaire | Mémoire |

### 18.2 Ne pas utiliser SharedPreferences comme base de données

SharedPreferences convient à :

- onboarding vu ;
- langue ;
- thème ;
- petits flags locaux.

Il ne convient pas à :

- historique ;
- listes volumineuses ;
- relations ;
- synchronisation ;
- données transactionnelles.

### 18.3 Cache

Chaque repository doit documenter sa politique :

- network only ;
- cache first puis refresh ;
- stale while revalidate ;
- cache only ;
- durée de validité ;
- invalidation ;
- comportement hors ligne.

### 18.4 Migrations

Dès qu'une base structurée est utilisée :

- versionner le schéma ;
- écrire une migration par version ;
- tester les migrations depuis plusieurs versions anciennes ;
- prévoir sauvegarde/rollback si possible ;
- ne jamais supprimer silencieusement des données utilisateur critiques.

### 18.5 Chiffrement

Le secure storage protège les secrets courts. Pour une base locale sensible, évaluer :

- chiffrement de la base ;
- clés stockées dans Keychain/Keystore ;
- exclusion des backups ;
- purge à la déconnexion ;
- minimisation des données conservées.

---

## 19. Organisation d'une feature

Structure cible détaillée :

```text
features/orders/
├── orders.dart
├── di/
│   └── orders_module.dart
├── data/
│   ├── datasources/
│   │   ├── orders_local_data_source.dart
│   │   ├── orders_remote_data_source.dart
│   │   └── orders_realtime_data_source.dart
│   ├── mappers/
│   │   ├── order_mapper.dart
│   │   └── order_event_mapper.dart
│   ├── models/
│   │   ├── order_dto.dart
│   │   └── order_event_dto.dart
│   └── repositories/
│       └── order_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── order.dart
│   │   └── order_status.dart
│   ├── repositories/
│   │   └── order_repository.dart
│   ├── usecases/
│   │   ├── get_order.dart
│   │   ├── watch_order.dart
│   │   └── submit_order.dart
│   └── value_objects/
│       └── order_id.dart
└── presentation/
    ├── bloc/
    │   ├── order_detail_cubit.dart
    │   └── order_detail_state.dart
    ├── pages/
    │   └── order_detail_page.dart
    ├── routes/
    │   └── order_routes.dart
    ├── view_models/
    │   └── order_detail_view_data.dart
    └── widgets/
        ├── order_status_badge.dart
        └── order_timeline.dart
```

### 19.1 Data source

Responsabilités :

- parler à une technologie précise ;
- retourner un DTO ;
- transformer les erreurs techniques du SDK en exceptions d'infrastructure ;
- ne pas décider d'une règle métier.

### 19.2 Repository implémenté

Responsabilités :

- choisir local/distant ;
- exécuter la stratégie de cache ;
- mapper DTO vers domaine ;
- normaliser les erreurs ;
- coordonner plusieurs data sources.

### 19.3 Use case

Responsabilités :

- porter une intention métier ;
- vérifier les préconditions ;
- coordonner plusieurs repositories ;
- être testable sans Flutter ;
- exposer une signature claire.

### 19.4 Cubit/BLoC

Responsabilités :

- traduire les intentions UI en appels de use cases ;
- exposer un état de présentation ;
- gérer concurrence et rafraîchissement ;
- ne pas dupliquer le métier.

### 19.5 Page

Responsabilités :

- composition de l'écran ;
- branchement des providers/listeners ;
- navigation ;
- adaptation responsive.

La page doit déléguer les sections complexes à des widgets spécifiques.

---

## 20. Design system et thème

### 20.1 Fondations actuelles

FOT DELSI centralise déjà :

- `AppColors` ;
- `AppTypography` ;
- `AppSpacing` ;
- `AppRadius` ;
- `AppDurations` ;
- `AppCurves` ;
- `AppIcons` ;
- `AppImages`.

Cette direction doit être conservée.

### 20.2 Tokens sémantiques

Dans la prochaine app, distinguer les couleurs brutes des couleurs sémantiques :

```text
Palette brute : blue500, blue700, orange500, gray100
Token sémantique : actionPrimary, textPrimary, surfaceRaised, borderDanger
```

Les widgets utilisent les tokens sémantiques, jamais `blue500` directement.

### 20.3 Theme extensions

Créer des `ThemeExtension` pour les tokens non couverts par Material :

```dart
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color warning;
  final Color info;
  final Color disabledSurface;
  // copyWith + lerp
}
```

Cela permet :

- thème clair/sombre ;
- variations de marque ;
- transitions de thème ;
- accès via `Theme.of(context)`.

### 20.4 Thèmes de composants

Centraliser dans `ThemeData` :

- `FilledButtonThemeData` ;
- `OutlinedButtonThemeData` ;
- `InputDecorationTheme` ;
- `BottomSheetThemeData` ;
- `DialogThemeData` ;
- `CardThemeData` ;
- `SnackBarThemeData` ;
- `AppBarTheme` ;
- `NavigationBarThemeData` ;
- `CheckboxThemeData`.

Le widget ne doit définir que les exceptions métier.

### 20.5 Typographie

Définir :

- échelle de titres ;
- corps ;
- labels ;
- nombres/monnaies ;
- règles de hauteur de ligne ;
- graisse disponible ;
- comportement avec facteur de texte élevé.

Tester au minimum à 100 %, 130 % et 200 % de taille de texte.

### 20.6 Espacements et tailles

Conserver une grille de 4 ou 8. Ajouter si nécessaire :

- hauteurs minimales tactiles ;
- largeur maximale des contenus tablet ;
- breakpoints ;
- insets de page ;
- élévations/ombres ;
- opacités standard.

### 20.7 Assets et icônes

- Centraliser les chemins ou utiliser un générateur d'assets.
- Ne pas mélanger plusieurs familles d'icônes sans règle.
- Prévoir des icônes sémantiques, pas seulement des noms graphiques.
- Fournir une alternative accessible aux illustrations importantes.

### 20.8 Catalogue de composants

Créer une application/catalogue interne présentant :

- tous les boutons ;
- champs ;
- cartes ;
- états vides ;
- erreurs ;
- skeletons ;
- dialogues ;
- bottom sheets ;
- notifications ;
- thèmes ;
- tailles de texte.

Le `main_showcase.dart` actuel constitue une bonne inspiration, mais le catalogue de composants doit être indépendant des scénarios App Store.

---

## 21. Animations et mouvement

### 21.1 Principes actuels à conserver

FOT DELSI possède des durées/courbes centralisées et respecte la réduction des animations. Les composants `EntranceFade`, `AnimatedReveal`, `StatusTransition` et `PulseDot` expriment une intention, pas seulement un effet visuel.

### 21.2 Règles

- Une animation explique un changement.
- Elle ne doit pas retarder une action.
- Une liste temps réel ne rejoue pas ses entrées à chaque événement.
- Les animations infinies sont rares et désactivées si le système le demande.
- Les durées et courbes viennent des tokens.
- Les transitions doivent rester testables.

### 21.3 Niveaux de mouvement

```text
micro       pression, sélection, feedback immédiat
component   ouverture d'une carte, changement d'état
page        transition entre destinations
ambient     activité discrète et non critique
```

### 21.4 Performance

- Préférer opacité/transform à des relayouts lourds.
- Passer l'enfant statique à `AnimatedBuilder.child`.
- Limiter les animations simultanées dans les listes.
- Utiliser `RepaintBoundary` après mesure, pas par réflexe.
- Profiler sur appareils milieu de gamme.

### 21.5 Lottie/Rive

Les utiliser uniquement si :

- l'asset apporte une vraie valeur ;
- la taille est maîtrisée ;
- une version statique existe ;
- le reduced motion est respecté ;
- le rendu est testé sur Android/iOS.

---

## 22. Widgets réutilisables

### 22.1 Trois niveaux

**Design system :** générique et sans métier.

```text
AppButton, AppTextField, AppDialog, AppSheet, AppCard, AppBadge
```

**Core métier transversal :** partagé par plusieurs features avec un sens commun.

```text
MoneyText, ConnectivityBanner, PermissionGate
```

**Widget de feature :** réutilisable uniquement dans sa feature.

```text
OrderTimeline, MachineStatusBadge, PaymentProviderCard
```

### 22.2 Quand promouvoir un widget vers le design system

Seulement s'il :

- apparaît dans plusieurs features ;
- ne dépend pas d'une entité métier ;
- possède une API stable ;
- suit les tokens du thème ;
- possède des tests ou stories/catalogue.

### 22.3 API d'un composant

Un composant partagé doit prévoir :

- états normal, pressé, focus, disabled, loading, error ;
- sémantique ;
- taille de texte ;
- clavier ;
- thème clair/sombre ;
- callback nullable si désactivé ;
- absence de logique réseau.

### 22.4 Dialogues et bottom sheets

Créer des fonctions d'entrée cohérentes :

```dart
Future<bool> showAppConfirmationDialog(...)
Future<T?> showAppBottomSheet<T>(...)
```

Elles centralisent :

- style ;
- safe areas ;
- clavier ;
- drag behavior ;
- accessibilité ;
- analytics d'ouverture/confirmation si nécessaire.

---

## 23. Fonctions utilitaires

### 23.1 Ce qui est un bon utilitaire

Les fonctions actuelles de téléphone et de prix sont de bons exemples :

- pures ;
- déterministes ;
- sans état global ;
- testables ;
- associées à une responsabilité précise.

### 23.2 Ce qui ne doit pas devenir un utilitaire

Éviter `helpers.dart` ou `utils.dart` géants contenant :

- appels réseau ;
- navigation ;
- accès GetIt ;
- contexte Flutter ;
- règles métier variées ;
- effets de bord.

### 23.3 Préférer les value objects

Pour une grande app, transformer certains utilitaires en types :

```dart
final class PhoneNumber {
  const PhoneNumber._(this.value);
  final String value;

  static Result<PhoneNumber> parse(String raw) { ... }
  String get display => ...;
}
```

Autres candidats :

- `Money` ;
- `EmailAddress` ;
- `OrderId` ;
- `Percentage` ;
- `UtcDateTime` ;
- `PaginationCursor`.

### 23.4 Extensions

Les extensions doivent rester petites et sans surprise :

- conversion visuelle ;
- garde nullable ;
- helpers de date localisés.

Ne pas masquer un appel réseau ou une mutation dans une extension.

---

## 24. Gestion des erreurs

### 24.1 Pipeline cible

```text
SDK/Dio exception
    ↓
InfrastructureException typée
    ↓ repository
Failure domaine/application
    ↓ Cubit/BLoC
PresentationError / état UI
    ↓
message + action de récupération
```

### 24.2 Taxonomie minimale

```text
NetworkUnavailableFailure
TimeoutFailure
UnauthorizedFailure
ForbiddenFailure
NotFoundFailure
ValidationFailure(fields)
ConflictFailure
RateLimitedFailure(retryAfter)
ServerFailure(correlationId)
ServiceUnavailableFailure
CancelledFailure
UnexpectedFailure(diagnosticId)
```

### 24.3 Erreur métier vs erreur technique

Exemples métier :

- machine déjà occupée ;
- commande déjà traitée ;
- paiement non confirmé ;
- quota dépassé.

Ces erreurs doivent avoir un code stable provenant du backend. L'application ne doit pas déduire la règle depuis le texte français du message.

### 24.4 Présentation

Chaque erreur UI précise :

- message humain ;
- action possible ;
- retry autorisé ou non ;
- données précédentes à conserver ;
- identifiant de diagnostic si utile.

### 24.5 Erreurs inattendues

- capturées par le système de crash reporting ;
- associées à la version et au contexte ;
- masquées à l'utilisateur par un message neutre ;
- jamais avalées silencieusement.

---

## 25. Observabilité, logs et diagnostic

Cette partie est indispensable pour une application plus grande et pour les opérations sensibles.

### 25.1 Trois piliers

1. **Logs structurés** : ce qui s'est passé.
2. **Métriques** : combien de fois et avec quelle latence.
3. **Traces/corrélation** : comment une action traverse mobile, backend et service externe.

### 25.2 Logger abstrait

```dart
abstract interface class AppLogger {
  void debug(String event, {Map<String, Object?> context = const {}});
  void info(String event, {Map<String, Object?> context = const {}});
  void warning(String event, {Object? error, StackTrace? stackTrace});
  void error(String event, {Object? error, StackTrace? stackTrace});
}
```

Ne pas disperser `print` et `debugPrint`.

### 25.3 Événements structurés

Préférer :

```json
{
  "event": "payment.status_check.completed",
  "level": "info",
  "correlationId": "...",
  "paymentId": "masked-or-internal-id",
  "status": "COMPLETED",
  "durationMs": 482,
  "appVersion": "1.2.0",
  "platform": "ios"
}
```

à une phrase libre impossible à agréger.

### 25.4 Corrélation

Une action sensible reçoit un `correlationId` au début. Il est transmis :

- dans les logs mobiles ;
- dans le header HTTP ;
- dans les logs backend ;
- dans les appels aux fournisseurs ;
- dans les événements WebSocket ;
- éventuellement dans les notifications.

Pour un paiement ou une commande machine, ajouter un identifiant métier et une idempotency key distincts.

### 25.5 Breadcrumbs

Conserver les dernières actions non sensibles :

- route ouverte ;
- bouton métier pressé ;
- changement de connectivité ;
- requête commencée/terminée ;
- socket connectée/déconnectée ;
- push reçu/tapé ;
- état de session modifié.

### 25.6 Redaction

Masquer automatiquement :

- tokens ;
- cookies ;
- OTP ;
- mots de passe ;
- numéros complets ;
- emails complets selon politique ;
- contenus de documents ;
- payloads de paiement sensibles.

La redaction s'applique avant tout transport vers un fournisseur de logs.

### 25.7 Crash reporting

Utiliser Sentry, Crashlytics ou équivalent avec :

- environnement ;
- version/build ;
- modèle OS/appareil ;
- route courante ;
- état de connectivité ;
- statut WebSocket ;
- type de session sans token ;
- correlation ID ;
- breadcrumbs.

### 25.8 Métriques produit et techniques

Techniques :

- taux d'erreur API par endpoint ;
- p50/p95/p99 de latence ;
- refresh token réussi/échoué ;
- reconnexions WebSocket ;
- parsing push échoué ;
- cold start ;
- frames lentes.

Produit :

- parcours commencé/terminé/abandonné ;
- étape où l'utilisateur bloque ;
- conversion ;
- activation d'une feature.

Ne pas mélanger analytics produit et logs de diagnostic dans une même API sans convention claire.

### 25.9 Support utilisateur

Ajouter un écran diagnostic exportable contenant uniquement des données sûres :

- version/build ;
- environnement ;
- plateforme/OS ;
- état réseau/backend ;
- état push autorisé ;
- état WebSocket ;
- identifiant diagnostic ;
- horodatage ;
- derniers codes d'erreur non sensibles.

L'utilisateur peut transmettre cet identifiant au support sans envoyer de capture contenant des données privées.

---

## 26. Sécurité

### 26.1 Principes

- Le mobile est un client non fiable.
- Toute autorisation est revérifiée côté backend.
- Les secrets serveur ne sont jamais embarqués.
- Les logs sont considérés comme des données potentiellement exportées.
- Les données locales sont minimisées.

### 26.2 Stockage sécurisé

- Access et refresh tokens dans Keychain/Keystore.
- Mémoire comme cache chaud, pas comme persistance unique.
- Suppression atomique à la déconnexion.
- Ne pas journaliser les valeurs.
- Définir les options d'accessibilité iOS selon le besoin.

### 26.3 Transport

- HTTPS/WSS uniquement en production.
- Refuser les certificats invalides.
- Ne jamais désactiver globalement la validation TLS.
- Évaluer le certificate pinning uniquement si une stratégie de rotation et de secours existe.

### 26.4 Permissions

Demander une permission au moment où sa valeur est compréhensible :

- caméra avant scan ;
- notifications après explication ;
- localisation au début de la fonctionnalité qui l'utilise.

Prévoir : refus, refus permanent, accès limité et ouverture des réglages.

### 26.5 Données personnelles

- collecter le minimum ;
- documenter la finalité ;
- définir la rétention ;
- permettre suppression/export selon les obligations ;
- ne pas utiliser des données de production dans screenshots/tests.

### 26.6 Protection applicative

Selon le risque du prochain projet :

- détection de version obsolète ;
- attestation d'intégrité ;
- blocage d'une version compromise ;
- obfuscation release ;
- protection des screenshots sur écrans très sensibles ;
- timeout d'inactivité ;
- biométrie comme réouverture locale, jamais comme autorisation serveur unique.

---

## 27. Performance

### 27.1 Démarrage

- Mesurer le temps avant premier frame et premier contenu utile.
- Différer les SDK non essentiels.
- Précharger uniquement la session minimale.
- Ne pas lire plusieurs fois le secure storage pendant le démarrage.

### 27.2 Rebuilds

- Utiliser `BlocSelector` pour observer une portion d'état.
- Découper les widgets lourds.
- Employer des constructeurs `const`.
- Éviter de recréer des objets coûteux dans `build`.
- Vérifier les listes temps réel avec Flutter DevTools.

### 27.3 Listes

- `ListView.builder`/slivers ;
- pagination ;
- clés stables ;
- préservation de l'ordre lors des deltas ;
- images mises en cache avec limites ;
- skeletons raisonnables.

### 27.4 Réseau

- pagination serveur ;
- compression ;
- payloads minimaux ;
- ETag/If-None-Match si pertinent ;
- éviter les refresh complets après chaque delta ;
- annuler les recherches obsolètes.

### 27.5 Temps réel

- limiter le débit des mises à jour UI ;
- agréger les événements fréquents ;
- ne reconstruire que l'entité modifiée ;
- suspendre ce qui n'est pas utile en arrière-plan.

---

## 28. Accessibilité et internationalisation

### 28.1 Internationalisation dès le départ

Même si la première version est seulement en français :

- utiliser les fichiers ARB ;
- ne pas coder les textes directement dans les widgets ;
- gérer pluriels, genres et paramètres ;
- formater dates/nombres/monnaies par locale ;
- prévoir les textes serveur sous forme de codes stables.

### 28.2 Accessibilité

- cibles tactiles minimales ;
- contraste suffisant ;
- labels sémantiques ;
- ordre de focus ;
- support clavier/tablette ;
- taille de texte élevée ;
- reduced motion ;
- ne pas dépendre uniquement de la couleur ;
- annoncer les changements importants aux technologies d'assistance.

### 28.3 Tests

Ajouter des tests pour :

- overflow avec texte à 200 % ;
- contraste des tokens ;
- labels des boutons icon-only ;
- navigation sans animation ;
- composants dans langues plus longues.

---

## 29. Stratégie de tests

### 29.1 Pyramide

```text
beaucoup de tests unitaires
      ↓
tests Cubit/BLoC et repository
      ↓
tests widgets ciblés
      ↓
quelques tests d'intégration critiques
      ↓
très peu de scénarios end-to-end externes
```

### 29.2 Tests unitaires

Tester :

- value objects ;
- use cases ;
- mappers ;
- politiques de retry/cache ;
- parsing de payloads ;
- fusion WebSocket ;
- règles métier ;
- formatage.

### 29.3 Repositories

Tester avec data sources fake :

- succès distant ;
- cache puis refresh ;
- erreur réseau avec cache ;
- parsing invalide ;
- conflit ;
- invalidation ;
- stratégie offline.

### 29.4 BLoC/Cubit

Tester les suites d'états et les politiques de concurrence. Utiliser `bloc_test` dans le prochain projet pour rendre les scénarios plus lisibles.

### 29.5 Widgets

Tester :

- état loading/success/empty/error ;
- action utilisateur ;
- dialogue ou sheet ;
- accessibilité ;
- taille de texte ;
- reduced motion ;
- reprise après erreur.

### 29.6 Golden tests

Réserver les goldens aux composants stables :

- design system ;
- cartes importantes ;
- écrans critiques ;
- thèmes clair/sombre ;
- plusieurs tailles.

Ne pas faire dépendre un golden de dates ou données non déterministes.

### 29.7 Tests d'intégration critiques

Scénarios minimum :

- connexion/restauration/refresh/déconnexion ;
- action sensible idempotente ;
- paiement en attente puis confirmé ;
- perte et retour réseau ;
- reconnexion WebSocket avec snapshot REST ;
- push ouvrant la bonne destination ;
- migration de base locale.

### 29.8 Fakes plutôt que mocks profonds

Le `ShowcaseHttpAdapter` actuel démontre une bonne approche : remplacer une couture basse et exécuter le reste de la vraie pile. Utiliser :

- adaptateur HTTP fake ;
- clock fake ;
- secure storage mémoire ;
- push fake ;
- realtime fake ;
- fixtures JSON versionnées.

### 29.9 Organisation

Les tests doivent refléter `lib/` :

```text
test/features/orders/data/...
test/features/orders/domain/...
test/features/orders/presentation/...
```

Les fixtures sont partagées uniquement quand leur contrat est réellement commun.

---

## 30. Qualité, CI/CD et livraison

### 30.1 Pipeline de pull request

Étapes obligatoires :

1. vérification du format ;
2. analyse statique ;
3. génération de code et contrôle qu'aucun diff n'est oublié ;
4. tests unitaires/widgets ;
5. contrôle d'architecture ;
6. audit des dépendances ;
7. build Android debug/release selon coût ;
8. build iOS sans signature sur runner compatible ;
9. rapport de couverture sans objectif aveugle.

### 30.2 Pipeline de release

- version déterministe ;
- build number automatique ;
- changelog ;
- signature depuis secrets CI ;
- App Bundle Android ;
- IPA iOS ;
- upload vers stores ;
- symboles de crash/obfuscation archivés ;
- tag Git ;
- déploiement progressif ;
- surveillance post-release.

### 30.3 Preflight plateforme

Le script iOS actuel vérifie la cohérence bundle/Firebase/entitlements. Généraliser ces contrôles :

- bundle ID/application ID ;
- Firebase par flavor ;
- capacités push ;
- deep links/app links ;
- version minimale OS ;
- signatures ;
- permissions déclarées ;
- symboles natifs ;
- présence des fichiers de configuration attendus.

### 30.4 Version minimale supportée

Le backend ou remote config doit pouvoir déclarer :

- version recommandée ;
- version minimale obligatoire ;
- message ;
- URL store ;
- période de grâce.

Une mise à jour forcée doit être exceptionnelle et testée.

### 30.5 Déploiement progressif

- internal testing ;
- beta/TestFlight ;
- pourcentage progressif ;
- surveillance erreurs et métriques ;
- pause/rollback via stores et feature flags.

---

## 31. Conventions de développement

### 31.1 Nommage

- fichiers en `snake_case` ;
- types en `UpperCamelCase` ;
- variables/méthodes en `lowerCamelCase` ;
- suffixes explicites : `Dto`, `Entity` uniquement si ambigu, `RepositoryImpl`, `Cubit`, `State`, `DataSource` ;
- événements au passé pour les faits, à l'intention pour les commandes selon convention documentée.

### 31.2 Imports

- imports package cohérents dans `lib` ;
- imports relatifs possibles à l'intérieur d'un petit sous-module si l'équipe le décide ;
- aucun import vers un interne d'une autre feature ;
- trier automatiquement les imports.

### 31.3 Immutabilité

- états immuables ;
- listes non modifiées en place ;
- entités immuables ;
- `const` autant que possible ;
- copies explicites.

### 31.4 Null safety

Un champ nullable signifie réellement « absence valide ». Ne pas rendre nullable un champ uniquement pour contourner une étape d'initialisation.

### 31.5 Commentaires

Commenter le **pourquoi**, les contraintes et les pièges. Ne pas commenter une ligne évidente. Les commentaires actuels autour du refresh token, du WebSocket et du push sont de bons exemples de contexte utile.

### 31.6 Lints recommandés

Renforcer progressivement :

- `avoid_dynamic_calls` ;
- `avoid_print` ;
- `cancel_subscriptions` ;
- `close_sinks` ;
- `discarded_futures` ;
- `unawaited_futures` ;
- `use_build_context_synchronously` ;
- `prefer_final_locals` ;
- `always_declare_return_types` ;
- `directives_ordering` ;
- `sort_constructors_first` si accepté par l'équipe.

Les règles doivent rester utiles et être introduites sans centaines de suppressions.

### 31.7 Definition of Done

Une feature est terminée quand :

- règles métier testées ;
- états loading/empty/error/success traités ;
- offline défini ;
- analytics/logs sensibles définis ;
- accessibilité vérifiée ;
- push/deep link testés si concernés ;
- erreurs serveur mappées ;
- documentation/API mise à jour ;
- tests CI verts ;
- observabilité prête pour la production.

---

## 32. Modèle complet d'une nouvelle feature

Exemple : soumettre une commande.

### 32.1 Domaine

```dart
abstract interface class OrderRepository {
  Future<Result<Order, Failure>> submit(SubmitOrderCommand command);
}

final class SubmitOrder {
  const SubmitOrder(this._repository);
  final OrderRepository _repository;

  Future<Result<Order, Failure>> call(SubmitOrderCommand command) {
    return _repository.submit(command);
  }
}
```

### 32.2 Data source

```dart
final class OrdersRemoteDataSource {
  const OrdersRemoteDataSource(this._client);
  final AuthenticatedApiClient _client;

  Future<OrderDto> submit(
    SubmitOrderRequestDto request, {
    required IdempotencyKey idempotencyKey,
  }) async {
    final response = await _client.postJson(
      '/orders',
      body: request.toJson(),
      idempotencyKey: idempotencyKey.value,
    );
    return OrderDto.fromJson(response.data);
  }
}
```

### 32.3 Repository

```dart
final class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._remote, this._mapper, this._logger);

  final OrdersRemoteDataSource _remote;
  final OrderMapper _mapper;
  final AppLogger _logger;

  @override
  Future<Result<Order, Failure>> submit(SubmitOrderCommand command) async {
    final key = command.idempotencyKey;
    try {
      final dto = await _remote.submit(
        SubmitOrderRequestDto.fromDomain(command),
        idempotencyKey: key,
      );
      return Success(_mapper.toDomain(dto));
    } on InfrastructureException catch (error, stackTrace) {
      _logger.warning(
        'order.submit.failed',
        error: error,
        stackTrace: stackTrace,
      );
      return FailureResult(mapInfrastructureFailure(error));
    }
  }
}
```

### 32.4 Présentation

```dart
final class SubmitOrderCubit extends Cubit<SubmitOrderState> {
  SubmitOrderCubit(this._submitOrder) : super(const SubmitOrderIdle());

  final SubmitOrder _submitOrder;

  Future<void> submit(OrderDraft draft) async {
    if (state is SubmitOrderLoading) return;
    emit(const SubmitOrderLoading());

    final result = await _submitOrder(draft.toCommand());
    switch (result) {
      case Success(value: final order):
        emit(SubmitOrderSuccess(order));
      case FailureResult(failure: final failure):
        emit(SubmitOrderFailure(failure));
    }
  }
}
```

### 32.5 Route

La route construit le Cubit avec l'injecteur et garde la page indépendante du service locator :

```dart
GoRoute(
  path: '/orders/new',
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<SubmitOrderCubit>(),
    child: const SubmitOrderPage(),
  ),
)
```

### 32.6 Tests minimum

- validation de `OrderDraft` ;
- mapping request/response ;
- repository sur succès, timeout, conflit et réponse invalide ;
- use case ;
- Cubit empêchant le double submit ;
- widget loading/error/success ;
- intégration vérifiant l'idempotence.

---

## 33. Décisions à conserver et améliorations prioritaires

### 33.1 À conserver de FOT DELSI

1. Organisation par feature.
2. Séparation `data/domain/presentation`.
3. BLoC/Cubit.
4. GetIt avec overrides de test.
5. Une seule socket partagée.
6. Abstraction du push.
7. Secure storage préchargé en mémoire.
8. Refresh token mutualisé.
9. Thème et motion centralisés.
10. Fakes au niveau de l'infrastructure.
11. Tests ciblés sur les régressions métier.
12. Preflight de release iOS.

### 33.2 Priorité 1 : à intégrer dès le premier commit

- flavors dev/staging/prod ;
- `AppConfig` typé ;
- bootstrap avec gestion globale d'erreurs ;
- modules DI par feature ;
- routes par feature et typées ;
- DTO générés et mappers ;
- logger structuré avec redaction ;
- correlation IDs ;
- design system avec ThemeExtensions ;
- l10n ;
- structure de tests miroir ;
- CI format/analyze/test/build.

### 33.3 Priorité 2 : avant première production

- crash reporting ;
- analytics séparées des logs ;
- retry/idempotence formalisés ;
- stratégie de cache ;
- health check réel ;
- WebSocket versionné et resynchronisable ;
- push/deep-link coordinator ;
- feature flags ;
- version minimale supportée ;
- tests d'intégration des parcours critiques ;
- pipeline de release automatisé.

### 33.4 Priorité 3 : avec la croissance

- extraction du design system en package ;
- packages internes par domaine si l'équipe grandit ;
- base locale avec synchronisation avancée ;
- monitoring de performance ;
- catalogue de composants ;
- contrôle automatique des frontières architecturales ;
- tests de contrat avec le backend ;
- automatisation de rollback et déploiement progressif.

### 33.5 À éviter

- créer un dossier `shared` où tout finit ;
- rendre chaque classe singleton ;
- appeler GetIt partout ;
- faire du DTO l'entité métier ;
- stocker l'état serveur uniquement dans les widgets ;
- traiter WebSocket comme source toujours fiable ;
- retry automatique de tous les POST ;
- logs contenant les payloads complets en production ;
- navigation directement depuis un repository ;
- règles métier codées dans des couleurs, textes ou conditions UI ;
- dépendances croisées entre features ;
- abstractions sans deuxième usage ni bénéfice testable.

---

## 34. Checklist de démarrage du prochain projet

### Fondation

- [ ] Définir les domaines métier et leurs frontières.
- [ ] Créer les flavors dev/staging/prod.
- [ ] Créer `AppConfig` et les points d'entrée.
- [ ] Installer le bootstrap et le handler d'erreurs.
- [ ] Définir les règles d'import et les lints.
- [ ] Installer la CI dès le premier jour.

### Architecture

- [ ] Créer `core`, `design_system`, `navigation`, `di`, `features` et `l10n`.
- [ ] Créer un template de feature.
- [ ] Définir Result/Failure/Exception.
- [ ] Définir les modules DI.
- [ ] Documenter les scopes singleton/factory/session.

### Réseau et session

- [ ] Créer les clients HTTP public/auth/upload.
- [ ] Ajouter correlation ID, redaction et télémétrie.
- [ ] Définir timeout, retry et idempotence.
- [ ] Créer le secure session store.
- [ ] Créer le `SessionCoordinator`.
- [ ] Tester les 401 concurrents et le refresh refusé.

### Données

- [ ] Choisir génération JSON.
- [ ] Séparer DTO et entités.
- [ ] Choisir la base locale si nécessaire.
- [ ] Définir cache et migrations.
- [ ] Créer fixtures et fakes d'infrastructure.

### Navigation

- [ ] Installer GoRouter typé.
- [ ] Définir les guards.
- [ ] Définir les shells/onglets.
- [ ] Créer le coordinateur d'intentions entrantes.
- [ ] Configurer Universal Links et App Links.

### Temps réel et push

- [ ] Créer un transport realtime unique.
- [ ] Versionner les événements.
- [ ] Définir resynchronisation REST après reconnexion.
- [ ] Abstraire FCM/APNs.
- [ ] Versionner les payloads push.
- [ ] Tester foreground/background/cold start.

### UI

- [ ] Définir les tokens du design system.
- [ ] Créer ThemeExtensions et thèmes de composants.
- [ ] Définir les règles de motion et reduced motion.
- [ ] Créer les composants de base.
- [ ] Créer un catalogue visuel.
- [ ] Tester texte agrandi, contraste et lecteurs d'écran.

### Observabilité et sécurité

- [ ] Installer logger, crash reporting et analytics.
- [ ] Définir la redaction.
- [ ] Ajouter breadcrumbs et diagnostic ID.
- [ ] Définir les événements des parcours critiques.
- [ ] Auditer permissions et stockage.
- [ ] Prévoir révocation de session et version minimale.

### Tests et livraison

- [ ] Organiser `test/` comme `lib/`.
- [ ] Ajouter tests unitaires, Cubit/BLoC et widgets.
- [ ] Ajouter les parcours d'intégration critiques.
- [ ] Ajouter preflight Android/iOS.
- [ ] Automatiser App Bundle, IPA et upload stores.
- [ ] Archiver symboles et informations de build.
- [ ] Mettre en place déploiement progressif et surveillance.

---

## Conclusion

L'architecture actuelle de FOT DELSI constitue une bonne base : elle a déjà les bons axes de séparation, une infrastructure réseau raisonnable, une socket mutualisée, un push abstrait, une navigation centralisée et un début de design system.

Pour la prochaine application, le principal changement n'est pas de remplacer les bibliothèques. Il faut surtout rendre les frontières explicites, modulariser la composition, typer les contrats, prévoir la résilience, intégrer l'observabilité dès le départ et automatiser les contrôles. Une grande application reste propre lorsque chaque nouvelle feature suit le même chemin, que les incidents sont traçables et que les dépendances ne peuvent pas se répandre librement.

Ce document doit être traité comme une base vivante : chaque décision importante du nouveau projet devra être ajoutée sous forme d'ADR, avec son contexte, les options envisagées, la décision et ses conséquences.
