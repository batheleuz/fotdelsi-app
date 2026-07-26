import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/customer_profile.dart';

/// Persiste les coordonnées du client (nom + téléphone) sur le device.
class CustomerProfileLocalDataSource {
  const CustomerProfileLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _keyFullName = 'customer_full_name';
  static const _keyPhone = 'customer_phone';

  Future<void> save(CustomerProfile profile) async {
    await Future.wait([
      _prefs.setString(_keyFullName, profile.fullName),
      _prefs.setString(_keyPhone, profile.phone),
    ]);
  }

  CustomerProfile load() {
    return CustomerProfile(
      fullName: _prefs.getString(_keyFullName) ?? '',
      phone: _prefs.getString(_keyPhone) ?? '',
    );
  }
}
