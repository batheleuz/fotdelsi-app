import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../cubit/new_dropoff_cubit.dart';

/// Étape 1 — coordonnées du client.
class NewDropOffClientStep extends StatefulWidget {
  const NewDropOffClientStep({super.key});

  @override
  State<NewDropOffClientStep> createState() => _NewDropOffClientStepState();
}

class _NewDropOffClientStepState extends State<NewDropOffClientStep> {
  late final TextEditingController _phone;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final state = context.read<NewDropOffCubit>().state;
    _phone = TextEditingController(text: state.contactPhone);
    _name = TextEditingController(text: state.customerName);
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewDropOffCubit>();
    final isPhoneValid =
        context.select((NewDropOffCubit c) => c.state.isPhoneValid);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const _Label('Numéro de téléphone du client'),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          maxLength: 9,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: cubit.setPhone,
          decoration: _decoration(
            hint: '77 123 45 67',
            prefix: const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Text('+221',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
            suffix: isPhoneValid
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : null,
            counter: '',
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6, left: 2),
          child: Text('Préfixes acceptés : 70 · 75 · 76 · 77 · 78',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ),
        const SizedBox(height: AppSpacing.md),
        const _Label('Nom du client'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.setName,
          decoration: _decoration(hint: 'Ex. Awa Diop'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F1FF),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFF155A9E)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Relisez le numéro à voix haute avec le client : la demande de paiement y sera envoyée.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF155A9E)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
    String? counter,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 14),
              child: prefix,
            ),
      prefixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      counterText: counter,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
      );
}
