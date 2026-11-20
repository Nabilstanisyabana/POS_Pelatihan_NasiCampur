import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item.dart';
import 'demo_store.dart';

abstract class MenuService {
  Stream<List<MenuItem>> watchMenus();

  Future<MenuItem> createMenu(MenuItem item);

  Future<void> updateMenu(MenuItem item);

  Future<void> deleteMenu(String id);

  Future<void> restoreMenu(MenuItem item);
}

class DemoMenuService implements MenuService {
  DemoMenuService(this._store);

  final DemoStore _store;

  @override
  Stream<List<MenuItem>> watchMenus() => _store.watchMenus();

  @override
  Future<MenuItem> createMenu(MenuItem item) => _store.createMenu(item);

  @override
  Future<void> updateMenu(MenuItem item) => _store.updateMenu(item);

  @override
  Future<void> deleteMenu(String id) => _store.deleteMenu(id);

  @override
  Future<void> restoreMenu(MenuItem item) => _store.createMenu(item);
}

class FirestoreMenuService implements MenuService {
  FirestoreMenuService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _menus =>
      _firestore.collection('menus');

  @override
  Stream<List<MenuItem>> watchMenus() {
    return _menus
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MenuItem.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<MenuItem> createMenu(MenuItem item) async {
    final now = DateTime.now();
    final data = item.toMap();
    data['createdAt'] = now.toIso8601String();
    data['updatedAt'] = now.toIso8601String();
    final reference = await _menus.add(data);
    return item.copyWith(id: reference.id, createdAt: now, updatedAt: now);
  }

  @override
  Future<void> updateMenu(MenuItem item) async {
    final now = DateTime.now();
    await _menus.doc(item.id).update({
      'name': item.name,
      'category': item.category,
      'price': item.price,
      'description': item.description,
      'emoji': item.emoji,
      'imageUrl': item.imageUrl,
      'isAvailable': item.isAvailable,
      'updatedAt': now.toIso8601String(),
    });
  }

  @override
  Future<void> deleteMenu(String id) => _menus.doc(id).delete();

  @override
  Future<void> restoreMenu(MenuItem item) async {
    final data = item.toMap();
    data['updatedAt'] = DateTime.now().toIso8601String();
    if (item.id.isNotEmpty) {
      await _menus.doc(item.id).set(data);
    } else {
      await _menus.add(data);
    }
  }
}
