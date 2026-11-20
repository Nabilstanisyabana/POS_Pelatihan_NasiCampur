import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'services/app_services.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';

class NusaPosApp extends StatelessWidget {
  const NusaPosApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: services),
        ChangeNotifierProvider(
          create: (_) => AuthController(services.auth)..restoreSession(),
        ),
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: MaterialApp(
        title: 'NusaPOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        scrollBehavior: const _AppScrollBehavior(),
        home: const AuthGate(),
      ),
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
