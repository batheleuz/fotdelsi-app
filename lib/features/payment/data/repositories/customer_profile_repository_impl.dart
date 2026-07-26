import '../../domain/entities/customer_profile.dart';
import '../../domain/repositories/customer_profile_repository.dart';
import '../datasources/customer_profile_local_data_source.dart';

class CustomerProfileRepositoryImpl implements CustomerProfileRepository {
  const CustomerProfileRepositoryImpl(this._local);

  final CustomerProfileLocalDataSource _local;

  @override
  CustomerProfile load() => _local.load();

  @override
  Future<void> save(CustomerProfile profile) => _local.save(profile);
}
