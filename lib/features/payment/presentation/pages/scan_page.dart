import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_router.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import '../bloc/scan_bloc.dart';
import '../bloc/scan_event.dart';
import '../bloc/scan_state.dart';
import '../widgets/scan_top_bar.dart';
import '../widgets/scan_viewfinder.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<ScanBloc>(),
      child: const _ScanView(),
    );
  }
}

class _ScanView extends StatefulWidget {
  const _ScanView();

  @override
  State<_ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<_ScanView> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    torchEnabled: false,
  );
  bool _torchOn = false;
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final raw = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (kDebugMode) debugPrint('QrCode raw => $raw');
    if (raw == null || raw.isEmpty) return;
    _processing = true;
    _controller.stop();
    context.read<ScanBloc>().add(ScanQrDetected(raw));
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  void _onListenerState(BuildContext context, ScanState state) {
    if (state.status == ScanStatus.success && state.machine != null) {
      // On attend que le flow programme→paiement soit terminé (pop) avant de
      // relancer la caméra. context.push() retourne une Future qui se complète
      // au pop — cela évite qu'un second scan soit déclenché pendant la
      // navigation et provoque un conflit de GlobalKey sur le Navigator GoRouter.
      final machine = state.machine!;
      // La machine est identifiée par le scan : reste à choisir la prestation.
      final PickFormulaArgs args = (machine: machine);
      context.push(AppRoutes.pickFormula, extra: args).then((_) {
        if (mounted) _resumeScanning();
      });
    }
    // En cas d'erreur : on NE relance PAS le scan automatiquement. La caméra
    // reste arrêtée et `_ErrorOverlay` affiche le message avec un bouton
    // « Scanner à nouveau ». Sinon le QR, toujours devant l'objectif, serait
    // redétecté instantanément → même erreur en boucle.
  }

  void _resumeScanning() {
    context.read<ScanBloc>().add(const ScanReset());
    _processing = false;
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1B33),
      body: BlocListener<ScanBloc, ScanState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: _onListenerState,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => const _CameraError(),
            ),
            SafeArea(
              child: Column(
                children: [
                  ScanTopBar(
                    torchOn: _torchOn,
                    onBack: () => Navigator.of(context).maybePop(),
                    onToggleTorch: _toggleTorch,
                  ),
                  const Spacer(),
                  const ScanViewfinder(),
                  const SizedBox(height: 34),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      children: [
                        Text(
                          'Scannez le QR de la machine',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Placez le code dans le cadre pour démarrer votre lavage',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // ManualEntryButton(onTap: _showManualEntry),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            BlocBuilder<ScanBloc, ScanState>(
              buildWhen: (p, c) => p.status != c.status,
              builder: (context, state) => switch (state.status) {
                ScanStatus.processing => const _ProcessingOverlay(),
                ScanStatus.error => _ErrorOverlay(
                  message: state.error ?? 'Code QR invalide.',
                  onRetry: _resumeScanning,
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Identification de la machine…',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Erreur de scan (QR inconnu, machine indisponible…). Bloquante par choix :
/// tant qu'elle est affichée la caméra reste arrêtée, ce qui évite de
/// redétecter le même QR en boucle. L'utilisateur relance explicitement.
class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white70,
            size: 48,
          ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Scanner à nouveau'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1B33),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.no_photography_outlined, color: Colors.white70, size: 48),
          SizedBox(height: 16),
          Text(
            'Caméra indisponible',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Autorisez l'accès à la caméra dans les réglages pour scanner les QR.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ManualEntrySheet extends StatefulWidget {
  const _ManualEntrySheet({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Code machine',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Saisissez le code inscrit sur la machine (ex. WASH_02).',
            style: TextStyle(fontSize: 12, color: Color(0xFF5A6B85)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'WASH_02',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final code = _controller.text.trim();
                if (code.isNotEmpty) widget.onSubmit(code);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Continuer'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
