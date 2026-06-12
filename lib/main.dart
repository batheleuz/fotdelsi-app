import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/websocket/ws_connection_cubit.dart';
import 'features/wash_session/presentation/cubit/wash_session_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const FotDelsiApp());
}

class FotDelsiApp extends StatelessWidget {
  const FotDelsiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
        routerConfig: AppRouter.router,
      ),
    );
  }
}
