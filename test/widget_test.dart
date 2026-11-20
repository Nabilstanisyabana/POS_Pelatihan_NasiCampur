import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_communication/core/utils/formatters.dart';
import 'package:realtime_communication/core/utils/order_code.dart';
import 'package:realtime_communication/models/menu_item.dart';
import 'package:realtime_communication/models/order.dart';

void main() {
  group('format rupiah', () {
    test('memformat ribuan dengan titik', () {
      expect(rupiah(0), 'Rp 0');
      expect(rupiah(8000), 'Rp 8.000');
      expect(rupiah(250000), 'Rp 250.000');
      expect(rupiah(1250000), 'Rp 1.250.000');
    });

    test('memformat nilai ringkas', () {
      expect(compactRupiah(1250000), 'Rp 1,3 jt');
      expect(compactRupiah(25000), 'Rp 25 rb');
    });
  });

  group('model menu', () {
    test('mapping bolak-balik tetap konsisten', () {
      final menu = MenuItem(
        id: 'menu-1',
        name: 'Nasi Goreng',
        category: 'Makanan',
        price: 28000,
        description: 'Enak',
        emoji: '🍛',
        imageUrl: '',
        isAvailable: true,
        createdAt: DateTime(2026, 1, 2, 10, 30),
      );

      final restored = MenuItem.fromMap(menu.id, menu.toMap());

      expect(restored.name, menu.name);
      expect(restored.price, 28000);
      expect(restored.category, 'Makanan');
      expect(restored.isAvailable, isTrue);
      expect(restored.createdAt, menu.createdAt);
    });
  });

  group('model order', () {
    test('mapping order dan item berjalan', () {
      final order = Order(
        id: 'order-1',
        code: 'INV-260102-101500',
        cashierId: 'kasir-1',
        cashierName: 'Raka',
        items: const [
          OrderItem(
            menuId: 'menu-1',
            name: 'Nasi Goreng',
            emoji: '🍛',
            price: 28000,
            quantity: 2,
          ),
        ],
        total: 56000,
        paymentMethod: 'qris',
        paymentStatus: PaymentStatus.paid,
        createdAt: DateTime(2026, 1, 2, 10, 15),
        paymentReference: 'MIOMI-1',
        paidAt: DateTime(2026, 1, 2, 10, 16),
      );

      final restored = Order.fromMap(order.id, order.toMap());

      expect(restored.code, order.code);
      expect(restored.total, 56000);
      expect(restored.itemCount, 2);
      expect(restored.isPaid, isTrue);
      expect(restored.paymentMethodLabel, contains('QRIS'));
    });
  });

  test('kode order mengikuti format INV', () {
    final code = generateOrderCode(DateTime(2026, 1, 2, 10, 15, 30, 45));
    expect(code, startsWith('INV-260102-101530'));
  });
}
