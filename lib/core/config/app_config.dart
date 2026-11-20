import 'package:firebase_core/firebase_core.dart';

/// Konfigurasi aplikasi NusaPOS.
///
/// Nilai sensitif diambil dari `--dart-define` agar aman dan fleksibel.
///
/// Contoh menjalankan dengan kredensial MiomiPay Sandbox:
/// flutter run -d chrome \
///   --dart-define=MIOMIPAY_API_KEY=MP-SB-xxxx \
///   --dart-define=MIOMIPAY_WEBHOOK_SECRET=xxxx
class AppConfig {
  AppConfig._();

  static const String appName = 'NusaPOS';
  static const String appVersion = '1.0.0';
  static const String storeName = String.fromEnvironment(
    'STORE_NAME',
    defaultValue: 'Nusa Eatery',
  );
  static const String storeAddress = String.fromEnvironment(
    'STORE_ADDRESS',
    defaultValue: 'Jl. Merdeka No. 88, Bandung',
  );

  // ---------------------------------------------------------------------------
  // Firebase
  // ---------------------------------------------------------------------------
  static const String _firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String _firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String _firebaseSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String _firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String _firebaseMeasurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );

  /// Paksa aplikasi berjalan dalam mode demo lokal (tanpa Firebase).
  static const bool forceDemo = bool.fromEnvironment('USE_DEMO');

  static bool get hasFirebaseConfig =>
      !forceDemo &&
      _firebaseApiKey.isNotEmpty &&
      _firebaseAppId.isNotEmpty &&
      _firebaseProjectId.isNotEmpty;

  static FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: _firebaseApiKey,
    appId: _firebaseAppId,
    messagingSenderId: _firebaseSenderId,
    projectId: _firebaseProjectId,
    authDomain: _firebaseAuthDomain.isNotEmpty
        ? _firebaseAuthDomain
        : '$_firebaseProjectId.firebaseapp.com',
    storageBucket: _firebaseStorageBucket.isNotEmpty
        ? _firebaseStorageBucket
        : '$_firebaseProjectId.appspot.com',
    measurementId: _firebaseMeasurementId.isNotEmpty
        ? _firebaseMeasurementId
        : null,
  );

  // ---------------------------------------------------------------------------
  // MiomiPay Gateway (Sesuai Dokumentasi Resmi)
  // Base URL: https://pg.miomidev.com/api/v1
  // ---------------------------------------------------------------------------
  static const String miomiPayBaseUrl = String.fromEnvironment(
    'MIOMIPAY_BASE_URL',
    defaultValue: 'https://pg.miomidev.com/api/v1',
  );

  /// API Key MiomiPay (Prefix MP-SB- untuk Sandbox, MP-LIVE- untuk Produksi).
  static const String miomiPayApiKey = String.fromEnvironment(
    'MIOMIPAY_API_KEY',
  );

  /// Webhook Secret untuk validasi HMAC-SHA256 signature.
  static const String miomiPayWebhookSecret = String.fromEnvironment(
    'MIOMIPAY_WEBHOOK_SECRET',
  );

  static const String miomiPayCreatePath = String.fromEnvironment(
    'MIOMIPAY_CREATE_PATH',
    defaultValue: '/payment/create',
  );

  static const String miomiPayStatusPath = String.fromEnvironment(
    'MIOMIPAY_STATUS_PATH',
    defaultValue: '/payment/{id}/status',
  );

  static const String miomiPaySuccessUrl = String.fromEnvironment(
    'MIOMIPAY_SUCCESS_URL',
    defaultValue: 'https://pg.miomidev.com/pay/success',
  );

  /// Menentukan apakah MiomiPay sudah dikonfigurasi dengan API Key.
  /// Jika belum, aplikasi berjalan otomatis dalam mode Simulator Sandbox.
  static bool get hasMiomiPayConfig => miomiPayApiKey.isNotEmpty;

  static String get createPaymentUrl =>
      '${_trimSlash(miomiPayBaseUrl)}$miomiPayCreatePath';

  static String statusPaymentUrl(String reference) =>
      '${_trimSlash(miomiPayBaseUrl)}${miomiPayStatusPath.replaceAll('{id}', reference)}';

  static String _trimSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
