import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_bootstrap.dart';
import 'services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = await AppBootstrap.initialize();
  final services = AppServices.create(
    firebaseReady: bootstrap.firebaseReady,
    firebaseMessage: bootstrap.message,
  );

  runApp(NusaPosApp(services: services));
}
