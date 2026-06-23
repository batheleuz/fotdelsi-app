import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';

/// Saisie d'un code OTP à 4 chiffres : 4 cases, auto-avance, auto-validation.
///
/// Implémentation robuste : un seul [TextField] invisible capte la saisie ;
/// les 4 cases ne sont qu'un affichage de son contenu.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onCompleted,
    this.length = 4,
    this.hasError = false,
  });

  final int length;
  final bool hasError;

  /// Appelé quand les [length] chiffres sont saisis.
  final ValueChanged<String> onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _onChanged() {
    setState(() {});
    if (_controller.text.length == widget.length) {
      _focus.unfocus();
      widget.onCompleted(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (i) {
            final filled = i < text.length;
            final active = i == text.length;
            return Container(
              width: 56,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: widget.hasError
                      ? AppColors.danger
                      : (active || filled)
                          ? AppColors.primaryLight
                          : AppColors.border,
                  width: (active || widget.hasError) ? 2 : 1,
                ),
              ),
              child: Text(
                filled ? text[i] : '',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              showCursor: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ),
      ],
    );
  }
}
