
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fotdelsi/core/connectivity/connectivity_cubit.dart';
import 'package:fotdelsi/core/connectivity/offline_banner.dart';
import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_theme.dart';
import 'package:fotdelsi/core/websocket/ws_connection_cubit.dart';
import 'package:fotdelsi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fotdelsi/features/client_auth/presentation/cubit/client_session_cubit.dart';
import 'package:fotdelsi/features/notifications/presentation/push_notification_service.dart';
import 'package:fotdelsi/features/service_status/presentation/cubit/service_status_cubit.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_session_cubit.dart';
import 'package:go_router/go_router.dart';

class FotDelsiApp extends StatefulWidget {
  const FotDelsiApp({super.key, required this.router});

  final GoRouter router;

  @override
  State<FotDelsiApp> createState() => _FotDelsiAppState();
}

class _FotDelsiAppState extends State<FotDelsiApp>
    with WidgetsBindingObserver {
  final ServiceStatusCubit _serviceStatus = serviceLocator<ServiceStatusCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Démarre l'interrogation de /status (immédiate + périodique).
    _serviceStatus.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Rafraîchit la disponibilité des services.
      _serviceStatus.refresh();
      // Re-tente l'enregistrement du device FCM : couvre le cas où le jeton
      // n'était pas encore prêt au moment de la liaison (install fraîche) →
      // plus besoin de redémarrer l'app.
      serviceLocator<PushNotificationService>().registerDeviceIfLinked();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: serviceLocator<AuthCubit>()),
        BlocProvider<ClientSessionCubit>.value(
          value: serviceLocator<ClientSessionCubit>(),
        ),
        BlocProvider<ServiceStatusCubit>.value(value: _serviceStatus),
        BlocProvider<WsConnectionCubit>(
          create: (_) => serviceLocator<WsConnectionCubit>(),
        ),
        BlocProvider<ConnectivityCubit>.value(
          value: serviceLocator<ConnectivityCubit>(),
        ),
        BlocProvider<WashSessionCubit>(
          create: (_) => serviceLocator<WashSessionCubit>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'FOT DELSI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: widget.router,
        // Bandeau « hors ligne » global, posé au-dessus de toutes les pages.
        builder: (context, child) => Stack(
          children: [
            ?child,
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: OfflineBanner(),
            ),
          ],
        ),
      ),
    );
  }
}
