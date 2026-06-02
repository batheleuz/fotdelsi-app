/// Formate un montant en FCFA avec séparateur de milliers : `8000` → `8 000 FCFA`.
String formatFcfa(int amount, {bool withSuffix = true}) {
  final digits = amount.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('\u202F');
    }
    buffer.write(digits[i]);
  }

  return withSuffix ? '$buffer\u202FFCFA' : buffer.toString();
}
