/// Coordonnées du client mémorisées localement pour préremplir le paiement.
class CustomerProfile {
  const CustomerProfile({
    required this.fullName,
    required this.phone,
  });

  final String fullName;
  final String phone;

  bool get isEmpty => fullName.isEmpty && phone.isEmpty;

  static const empty = CustomerProfile(fullName: '', phone: '');
}
