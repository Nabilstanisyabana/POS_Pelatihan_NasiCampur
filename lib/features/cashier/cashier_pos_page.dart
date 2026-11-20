import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/food_image.dart';
import '../../models/menu_item.dart';
import '../../services/app_services.dart';
import '../../state/cart_controller.dart';
import 'cart_panel.dart';

/// Halaman POS Kasir sesuai PRD Section 4.3, 16, & 18:
/// - POS-01: Daftar menu real-time dari admin, menu "Habis" tampil redup (opasitas 50%) & label "Habis"
/// - POS-02: Tap menu untuk menambah ke keranjang; tap lagi untuk menambah qty
/// - POS-03: Keranjang jelas, subtotal & total
/// - POS-04: Pencarian menu & filter kategori
/// - POS-05: Bar keranjang melayang di bawah: "3 item • Rp 75.000" dan tombol "Lihat Pesanan"
class CashierPosPage extends StatefulWidget {
  const CashierPosPage({super.key});

  @override
  State<CashierPosPage> createState() => _CashierPosPageState();
}

class _CashierPosPageState extends State<CashierPosPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(MenuItem menu) {
    if (!menu.isAvailable) return;
    context.read<CartController>().add(menu);
    HapticFeedback.selectionClick();
  }

  Future<void> _openCartSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetContext) {
        return const FractionallySizedBox(
          heightFactor: 0.85,
          child: CartPanel(inSheet: true),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    final cart = context.watch<CartController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<MenuItem>>(
          stream: services.menus.watchMenus(),
          builder: (context, snapshot) {
            final menus = snapshot.data ?? const <MenuItem>[];
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

            final categories = <String>{'Semua'};
            for (final menu in menus) {
              categories.add(menu.category);
            }
            if (!categories.contains(_category)) {
              _category = 'Semua';
            }

            final filtered = menus.where((menu) {
              final categoryMatch =
                  _category == 'Semua' || menu.category == _category;
              final searchMatch = menu.name.toLowerCase().contains(
                _query.toLowerCase(),
              );
              return categoryMatch && searchMatch;
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                // Grid 2 kolom di HP per PRD Section 16 & 18, responsif di layar lebar
                final columns = isWide ? 3 : 2;

                final gridContent = CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // [ 🔍 Cari menu... ] per PRD Section 18
                            TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              decoration: InputDecoration(
                                hintText: 'Cari menu...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _query = '');
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // (Semua) (Makanan) (Minuman) ... Chips horizontal per PRD Section 16 & 18
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: categories.map((cat) {
                                  final selected = _category == cat;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: selected,
                                      onSelected: (_) =>
                                          setState(() => _category = cat),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: menus.isEmpty
                              ? Icons.restaurant_menu_rounded
                              : Icons.search_off_rounded,
                          title: menus.isEmpty
                              ? 'Menu belum tersedia'
                              : 'Menu tidak ditemukan',
                          message: menus.isEmpty
                              ? 'Minta admin menambahkan menu terlebih dahulu.'
                              : 'Coba kata kunci atau kategori lain.',
                        ),
                      )
                    else
                      // Grid Menu 2 kolom per PRD Section 16 & 18
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          cart.isEmpty ? 16 : 96,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 220,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final menu = filtered[index];
                              return _CashierMenuCard(
                                menu: menu,
                                inCartQuantity: cart.quantityOf(menu.id),
                                onAdd: () => _addToCart(menu),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: gridContent),
                      SizedBox(
                        width: 360,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: const CartPanel(),
                        ),
                      ),
                    ],
                  );
                }

                return Stack(
                  children: [
                    gridContent,
                    // Bar Keranjang Melayang di bagian bawah (PRD Section 16 & 18)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: 16,
                      right: 16,
                      bottom: cart.isEmpty ? -80 : 16,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: cart.isEmpty ? 0 : 1,
                        child: _FloatingCartBar(
                          itemCount: cart.count,
                          total: cart.total,
                          onTap: _openCartSheet,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Kartu Menu (Kasir) sesuai PRD Section 16:
/// - Grid 2 kolom: foto/ikon placeholder di atas, nama (Title), harga (Price) di bawah, tombol + kecil di pojok.
/// - Item ada di keranjang: badge qty berwarna accent (#F59E0B) di pojok kartu.
/// - Menu "Habis": opasitas 50% dan label "Habis", tidak bisa di-tap.
class _CashierMenuCard extends StatelessWidget {
  const _CashierMenuCard({
    required this.menu,
    required this.inCartQuantity,
    required this.onAdd,
  });

  final MenuItem menu;
  final int inCartQuantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isAvailable = menu.isAvailable;

    return Opacity(
      // Opasitas 50% untuk menu habis per PRD Section 16
      opacity: isAvailable ? 1.0 : 0.50,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isAvailable ? onAdd : null, // tidak bisa di-tap jika habis
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto / Ikon placeholder di atas
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FoodImage(
                      imageUrl: menu.imageUrl,
                      emoji: menu.emoji,
                      category: menu.category,
                    ),

                    // Badge Qty berwarna accent (#F59E0B) di pojok kartu (PRD Section 16)
                    if (inCartQuantity > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33F59E0B),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$inCartQuantity',
                            style: AppTypography.caption(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                    // Label "Habis" untuk menu habis (PRD Section 16)
                    if (!isAvailable)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.25),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Habis',
                              style: AppTypography.caption(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bagian bawah: Nama (Title), Harga (Price), dan tombol + kecil
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            menu.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title().copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rupiah(menu.price),
                            style: AppTypography.price(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Tombol + kecil di pojok (PRD Section 16)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? AppColors.primary
                            : AppColors.outline,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: isAvailable ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bar Keranjang (Kasir) sesuai PRD Section 16 & 18:
/// Bar melayang di bagian bawah: "{n} item • Rp {total}" dan tombol "Lihat Pesanan";
/// muncul dengan animasi geser halus saat item pertama ditambahkan.
class _FloatingCartBar extends StatelessWidget {
  const _FloatingCartBar({
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  final int itemCount;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 3 item • Rp 75.000
              Expanded(
                child: Text(
                  '$itemCount item • ${rupiah(total)}',
                  style: AppTypography.label(color: Colors.white).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Tombol Lihat Pesanan
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Lihat Pesanan',
                  style: AppTypography.label(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
