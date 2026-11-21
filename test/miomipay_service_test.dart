import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realtime_communication/models/order.dart';
import 'package:realtime_communication/services/miomipay_service.dart';

void main() {
  test(
    'backend-only mode reports backend failures without simulator fallback',
    () async {
      var requestCount = 0;
      final service = MiomiPayService(
        simulate: false,
        proxyOnly: true,
        client: MockClient((_) async {
          requestCount++;
          return http.Response('{"message":"Unauthorized"}', 401);
        }),
      );
      addTearDown(service.dispose);

      final order = Order(
        id: '',
        code: 'MP-INV-20261121091521000000',
        cashierId: 'cashier-1',
        cashierName: 'Kasir',
        items: const [],
        total: 10000,
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime(2026, 11, 21),
      );

      await expectLater(
        service.createQrisPayment(order: order),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('HTTP 401'),
          ),
        ),
      );
      expect(requestCount, 1);
    },
  );
}
