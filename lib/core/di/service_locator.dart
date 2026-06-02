import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/machines/data/datasources/machine_api_data_source.dart';
import '../../features/machines/data/datasources/machine_remote_data_source.dart';
import '../../features/machines/data/repositories/machine_repository_impl.dart';
import '../../features/machines/domain/repositories/machine_repository.dart';
import '../../features/machines/domain/usecases/get_machine.dart';
import '../../features/machines/domain/usecases/get_machines.dart';
import '../../features/machines/domain/usecases/watch_machines.dart';
import '../../features/machines/presentation/bloc/machines_bloc.dart';
import '../network/dio_client.dart';

/// Conteneur d'injection de dépendances unique de l'application.
final GetIt serviceLocator = GetIt.instance;

/// Initialise toutes les dépendances. Appelé une fois depuis `main()` avant
/// `runApp`. Les enregistrements sont groupés par feature pour rester lisibles
/// et faciles à étendre.
Future<void> setupLocator() async {
  // --- Core ---
  serviceLocator.registerLazySingleton<Dio>(() => DioClient.create());

  // --- Features ---
  _registerMachines();
}

void _registerMachines() {
  // Data
  serviceLocator.registerLazySingleton<MachineApiDataSource>(
    () => MachineApiDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<MachineRemoteDataSource>(
    () => const MachineRemoteDataSource(),
  );
  serviceLocator.registerLazySingleton<MachineRepository>(
    () => MachineRepositoryImpl(serviceLocator(), serviceLocator()),
  );

  // Domain (use cases)
  serviceLocator.registerFactory<GetMachines>(
    () => GetMachines(serviceLocator()),
  );
  serviceLocator.registerFactory<GetMachine>(
    () => GetMachine(serviceLocator()),
  );
  serviceLocator.registerFactory<WatchMachines>(
    () => WatchMachines(serviceLocator()),
  );

  // Presentation (Bloc — une instance par écran)
  serviceLocator.registerFactory<MachinesBloc>(
    () => MachinesBloc(serviceLocator(), serviceLocator()),
  );
}
