import 'package:firebase_core/firebase_core.dart';

import '../core/config/app_config.dart';
import 'demo_store.dart';

class BootstrapResult {
  const BootstrapResult({required this.firebaseReady, this.message});

  final bool firebaseReady;
  final String? message;
}

class AppBootstrap {
  AppBootstrap._();

  static Future<BootstrapResult> initialize() async {
    if (AppConfig.forceDemo) {
      await DemoStore.instance.init();
      return const BootstrapResult(
        firebaseReady: false,
        message: 'Demo Mode diaktifkan lewat --dart-define=USE_DEMO=true.',
      );
    }

    if (!AppConfig.hasFirebaseConfig) {
      await DemoStore.instance.init();
      return const BootstrapResult(
        firebaseReady: false,
        message:
            'Kredensial Firebase belum diisi. Aplikasi berjalan di Demo Mode '
            'dengan data lokal.',
      );
    }

    try {
      await Firebase.initializeApp(options: AppConfig.firebaseOptions);
      return const BootstrapResult(firebaseReady: true);
    } catch (error) {
      await DemoStore.instance.init();
      return BootstrapResult(
        firebaseReady: false,
        message:
            'Gagal terhubung ke Firebase, beralih ke Demo Mode. '
            'Periksa konfigurasi. ($error)',
      );
    }
  }
}
