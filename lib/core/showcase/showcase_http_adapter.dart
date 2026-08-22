import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_endpoints.dart';
import 'showcase_story.dart';

/// Adaptateur HTTP qui répond à la place du serveur, pour les captures d'écran.
///
/// ─── Pourquoi ici et pas plus haut ───
///
/// On aurait pu enregistrer de faux dépôts (`MachineRepository`,
/// `DropOffRepository`, …) dans le service locator. Deux raisons de ne pas le
/// faire :
///
///  1. **Une seule couture au lieu de dix.** Un faux par dépôt, c'est dix
///     fichiers à maintenir en parallèle des vrais, et ils divergent au premier
///     changement de signature.
///  2. **Ce qu'on photographie reste l'application.** En branchant au niveau
///     HTTP, tout le vrai code s'exécute : désérialisation, mapping vers les
///     entités, dépôts, cubits, widgets. Une capture prouve donc quelque chose.
///     Avec de faux dépôts, on photographierait une marionnette.
///
/// Ce fichier ne contient **aucune donnée** : elles sont toutes dans
/// [ShowcaseStory]. Ici, uniquement l'aiguillage.
class ShowcaseHttpAdapter implements HttpClientAdapter {
  ShowcaseHttpAdapter({this.latency = const Duration(milliseconds: 140)});

  /// Latence simulée.
  ///
  /// Zéro donnerait des écrans qui apparaissent déjà remplis, sans jamais
  /// passer par leurs états de chargement — on ne verrait donc pas si un
  /// squelette est cassé. 140 ms suffit à les traverser sans faire attendre.
  final Duration latency;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final body = _route(options.method.toUpperCase(), options.path);

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Object? _route(String method, String path) {
    // Les écritures (démarrer une machine, payer, lier un numéro) réussissent
    // toutes en silence : dans une capture, seul l'écran d'après compte.
    if (method != 'GET') return ShowcaseStory.envelope(const {});

    return switch (path) {
      ApiEndpoints.status => ShowcaseStory.envelope(ShowcaseStory.status()),
      ApiEndpoints.serviceFormulas => ShowcaseStory.envelope(
        ShowcaseStory.formulas(),
      ),
      ApiEndpoints.machines => ShowcaseStory.envelope(ShowcaseStory.machines()),
      ApiEndpoints.myCycles => ShowcaseStory.envelope(ShowcaseStory.myCycles()),
      ApiEndpoints.myPendingPayments => ShowcaseStory.envelope(
        ShowcaseStory.pendingPayments(),
      ),
      ApiEndpoints.clientProfile => ShowcaseStory.envelope(
        ShowcaseStory.profile(),
      ),
      ApiEndpoints.myDropOffs => ShowcaseStory.envelope(
        ShowcaseStory.myDropOffs(),
      ),
      _ => _parameterized(path),
    };
  }

  Object? _parameterized(String path) {
    // `/me/dropoffs/:id` — un seul dépôt en vitrine, quel que soit l'id
    // demandé : suivre le lien depuis n'importe quel cycle doit aboutir.
    if (path.startsWith('${ApiEndpoints.myDropOffs}/')) {
      return ShowcaseStory.envelope(ShowcaseStory.finishingDropOff());
    }

    // `/machines/:id` et `/machines/device/:name`
    if (path.startsWith('${ApiEndpoints.machines}/')) {
      final id = path.split('/').last;
      final machines = ShowcaseStory.machines();
      final found = machines.firstWhere(
        (m) => m['id'] == id || m['code'] == id,
        orElse: () => machines.first,
      );
      return ShowcaseStory.envelope(found);
    }

    _signalerRouteInconnue(path);

    // Enveloppe vide plutôt qu'une erreur : un 404 ferait apparaître un écran
    // d'erreur rouge au milieu d'une séance de captures. L'écran sera vide —
    // et l'avertissement ci-dessus dit lequel compléter.
    return ShowcaseStory.envelope(const {});
  }

  final Set<String> _dejaSignalees = {};

  void _signalerRouteInconnue(String path) {
    if (!_dejaSignalees.add(path)) return;
    debugPrint(
      'VITRINE — route non couverte : $path\n'
      "  L'écran s'affichera vide. Ajoutez-la dans ShowcaseStory si elle doit "
      'apparaître sur une capture.',
    );
  }

  @override
  void close({bool force = false}) {}
}
