import 'menu_item.dart';

class CartItem {
  const CartItem({required this.menu, required this.quantity});

  final MenuItem menu;
  final int quantity;

  int get subtotal => menu.price * quantity;

  CartItem copyWith({MenuItem? menu, int? quantity}) {
    return CartItem(
      menu: menu ?? this.menu,
      quantity: quantity ?? this.quantity,
    );
  }
}
