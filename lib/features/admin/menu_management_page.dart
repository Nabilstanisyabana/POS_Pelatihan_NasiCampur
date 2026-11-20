import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/food_image.dart';
import '../../models/menu_item.dart';
import '../../services/app_services.dart';
import 'menu_form_sheet.dart';

/// Halaman Kelola Menu Admin sesuai PRD Section 4.2 & 16 & 18:
/// - MENU-01: Tambah menu
/// - MENU-02: Daftar menu real-time dengan pencarian dan chip filter kategori
/// - MENU-03: Update ubah menu
/// - MENU-04: Delete menu dengan dialog konfirmasi
/// - MENU-05: Validasi form nama wajib, harga > 0
/// - MENU-06: Toggle "Tersedia / Habis" langsung dari daftar
/// - MENU-07: Undo (snackbar) setelah hapus
/// - Baris Menu: List 1 kolom: thumbnail kecil, nama, kategori, harga, switch Tersedia, menu titik tiga
class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({MenuItem? item}) async {
    final saved = await showMenuFormSheet(context, item: item);
    if (!saved || !mounted) return;
    _toast(item == null ? 'Menu baru berhasil ditambahkan.' : 'Menu diperbarui.');
  }

  Future<void> _delete(MenuItem item) async {
    // Dialog Konfirmasi sesuai PRD Section 16 & 19
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus menu?'),
        content: const Text('Menu ini akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final services = context.read<AppServices>();
    try {
      await services.menus.deleteMenu(item.id);
      if (!mounted) return;

      // Undo snackbar (MENU-07)
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${item.name} dihapus.'),
            action: SnackBarAction(
              label: 'Urungkan',
              textColor: AppColors.accent,
              onPressed: () async {
                try {
                  await services.menus.restoreMenu(item);
                } catch (_) {}
              },
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      _toast('Gagal menghapus menu: $error', error: true);
    }
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    try {
      await context
          .read<AppServices>()
          .menus
          .updateMenu(item.copyWith(isAvailable: !item.isAvailable));
      if (!mounted) return;
      _toast(
        item.isAvailable
            ? '${item.name} ditandai habis.'
            : '${item.name} kembali tersedia.',
      );
    } catch (error) {
      if (!mounted) return;
      _toast('Gagal mengubah status menu: $error', error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.textPrimary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();

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

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Judul halaman
                            Text('Kelola Menu', style: AppTypography.heading1()),
                            const SizedBox(height: 4),
                            Text(
                              '${menus.length} menu tersimpan • perubahan real-time ke kasir.',
                              style: AppTypography.bodyM(),
                            ),
                            const SizedBox(height: 16),

                            // Search Bar per PRD 18: [ 🔍 Cari menu... ]
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

                            // Chip Kategori per PRD 16 & 18: (Semua) (Makanan) (Minuman) ...
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
                            const SizedBox(height: 12),

                            // Info ringkas
                            Row(
                              children: [
                                Text(
                                  '${filtered.length} menu',
                                  style: AppTypography.label().copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• ${menus.where((m) => m.isAvailable).length} tersedia',
                                  style: AppTypography.caption(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
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
                          ? 'Belum ada menu'
                          : 'Menu tidak ditemukan',
                      message: menus.isEmpty
                          ? 'Belum ada menu. Tambah menu pertama'
                          : 'Coba kata kunci atau kategori lain.',
                      actionLabel: menus.isEmpty ? 'Tambah Menu' : null,
                      onAction: menus.isEmpty ? () => _openForm() : null,
                    ),
                  )
                else
                  // List 1 kolom Baris Menu (Admin) sesuai PRD Section 16 & 18:
                  // [img] Nasi Goreng      Rp 20.000  ⏺ Tersedia  ⋮
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final menu = filtered[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _AdminMenuRow(
                                  menu: menu,
                                  onEdit: () => _openForm(item: menu),
                                  onDelete: () => _delete(menu),
                                  onToggleAvailability: () =>
                                      _toggleAvailability(menu),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      // FAB "+ Tambah Menu" di tab Menu per PRD Section 17 & 18
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Menu'),
      ),
    );
  }
}

/// Baris Menu (Admin) sesuai PRD Section 16:
/// List satu kolom: thumbnail kecil, nama (Title), kategori (Caption), harga (Price),
/// switch Tersedia, menu titik tiga (Edit, Hapus).
class _AdminMenuRow extends StatelessWidget {
  const _AdminMenuRow({
    required this.menu,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  final MenuItem menu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Thumbnail kecil
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: FoodImage(
                  imageUrl: menu.imageUrl,
                  emoji: menu.emoji,
                  category: menu.category,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nama & Kategori
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    menu.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title(),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(menu.category, style: AppTypography.caption()),
                      const SizedBox(width: 6),
                      Text('•', style: AppTypography.caption()),
                      const SizedBox(width: 6),
                      Text(
                        rupiah(menu.price),
                        style: AppTypography.price(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Switch Tersedia (MENU-06: Toggle langsung dari daftar)
            Tooltip(
              message: menu.isAvailable ? 'Tersedia' : 'Habis',
              child: Switch(
                value: menu.isAvailable,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryContainer,
                onChanged: (_) => onToggleAvailability(),
              ),
            ),

            // Menu titik tiga (Edit, Hapus)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hapus',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
