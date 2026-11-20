import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending,
  paid,
  failed,
  expired;

  static PaymentStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'settlement':
      case 'completed':
        return PaymentStatus.paid;
      case 'expired':
        return PaymentStatus.expired;
      case 'failed':
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  String get value => name;

  String get label => switch (this) {
    PaymentStatus.pending => 'Menunggu',
    PaymentStatus.paid => 'Berhasil',
    PaymentStatus.failed => 'Gagal',
    PaymentStatus.expired => 'Kedaluwarsa',
  };
}

class OrderItem {
  const OrderItem({
    required this.menuId,
    required this.name,
    this.emoji = '🍽️',
    required this.price,
    required this.quantity,
  });

  final String menuId;
  final String name;
  final String emoji;
  final int price;
  final int quantity;

  int get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'menuId': menuId,
    'name': name,
    'emoji': emoji,
    'price': price,
    'qty': quantity,
    'quantity': quantity, // backward-compat
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuId: (map['menuId'] as String?) ?? '',
      name: (map['name'] as String?) ?? 'Menu',
      emoji: (map['emoji'] as String?) ?? '🍽️',
      price: _toInt(map['price']),
      quantity: _toInt(map['qty'] ?? map['quantity'] ?? 1),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }
}

class Order {
  const Order({
    required this.id,
    required this.code,
    required this.cashierId,
    required this.cashierName,
    required this.items,
    required this.total,
    this.paymentMethod = 'miomipay',
    required this.paymentStatus,
    required this.createdAt,
    this.paymentReference,
    this.paidAt,
  });

  final String id;
  final String code;
  final String cashierId;
  final String cashierName;
  final List<OrderItem> items;
  final int total;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final String? paymentReference;
  final DateTime? paidAt;

  bool get isPaid => paymentStatus == PaymentStatus.paid;

  int get itemCount => items.fold(0, (acc, item) => acc + item.quantity);

  String get paymentMethodLabel => 'QRIS • MiomiPay';

  Order copyWith({
    String? id,
    String? code,
    String? cashierId,
    String? cashierName,
    List<OrderItem>? items,
    int? total,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
    String? paymentReference,
    DateTime? paidAt,
  }) {
    return Order(
      id: id ?? this.id,
      code: code ?? this.code,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      items: items ?? this.items,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      paymentReference: paymentReference ?? this.paymentReference,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'cashierId': cashierId,
    'cashierName': cashierName,
    'items': items.map((item) => item.toMap()).toList(),
    'total': total,
    'paymentMethod': paymentMethod,
    'status': paymentStatus.value,
    'paymentStatus': paymentStatus.value,
    'paymentRef': paymentReference,
    'paymentReference': paymentReference,
    'createdAt': createdAt.toIso8601String(),
    'paidAt': paidAt?.toIso8601String(),
  };

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = map['items'];
    return Order(
      id: id,
      code: (map['code'] as String?) ?? '-',
      cashierId: (map['cashierId'] as String?) ?? '',
      cashierName: (map['cashierName'] as String?) ?? 'Kasir',
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => OrderItem.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      total: _toInt(map['total']),
      paymentMethod: (map['paymentMethod'] as String?) ?? 'miomipay',
      paymentStatus: PaymentStatus.fromValue(
        (map['status'] ?? map['paymentStatus']) as String?,
      ),
      createdAt: _toDate(map['createdAt']),
      paymentReference:
          (map['paymentRef'] ?? map['paymentReference']) as String?,
      paidAt: map['paidAt'] == null ? null : _toDate(map['paidAt']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  static DateTime _toDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
