import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fotdelsi/app.dart';

import 'firebase_options.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/notifications/presentation/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupLocator();

  final authCubit = serviceLocator<AuthCubit>();
  final router = AppRouter.create(authCubit);

  serviceLocator<PushNotificationService>().init(router);

  runApp(FotDelsiApp(router: router));
}
