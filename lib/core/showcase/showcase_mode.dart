/// Indique que l'application tourne pour la séance de captures.
///
/// ─── Pourquoi ce drapeau existe ───
///
/// Presque tout se simule au niveau du réseau — c'est le rôle de
/// [ShowcaseHttpAdapter], et c'est de loin la meilleure façon de faire : les
/// écrans restent ceux de production, jusqu'à la désérialisation.
///
/// La caméra échappe à cette règle. `MobileScanner` ouvre un périphérique
/// matériel qui n'existe pas sur simulateur : la capture de l'écran de scan
/// sortirait noire, ou avec le message d'erreur de la caméra. Or c'est le
/// geste le plus caractéristique du service, et il mérite d'être montré.
///
/// ─── Ce que le drapeau NE fait pas ───
///
/// Il ne change aucun comportement métier, aucun texte, aucune mise en page.
/// Il substitue une image de fond, et rien d'autre. Toute tentation d'en
/// faire un second mode de l'application doit être refusée ici : une vitrine
/// qui diverge de l'application ment au client avant même qu'il l'installe.
///
/// Vaut `false` dans le binaire de production — seul `main_showcase.dart` le
/// lève, et rien ne l'importe depuis `main.dart`.
abstract final class ShowcaseMode {
  const ShowcaseMode._();

  static bool _enabled = false;

  static bool get enabled => _enabled;

  /// Appelé une seule fois, depuis le point d'entrée vitrine.
  static void enable() => _enabled = true;
}
