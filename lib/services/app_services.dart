import '../core/config/app_config.dart';
import 'auth_service.dart';
import 'demo_store.dart';
import 'menu_service.dart';
import 'miomipay_service.dart';
import 'order_service.dart';

class AppServices {
  AppServices({
    required this.auth,
    required this.menus,
    required this.orders,
    required this.payments,
    required this.demoMode,
    this.firebaseMessage,
  });

  final AuthService auth;
  final MenuService menus;
  final OrderService orders;
  final MiomiPayService payments;
  final bool demoMode;
  final String? firebaseMessage;

  bool get isFirebaseReady => !demoMode;

  bool get isPaymentSimulated => payments.isSimulated;

  String get modeLabel => demoMode ? 'Demo Mode' : 'Firebase Live';

  String get paymentLabel =>
      isPaymentSimulated ? 'MiomiPay Simulator' : 'MiomiPay Live';

  static AppServices create({
    required bool firebaseReady,
    String? firebaseMessage,
  }) {
    if (firebaseReady) {
      return AppServices(
        auth: FirebaseAuthService(),
        menus: FirestoreMenuService(),
        orders: FirestoreOrderService(),
        payments: MiomiPayService(
          simulate: !AppConfig.hasMiomiPayConfig,
          proxyOnly: AppConfig.miomiPayUseBackend,
        ),
        demoMode: false,
        firebaseMessage: firebaseMessage,
      );
    }

    final store = DemoStore.instance;
    return AppServices(
      auth: DemoAuthService(store),
      menus: DemoMenuService(store),
      orders: DemoOrderService(store),
      payments: MiomiPayService(
        simulate: !AppConfig.hasMiomiPayConfig,
        proxyOnly: AppConfig.miomiPayUseBackend,
      ),
      demoMode: true,
      firebaseMessage: firebaseMessage,
    );
  }
}
