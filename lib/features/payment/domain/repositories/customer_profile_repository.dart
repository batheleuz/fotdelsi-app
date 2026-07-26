import '../entities/customer_profile.dart';

abstract interface class CustomerProfileRepository {
  CustomerProfile load();
  Future<void> save(CustomerProfile profile);
}
