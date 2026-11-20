import 'package:cloud_firestore/cloud_firestore.dart'
    show CollectionReference, FirebaseFirestore;

import '../models/order.dart';
import 'demo_store.dart';

abstract class OrderService {
  Stream<List<Order>> watchOrders({int limit = 200});

  Future<Order> createOrder(Order order);

  Future<void> markPaid(
    String id, {
    required String paymentReference,
    required DateTime paidAt,
  });

  Future<void> markFailed(String id);

  Future<void> markExpired(String id);
}

class DemoOrderService implements OrderService {
  DemoOrderService(this._store);

  final DemoStore _store;

  @override
  Stream<List<Order>> watchOrders({int limit = 200}) => _store.watchOrders();

  @override
  Future<Order> createOrder(Order order) => _store.createOrder(order);

  @override
  Future<void> markPaid(
    String id, {
    required String paymentReference,
    required DateTime paidAt,
  }) async {
    final orders = await _store.watchOrders().first;
    final index = orders.indexWhere((order) => order.id == id);
    if (index == -1) return;
    await _store.updateOrder(
      orders[index].copyWith(
        paymentStatus: PaymentStatus.paid,
        paymentReference: paymentReference,
        paidAt: paidAt,
      ),
    );
  }

  @override
  Future<void> markFailed(String id) async {
    final orders = await _store.watchOrders().first;
    final index = orders.indexWhere((order) => order.id == id);
    if (index == -1) return;
    await _store.updateOrder(
      orders[index].copyWith(paymentStatus: PaymentStatus.failed),
    );
  }

  @override
  Future<void> markExpired(String id) async {
    final orders = await _store.watchOrders().first;
    final index = orders.indexWhere((order) => order.id == id);
    if (index == -1) return;
    await _store.updateOrder(
      orders[index].copyWith(paymentStatus: PaymentStatus.expired),
    );
  }
}

class FirestoreOrderService implements OrderService {
  FirestoreOrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  @override
  Stream<List<Order>> watchOrders({int limit = 200}) {
    return _orders
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Order.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<Order> createOrder(Order order) async {
    final data = order.toMap();
    data['createdAt'] = DateTime.now().toIso8601String();
    final reference = await _orders.add(data);
    return order.copyWith(id: reference.id);
  }

  @override
  Future<void> markPaid(
    String id, {
    required String paymentReference,
    required DateTime paidAt,
  }) async {
    await _orders.doc(id).update({
      'status': PaymentStatus.paid.value,
      'paymentStatus': PaymentStatus.paid.value,
      'paymentRef': paymentReference,
      'paymentReference': paymentReference,
      'paidAt': paidAt.toIso8601String(),
    });
  }

  @override
  Future<void> markFailed(String id) async {
    await _orders.doc(id).update({
      'status': PaymentStatus.failed.value,
      'paymentStatus': PaymentStatus.failed.value,
    });
  }

  @override
  Future<void> markExpired(String id) async {
    await _orders.doc(id).update({
      'status': PaymentStatus.expired.value,
      'paymentStatus': PaymentStatus.expired.value,
    });
  }
}
