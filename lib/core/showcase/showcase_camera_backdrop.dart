import 'package:flutter/material.dart';

/// Ce que la caméra verrait, pour la capture d'écran du scan.
///
/// ─── Dessiné, et non photographié ───
///
/// Une photo de laverie daterait la fiche : elle montrerait un local, un
/// éclairage, un modèle de machine. Un dessin sobre suggère le geste sans rien
/// promettre de précis — et se refait en une ligne le jour où le parc change.
///
/// ─── Composé autour du cadre de visée ───
///
/// Le cadre fait 220 points et se pose au centre de l'écran. L'autocollant QR
/// est donc placé là, à cette taille : c'est ce que le cadre doit encadrer.
/// Une première version centrait la machine entière — le cadre tombait sur le
/// hublot, et la capture montrait quelqu'un visant une porte.
///
/// ─── Volontairement peu contrasté ───
///
/// Le sujet de la capture, ce sont le cadre et sa consigne. Un fond trop
/// présent leur volerait l'œil.
class ShowcaseCameraBackdrop extends StatelessWidget {
  const ShowcaseCameraBackdrop({super.key});

  /// Doit suivre `ScanViewfinder.size`.
  static const double _viewfinder = 220;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        // La lumière tombe d'en haut, comme un plafonnier de laverie.
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.15,
          colors: [Color(0xFF31496F), Color(0xFF0A1729)],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: _viewfinder * 1.9,
          height: _viewfinder * 2.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: CustomPaint(painter: _MachinePainter())),
              // L'autocollant, exactement où le cadre viendra se poser.
              SizedBox(
                width: _viewfinder * 0.62,
                height: _viewfinder * 0.62,
                child: CustomPaint(painter: _QrStickerPainter()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La façade : un panneau, un bandeau de commandes, un hublot sous le code.
class _MachinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()
      ..color = const Color(0xFF3A5A8C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(26),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF16253F));
    canvas.drawRRect(body, edge);

    // Bandeau de commandes.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.07,
            size.width * 0.8, size.height * 0.06),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF1F3558),
    );

    // Le hublot, SOUS l'autocollant : le code se colle au-dessus de la porte,
    // là où on le lit sans se baisser.
    final centre = Offset(size.width / 2, size.height * 0.68);
    final rayon = size.width * 0.30;

    canvas.drawCircle(centre, rayon, Paint()..color = const Color(0xFF1F3558));
    canvas.drawCircle(centre, rayon, edge);
    canvas.drawCircle(
      centre,
      rayon * 0.74,
      Paint()..color = const Color(0xFF0E1E36),
    );
    canvas.drawCircle(
      centre.translate(-rayon * 0.32, -rayon * 0.32),
      rayon * 0.16,
      Paint()..color = const Color(0x1AFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Un QR code stylisé : trois repères d'angle et une trame.
///
/// Ne code rien — il n'est jamais lu, seulement photographié. Dessiner un vrai
/// code obligerait à embarquer un générateur pour une image décorative.
class _QrStickerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // L'autocollant blanc, comme sur les machines.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFF2F5FA),
    );

    final encre = Paint()..color = const Color(0xFF0F1B2D);
    final u = size.width / 11; // module du code

    void repere(double cx, double cy) {
      canvas.drawRect(Rect.fromLTWH(cx, cy, u * 3, u * 3), encre);
      canvas.drawRect(
        Rect.fromLTWH(cx + u * 0.75, cy + u * 0.75, u * 1.5, u * 1.5),
        Paint()..color = const Color(0xFFF2F5FA),
      );
    }

    repere(u, u);
    repere(size.width - u * 4, u);
    repere(u, size.height - u * 4);

    // Une trame régulière : de loin, un QR code se lit à sa texture.
    for (var i = 0; i < 5; i++) {
      for (var j = 0; j < 5; j++) {
        if ((i + j) % 2 != 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(u * (5 + i * 1.1), u * (5 + j * 1.1), u * 0.8, u * 0.8),
          encre,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
