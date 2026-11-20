import 'package:flutter/material.dart';

import '../shared/profile_page.dart';
import 'cashier_history_page.dart';
import 'cashier_pos_page.dart';

/// Kasir Shell sesuai PRD Section 17:
/// Bottom Navigation dengan 3 tab:
/// 1. Kasir (POS)
/// 2. Riwayat
/// 3. Profil
/// Layar pembayaran dibuka sebagai halaman penuh tanpa bottom nav.
class CashierShell extends StatefulWidget {
  const CashierShell({super.key});

  @override
  State<CashierShell> createState() => _CashierShellState();
}

class _CashierShellState extends State<CashierShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          CashierPosPage(),
          CashierHistoryPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded),
            label: 'Kasir',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
