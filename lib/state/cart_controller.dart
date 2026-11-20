import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => List.unmodifiable(_items.values);

  bool get isEmpty => _items.isEmpty;

  int get count => _items.values.fold(0, (sum, item) => sum + item.quantity);

  int get total =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);

  int quantityOf(String menuId) => _items[menuId]?.quantity ?? 0;

  void add(MenuItem menu) {
    if (!menu.isAvailable) return;
    final current = _items[menu.id];
    _items[menu.id] = current == null
        ? CartItem(menu: menu, quantity: 1)
        : current.copyWith(quantity: current.quantity + 1);
    notifyListeners();
  }

  void increment(String menuId) {
    final current = _items[menuId];
    if (current == null) return;
    _items[menuId] = current.copyWith(quantity: current.quantity + 1);
    notifyListeners();
  }

  void decrement(String menuId) {
    final current = _items[menuId];
    if (current == null) return;
    if (current.quantity <= 1) {
      _items.remove(menuId);
    } else {
      _items[menuId] = current.copyWith(quantity: current.quantity - 1);
    }
    notifyListeners();
  }

  void remove(String menuId) {
    _items.remove(menuId);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
