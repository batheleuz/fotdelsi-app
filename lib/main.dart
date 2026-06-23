import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/websocket/ws_connection_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/client_auth/presentation/cubit/client_session_cubit.dart';
import 'features/wash_session/presentation/cubit/wash_session_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // Le profil démarre en `unknown` : le SplashScreen reste affiché et
  // déclenche `bootstrap()` (restauration de session), puis le routeur
  // redirige vers la bonne destination.
  final authCubit = serviceLocator<AuthCubit>();

  runApp(FotDelsiApp(router: AppRouter.create(authCubit)));
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
