import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_button.dart';
import '../../models/menu_item.dart';
import '../../services/app_services.dart';

Future<bool> showMenuFormSheet(
  BuildContext context, {
  MenuItem? item,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) => _MenuFormSheet(item: item),
  );
  return result ?? false;
}

class _MenuFormSheet extends StatefulWidget {
  const _MenuFormSheet({this.item});

  final MenuItem? item;

  @override
  State<_MenuFormSheet> createState() => _MenuFormSheetState();
}

class _MenuFormSheetState extends State<_MenuFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageController;

  static const _categories = ['Makanan', 'Minuman', 'Snack', 'Lainnya'];
  static const _emojis = [
    '🍛', '🍜', '🍗', '🍢', '☕', '🍵',
    '🍟', '🍌', '💧', '🍰', '🥤', '🍽️'
  ];

  late String _category;
  late String _emoji;
  late bool _available;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item == null ? '' : '${item.price}',
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _imageController = TextEditingController(text: item?.imageUrl ?? '');
    _category = item?.category ?? 'Makanan';
    if (!_categories.contains(_category)) _category = 'Lainnya';
    _emoji = item?.emoji ?? '🍽️';
    _available = item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final service = context.read<AppServices>().menus;
      final price = int.tryParse(
            _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;

      final now = DateTime.now();
      final menu = MenuItem(
        id: widget.item?.id ?? '',
        name: _nameController.text.trim(),
        category: _category,
        price: price,
        description: _descriptionController.text.trim(),
        emoji: _emoji,
        imageUrl: _imageController.text.trim(),
        isAvailable: _available,
        createdAt: widget.item?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEdit) {
        await service.updateMenu(menu);
      } else {
        await service.createMenu(menu);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Gagal menyimpan menu: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Ubah Menu' : 'Tambah Menu',
                          style: AppTypography.heading2(),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEdit
                              ? 'Perbarui informasi menu di bawah ini.'
                              : 'Isi informasi menu baru untuk kasir.',
                          style: AppTypography.bodyM(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: AppTypography.caption(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Nama Menu (Label di atas field per PRD 16 & MENU-05)
              Text(
                'Nama Menu *',
                style: AppTypography.label().copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Nasi Goreng Spesial',
                  prefixIcon: Icon(Icons.restaurant_rounded, size: 20),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Nama menu wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Harga & Kategori
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Harga
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harga *',
                          style: AppTypography.label().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: '25000',
                            prefixText: 'Rp ',
                            prefixIcon: Icon(Icons.payments_outlined, size: 20),
                          ),
                          validator: (value) {
                            final raw = value?.trim() ?? '';
                            final price = int.tryParse(raw);
                            if (price == null || price <= 0) {
                              return 'Harga harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Kategori
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori',
                          style: AppTypography.label().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.category_outlined, size: 20),
                          ),
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: AppTypography.bodyM()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Switch Status Tersedia
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      _available ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: _available ? AppColors.success : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _available ? 'Menu Tersedia' : 'Menu Habis',
                            style: AppTypography.label().copyWith(
                              fontWeight: FontWeight.w600,
                              color: _available ? AppColors.success : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _available
                                ? 'Dapat dipesan oleh kasir.'
                                : 'Akan ditampilkan redup dan tidak bisa dipesan.',
                            style: AppTypography.caption(),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _available,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primaryContainer,
                      onChanged: (val) => setState(() => _available = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Foto / URL Gambar Opsional
              Text(
                'URL Foto (Opsional)',
                style: AppTypography.label().copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _imageController,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.image_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // Pilih Ikon / Emoji Cadangan
              Text(
                'Ikon Menu',
                style: AppTypography.label().copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojis.map((emoji) {
                  final selected = emoji == _emoji;
                  return InkWell(
                    onTap: () => setState(() => _emoji = emoji),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryContainer
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.outline,
                          width: selected ? 1.8 : 1,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Tombol Simpan (Microcopy 19: Tombol "Simpan", Tinggi 52 dp)
              PrimaryButton(
                text: 'Simpan',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
