import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fotdelsi/core/auth/auth_token_store.dart';
import 'package:fotdelsi/core/auth/client_session_store.dart';
import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/core/network/auth_interceptor.dart';
import 'package:fotdelsi/features/auth/data/datasources/auth_api_data_source.dart';
import 'package:fotdelsi/features/client_auth/data/datasources/client_auth_api_data_source.dart';
import 'package:fotdelsi/features/client_auth/data/repositories/client_auth_repository_impl.dart';
import 'package:fotdelsi/features/client_auth/domain/repositories/client_auth_repository.dart';
import 'package:fotdelsi/features/client_auth/presentation/cubit/client_session_cubit.dart';
import 'package:fotdelsi/features/client_auth/presentation/cubit/link_phone_cubit.dart';
import 'package:fotdelsi/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fotdelsi/features/auth/domain/repositories/auth_repository.dart';
import 'package:fotdelsi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fotdelsi/features/dropoffs/data/datasources/drop_off_api_data_source.dart';
import 'package:fotdelsi/features/dropoffs/data/repositories/drop_off_repository_impl.dart';
import 'package:fotdelsi/features/dropoffs/domain/repositories/drop_off_repository.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/agent_queue_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/assign_machine_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/drop_off_detail_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/drop_off_search_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/my_dropoffs_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/new_dropoff_cubit.dart';
import 'package:fotdelsi/core/websocket/realtime_socket.dart';
import 'package:fotdelsi/core/websocket/ws_connection_cubit.dart';
import 'package:fotdelsi/features/machines/data/datasources/machine_realtime_data_source.dart';
import 'package:fotdelsi/features/machines/data/datasources/machine_socket_data_source.dart';
import 'package:fotdelsi/features/payment/data/datasources/customer_profile_local_data_source.dart';
import 'package:fotdelsi/features/payment/data/datasources/payment_api_data_source.dart';
import 'package:fotdelsi/features/payment/data/repositories/customer_profile_repository_impl.dart';
import 'package:fotdelsi/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:fotdelsi/features/payment/domain/repositories/customer_profile_repository.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:fotdelsi/features/payment/presentation/bloc/scan_bloc.dart';
import 'package:fotdelsi/features/wash_session/data/datasources/wash_session_api_data_source.dart';
import 'package:fotdelsi/features/wash_session/data/datasources/wash_session_local_data_source.dart';
import 'package:fotdelsi/features/wash_session/data/datasources/wash_session_socket_data_source.dart';
import 'package:fotdelsi/features/wash_session/data/repositories/wash_session_repository_impl.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_session_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/machines/data/datasources/machine_api_data_source.dart';
import '../../features/machines/data/datasources/machine_remote_data_source.dart';
import '../../features/machines/data/repositories/machine_repository_impl.dart';
import '../../features/machines/domain/repositories/machine_repository.dart';
import '../../features/machines/presentation/bloc/machines_bloc.dart';
import '../network/dio_client.dart';

/// Conteneur d'injection de dépendances unique de l'application.
final GetIt serviceLocator = GetIt.instance;

Future<void> setupLocator() async {
  // --- Core ---
  serviceLocator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  serviceLocator.registerLazySingleton<AuthTokenStore>(
    () => AuthTokenStore(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<ClientSessionStore>(
    () => ClientSessionStore(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<Dio>(() {
    final dio = DioClient.create();
    dio.interceptors.add(
      AuthInterceptor(
        serviceLocator<AuthTokenStore>(),
        serviceLocator<ClientSessionStore>(),
        ApiEndpoints.baseUrl,
      ),
    );
    return dio;
  });
  serviceLocator.registerLazySingleton<WsConnectionCubit>(
    () => WsConnectionCubit(),
  );
  // Connexion temps réel partagée — une seule socket pour toute l'app.
  serviceLocator.registerLazySingleton<RealtimeSocket>(() => RealtimeSocket());

  // SharedPreferences — instance partagée
  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(prefs);

  // --- Features ---
  _registerAuth();
  _registerClientAuth();
  _registerDropOffs();
  _registerMachines();
  _registerPayment();
  _registerWashSession();
}

void _registerClientAuth() {
  serviceLocator.registerLazySingleton<ClientAuthApiDataSource>(
    () => ClientAuthApiDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<ClientAuthRepository>(
    () => ClientAuthRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  // Singleton global : état « numéro lié » observé par l'accueil.
  serviceLocator.registerLazySingleton<ClientSessionCubit>(
    () => ClientSessionCubit(serviceLocator()),
  );
  // Factory : une instance par parcours de liaison.
  serviceLocator.registerFactory<LinkPhoneCubit>(
    () => LinkPhoneCubit(serviceLocator()),
  );
}

void _registerDropOffs() {
  serviceLocator.registerLazySingleton<DropOffApiDataSource>(
    () => DropOffApiDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<DropOffRepository>(
    () => DropOffRepositoryImpl(serviceLocator()),
  );
  // Factory : un cubit par ouverture de l'écran file d'attente.
  serviceLocator.registerFactory<AgentQueueCubit>(
    () => AgentQueueCubit(serviceLocator()),
  );
  // Factory : un cubit par ouverture de l'assistant nouveau dépôt.
  serviceLocator.registerFactory<NewDropOffCubit>(
    () => NewDropOffCubit(
      serviceLocator(), // DropOffRepository
      serviceLocator(), // PaymentRepository
      serviceLocator(), // MachineRepository
    ),
  );
  serviceLocator.registerFactory<DropOffDetailCubit>(
    () => DropOffDetailCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<AssignMachineCubit>(
    () => AssignMachineCubit(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerFactory<DropOffSearchCubit>(
    () => DropOffSearchCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<MyDropOffsCubit>(
    () => MyDropOffsCubit(serviceLocator()),
  );
}

void _registerAuth() {
  serviceLocator.registerLazySingleton<AuthApiDataSource>(
    () => AuthApiDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  // Singleton global : pilote le routage par rôle pour toute l'app.
  serviceLocator.registerLazySingleton<AuthCubit>(
    () => AuthCubit(serviceLocator()),
  );
}

void _registerMachines() {
  serviceLocator.registerLazySingleton<MachineRealtimeDataSource>(
    () => MachineSocketDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<MachineApiDataSource>(
    () => MachineApiDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<MachineRemoteDataSource>(
    () => const MachineRemoteDataSource(),
  );
  serviceLocator.registerLazySingleton<MachineRepository>(
    () => MachineRepositoryImpl(serviceLocator(), serviceLocator()),
  );

  serviceLocator.registerFactory<MachinesBloc>(
    () => MachinesBloc(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerFactory<ScanBloc>(() => ScanBloc(serviceLocator()));
}

void _registerPayment() {
  serviceLocator.registerLazySingleton<PaymentApiDataSource>(
    () => PaymentApiDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<CustomerProfileLocalDataSource>(
    () => CustomerProfileLocalDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<CustomerProfileRepository>(
    () => CustomerProfileRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerFactory<PaymentBloc>(
    () => PaymentBloc(
      serviceLocator(), // PaymentRepository
      serviceLocator(), // CustomerProfileRepository
      serviceLocator(), // WashSessionCubit
    ),
  );
}

void _registerWashSession() {
  // Data — local (SharedPreferences), distant (REST) et temps réel (WebSocket).
  serviceLocator.registerLazySingleton<WashSessionLocalDataSource>(
    () => WashSessionLocalDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<WashSessionApiDataSource>(
    () => WashSessionApiDataSource(serviceLocator()), // Dio
  );
  serviceLocator.registerLazySingleton<WashSessionSocketDataSource>(
    () => WashSessionSocketDataSource(serviceLocator()), // RealtimeSocket
  );
  serviceLocator.registerLazySingleton<WashSessionRepository>(
    () => WashSessionRepositoryImpl(
      serviceLocator(), // WashSessionLocalDataSource
      serviceLocator(), // WashSessionApiDataSource
      serviceLocator(), // WashSessionSocketDataSource
    ),
  );

  // Presentation — singleton global
  serviceLocator.registerLazySingleton<WashSessionCubit>(
    () => WashSessionCubit(serviceLocator()), // WashSessionRepository
  );
}
