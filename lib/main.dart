import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/websocket/ws_connection_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/client_auth/presentation/cubit/client_session_cubit.dart';
import 'features/notifications/presentation/push_notification_service.dart';
import 'features/wash_session/presentation/cubit/wash_session_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupLocator();

  final authCubit = serviceLocator<AuthCubit>();
  final router = AppRouter.create(authCubit);

  // Notifications push : init FCM, permission, enregistrement device si
  // numéro lié, affichage en premier plan, ack + deep-link au tap.
  serviceLocator<PushNotificationService>().init(router);

  runApp(FotDelsiApp(router: router));
}

class FotDelsiApp extends StatelessWidget {
  const FotDelsiApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: serviceLocator<AuthCubit>()),
        BlocProvider<ClientSessionCubit>.value(
          value: serviceLocator<ClientSessionCubit>(),
        ),
        BlocProvider<WsConnectionCubit>(
          create: (_) => serviceLocator<WsConnectionCubit>(),
        ),
        BlocProvider<WashSessionCubit>(
          create: (_) => serviceLocator<WashSessionCubit>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'FOT DELSI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
