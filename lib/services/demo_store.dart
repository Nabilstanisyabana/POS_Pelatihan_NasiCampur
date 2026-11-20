import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class DemoAccount {
  DemoAccount({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final String password;
  final UserRole role;

  AppUser toUser() =>
      AppUser(uid: uid, name: name, email: email, role: role);

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'password': password,
    'role': role.value,
  };

  factory DemoAccount.fromMap(Map<String, dynamic> map) {
    return DemoAccount(
      uid: (map['uid'] as String?) ?? 'demo-user',
      name: (map['name'] as String?) ?? 'Pengguna Demo',
      email: (map['email'] as String?) ?? '',
      password: (map['password'] as String?) ?? '',
      role: UserRole.fromValue(map['role'] as String?),
    );
  }
}

/// Penyimpanan lokal untuk Demo Mode.
///
/// Data disimpan di SharedPreferences sehingga perubahan menu dan transaksi
/// tetap ada saat aplikasi dibuka kembali. Mode ini hanya untuk presentasi;
/// password disimpan plain text dan TIDAK boleh dipakai di produksi.
class DemoStore {
  DemoStore._();

  static final DemoStore instance = DemoStore._();

  static const _menusKey = 'nusapos_demo_menus_v2';
  static const _ordersKey = 'nusapos_demo_orders_v2';
  static const _accountsKey = 'nusapos_demo_accounts_v2';
  static const _sessionKey = 'nusapos_demo_session_v2';

  late SharedPreferences _prefs;
  bool _initialized = false;

  final List<MenuItem> _menus = [];
  final List<Order> _orders = [];
  final Map<String, DemoAccount> _accounts = {};

  final _menuController = StreamController<List<MenuItem>>.broadcast();
  final _orderController = StreamController<List<Order>>.broadcast();

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadAccounts();
    _loadMenus();
    _loadOrders();
    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  Future<AppUser> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw AppException('Email atau password salah. Coba lagi ya.');
    }
    await _prefs.setString(_sessionKey, account.email);
    return account.toUser();
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final normalized = email.trim().toLowerCase();
    if (_accounts.containsKey(normalized)) {
      throw AppException('Email sudah terdaftar. Silakan login.');
    }
    final account = DemoAccount(
      uid: 'demo-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalized,
      password: password,
      role: role,
    );
    _accounts[normalized] = account;
    await _prefs.setString(_accountsKey, jsonEncode(_accounts.values.map((e) => e.toMap()).toList()));
    await _prefs.setString(_sessionKey, normalized);
    return account.toUser();
  }

  Future<AppUser?> restoreSession() async {
    final email = _prefs.getString(_sessionKey);
    if (email == null) return null;
    final account = _accounts[email];
    return account?.toUser();
  }

  Future<void> signOut() async {
    await _prefs.remove(_sessionKey);
  }

  // ---------------------------------------------------------------------------
  // Menu
  // ---------------------------------------------------------------------------
  Stream<List<MenuItem>> watchMenus() async* {
    yield List<MenuItem>.unmodifiable(_menus);
    yield* _menuController.stream;
  }

  Future<MenuItem> createMenu(MenuItem item) async {
    final created = item.copyWith(
      id: 'menu-${DateTime.now().microsecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _menus.insert(0, created);
    _emitMenus();
    await _persistMenus();
    return created;
  }

  Future<void> updateMenu(MenuItem item) async {
    final index = _menus.indexWhere((menu) => menu.id == item.id);
    if (index == -1) throw AppException('Menu tidak ditemukan.');
    _menus[index] = item;
    _emitMenus();
    await _persistMenus();
  }

  Future<void> deleteMenu(String id) async {
    _menus.removeWhere((menu) => menu.id == id);
    _emitMenus();
    await _persistMenus();
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------
  Stream<List<Order>> watchOrders() async* {
    yield List<Order>.unmodifiable(_orders);
    yield* _orderController.stream;
  }

  Future<Order> createOrder(Order order) async {
    final created = order.copyWith(
      id: 'order-${DateTime.now().microsecondsSinceEpoch}',
    );
    _orders.insert(0, created);
    _emitOrders();
    await _persistOrders();
    return created;
  }

  Future<void> updateOrder(Order order) async {
    final index = _orders.indexWhere((item) => item.id == order.id);
    if (index == -1) return;
    _orders[index] = order;
    _emitOrders();
    await _persistOrders();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------
  void _loadAccounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            if (item is Map) {
              final account = DemoAccount.fromMap(
                Map<String, dynamic>.from(item),
              );
              _accounts[account.email] = account;
            }
          }
        }
      } catch (_) {
        _accounts.clear();
      }
    }
    if (_accounts.isEmpty) {
      for (final account in _seedAccounts()) {
        _accounts[account.email] = account;
      }
      unawaited(
        _prefs.setString(
          _accountsKey,
          jsonEncode(_accounts.values.map((e) => e.toMap()).toList()),
        ),
      );
    }
  }

  void _loadMenus() {
    final raw = _prefs.getString(_menusKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          _menus
            ..clear()
            ..addAll(
              list.whereType<Map>().map(
                (item) => MenuItem.fromMap(
                  (item['id'] as String?) ?? '',
                  Map<String, dynamic>.from(item),
                ),
              ),
            );
        }
      } catch (_) {
        _menus.clear();
      }
    }
    if (_menus.isEmpty) {
      _menus.addAll(_seedMenus());
      unawaited(_persistMenus());
    }
  }

  void _loadOrders() {
    final raw = _prefs.getString(_ordersKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          _orders
            ..clear()
            ..addAll(
              list.whereType<Map>().map(
                (item) => Order.fromMap(
                  (item['id'] as String?) ?? '',
                  Map<String, dynamic>.from(item),
                ),
              ),
            );
        }
      } catch (_) {
        _orders.clear();
      }
    }
    if (_orders.isEmpty) {
      _orders.addAll(_seedOrders());
      unawaited(_persistOrders());
    }
  }

  Future<void> _persistMenus() async {
    final payload = _menus
        .map((menu) => {'id': menu.id, ...menu.toMap()})
        .toList();
    await _prefs.setString(_menusKey, jsonEncode(payload));
  }

  Future<void> _persistOrders() async {
    final payload = _orders
        .map((order) => {'id': order.id, ...order.toMap()})
        .toList();
    await _prefs.setString(_ordersKey, jsonEncode(payload));
  }

  void _emitMenus() => _menuController.add(List.unmodifiable(_menus));

  void _emitOrders() => _orderController.add(List.unmodifiable(_orders));

  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------
  List<DemoAccount> _seedAccounts() => [
    DemoAccount(
      uid: 'demo-admin',
      name: 'Nadia Admin',
      email: 'admin@nusapos.id',
      password: 'admin123',
      role: UserRole.admin,
    ),
    DemoAccount(
      uid: 'demo-kasir',
      name: 'Raka Kasir',
      email: 'kasir@nusapos.id',
      password: 'kasir123',
      role: UserRole.kasir,
    ),
  ];

  List<MenuItem> _seedMenus() {
    final now = DateTime.now();
    return [
      MenuItem(
        id: 'menu-nasi-goreng',
        name: 'Nasi Goreng Spesial',
        category: 'Makanan',
        price: 28000,
        description: 'Nasi goreng kampung dengan telur mata sapi, ayam, dan kerupuk.',
        emoji: '🍛',
        imageUrl:
            'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80',
        isAvailable: true,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      MenuItem(
        id: 'menu-mie-ayam',
        name: 'Mie Ayam Bakso',
        category: 'Makanan',
        price: 25000,
        description: 'Mie ayam gurih dengan bakso sapi dan pangsit renyah.',
        emoji: '🍜',
        imageUrl:
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80',
        isAvailable: true,
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      MenuItem(
        id: 'menu-ayam-geprek',
        name: 'Ayam Geprek Sambal Ijo',
        category: 'Makanan',
        price: 32000,
        description: 'Ayam crispy digeprek sambal ijo pedas, nasi hangat, dan lalapan.',
        emoji: '🍗',
        imageUrl:
            'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=900&q=80',
        isAvailable: true,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      MenuItem(
        id: 'menu-sate-ayam',
        name: 'Sate Ayam Madura',
        category: 'Makanan',
        price: 35000,
        description: '10 tusuk sate ayam dengan bumbu kacang legit dan lontong.',
        emoji: '🍢',
        imageUrl:
            'https://images.unsplash.com/photo-1529042410759-befb1204b468?auto=format&fit=crop&w=900&q=80',
        isAvailable: true,
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      MenuItem(
        id: 'menu-kopi-susu',
        name: 'Es Kopi Susu Gula Aren',
        category: 'Minuman',
        price: 22000,
        description: 'Espresso house blend, susu segar, dan gula aren asli.',
        emoji: '☕',
        imageUrl:
            'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=900&q=80',
        isAvailable: true,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      MenuItem(
        id: 'menu-matcha',
        name: 'Matcha Latte',
        category: 'Minuman',
        price: 26000,
        description: 'Matcha Jepang premium dengan susu creamy dan es batu.',
        emoji: '🍵',
        imageUrl:
            'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?auto=format&fit=crop&w=900&q=80',
        isAvailable: true,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      MenuItem(
        id: 'menu-kentang',
        name: 'Kentang Goreng',
        category: 'Snack',
        price: 18000,
        description: 'Kentang goreng renyah dengan saus mayo dan sambal.',
        emoji: '🍟',
        imageUrl:
            'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=900&q=80',
        isAvailable: true,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      MenuItem(
        id: 'menu-pisang',
        name: 'Pisang Goreng Keju',
        category: 'Snack',
        price: 17000,
        description: 'Pisang goreng hangat dengan topping keju dan susu kental.',
        emoji: '🍌',
        imageUrl:
            'https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&w=900&q=80',
        isAvailable: false,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      MenuItem(
        id: 'menu-air',
        name: 'Air Mineral',
        category: 'Minuman',
        price: 8000,
        description: 'Air mineral dingin 600 ml.',
        emoji: '💧',
        imageUrl: '',
        isAvailable: true,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }

  List<Order> _seedOrders() {
    final now = DateTime.now();
    final menus = _seedMenus();
    OrderItem item(String id, int qty) {
      final menu = menus.firstWhere((menu) => menu.id == id);
      return OrderItem(
        menuId: menu.id,
        name: menu.name,
        emoji: menu.emoji,
        price: menu.price,
        quantity: qty,
      );
    }

    final first = now.subtract(const Duration(hours: 2, minutes: 12));
    final second = now.subtract(const Duration(hours: 4, minutes: 5));
    final third = now.subtract(const Duration(days: 1, hours: 3));
    final fourth = now.subtract(const Duration(days: 2, hours: 1));

    return [
      Order(
        id: 'order-seed-1',
        code: 'INV-${_codeStamp(first)}-001',
        cashierId: 'demo-kasir',
        cashierName: 'Raka Kasir',
        items: [item('menu-nasi-goreng', 1), item('menu-kopi-susu', 2)],
        total: 28000 + (22000 * 2),
        paymentMethod: 'qris',
        paymentStatus: PaymentStatus.paid,
        createdAt: first,
        paidAt: first.add(const Duration(minutes: 2)),
        paymentReference: 'MIOMI-DEMO-001',
      ),
      Order(
        id: 'order-seed-2',
        code: 'INV-${_codeStamp(second)}-002',
        cashierId: 'demo-kasir',
        cashierName: 'Raka Kasir',
        items: [item('menu-ayam-geprek', 2), item('menu-kentang', 1)],
        total: (32000 * 2) + 18000,
        paymentMethod: 'qris',
        paymentStatus: PaymentStatus.paid,
        createdAt: second,
        paidAt: second.add(const Duration(minutes: 1)),
        paymentReference: 'MIOMI-DEMO-002',
      ),
      Order(
        id: 'order-seed-3',
        code: 'INV-${_codeStamp(third)}-003',
        cashierId: 'demo-kasir',
        cashierName: 'Raka Kasir',
        items: [item('menu-mie-ayam', 1), item('menu-matcha', 1)],
        total: 25000 + 26000,
        paymentMethod: 'cash',
        paymentStatus: PaymentStatus.paid,
        createdAt: third,
        paidAt: third.add(const Duration(minutes: 3)),
      ),
      Order(
        id: 'order-seed-4',
        code: 'INV-${_codeStamp(fourth)}-004',
        cashierId: 'demo-kasir',
        cashierName: 'Raka Kasir',
        items: [item('menu-sate-ayam', 2), item('menu-air', 1)],
        total: (35000 * 2) + 8000,
        paymentMethod: 'qris',
        paymentStatus: PaymentStatus.paid,
        createdAt: fourth,
        paidAt: fourth.add(const Duration(minutes: 2)),
        paymentReference: 'MIOMI-DEMO-004',
      ),
    ];
  }

  static String _codeStamp(DateTime date) {
    final year = date.year.toString().substring(2);
    return '$year${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
