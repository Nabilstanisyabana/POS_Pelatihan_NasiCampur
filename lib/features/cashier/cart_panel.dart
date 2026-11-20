import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_code.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/food_image.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../models/order.dart';
import '../../services/app_services.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import 'payment_page.dart';

/// Review Pesanan / Keranjang sesuai PRD Section 4.3 & 16:
/// - List item pesanan
/// - Qty stepper (40 dp, minus di qty 1 memunculkan ikon hapus)
/// - Subtotal & Total
/// - Tombol: "Bayar dengan MiomiPay"
class CartPanel extends StatefulWidget {
  const CartPanel({
    super.key,
    this.inSheet = false,
    this.onCheckoutSuccess,
  });

  final bool inSheet;
  final VoidCallback? onCheckoutSuccess;

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  bool _busy = false;

  Future<void> _clearCart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: const Text('Semua item di keranjang akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CartController>().clear();
    }
  }

  Future<void> _processPayment() async {
    final cart = context.read<CartController>();
    if (cart.isEmpty || _busy) return;

    final user = context.read<AuthController>().user;
    if (user == null) return;
    final services = context.read<AppServices>();

    setState(() => _busy = true);

    try {
      final orderCode = generateOrderCode();
      final orderItems = cart.items
          .map(
            (item) => OrderItem(
              menuId: item.menu.id,
              name: item.menu.name,
              emoji: item.menu.emoji,
              price: item.menu.price,
              quantity: item.quantity,
            ),
          )
          .toList();

      final order = Order(
        id: '',
        code: orderCode,
        cashierId: user.uid,
        cashierName: user.name,
        items: orderItems,
        total: cart.total,
        paymentMethod: 'miomipay',
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime.now(),
      );

      // Simpan transaksi status pending ke Firestore (POS-07, PRD 8)
      // Jika Firebase terkendala, tetap lanjutkan agar flow kasir tidak macet
      Order savedOrder;
      try {
        savedOrder = await services.orders.createOrder(order);
      } catch (err) {
        debugPrint('[Orders] Firestore write error, continuing locally: $err');
        savedOrder = order.copyWith(
          id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Inisiasi tagihan pembayaran MiomiPay (Otomatis beralih ke Sandbox Simulator jika CORS / offline)
      final intent = await services.payments.createQrisPayment(order: savedOrder);

      if (!mounted) return;
      setState(() => _busy = false);

      // Jika dibuka di modal bottom sheet, tutup sheet terlebih dahulu
      if (widget.inSheet) {
        Navigator.of(context).pop();
      }
      widget.onCheckoutSuccess?.call();

      // Navigasi ke Layar Pembayaran penuh tanpa bottom nav (PRD Section 17)
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentPage(order: savedOrder, intent: intent),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memulai transaksi: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: widget.inSheet
          ? null
          : BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
      child: Column(
        children: [
          if (widget.inSheet)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          // Header Keranjang
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
            child: Row(
              children: [
                Text(
                  'Review Pesanan',
                  style: AppTypography.heading2().copyWith(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${cart.count} item',
                    style: AppTypography.caption(
                      color: AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  TextButton(
                    onPressed: () => _clearCart(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Kosongkan'),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: cart.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Keranjang kosong',
                    message: 'Tap menu pada daftar untuk menambahkan pesanan.',
                    compact: true,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: FoodImage(
                                  imageUrl: item.menu.imageUrl,
                                  emoji: item.menu.emoji,
                                  category: item.menu.category,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.menu.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.title().copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rupiah(item.menu.price),
                                    style: AppTypography.caption(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Qty stepper 40 dp (PRD 16)
                            QuantityStepper(
                              quantity: item.quantity,
                              compact: true,
                              onDecrement: () => cart.decrement(item.menu.id),
                              onIncrement: () => cart.increment(item.menu.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (!cart.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.outline)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Total Pesanan', style: AppTypography.bodyM()),
                      const Spacer(),
                      Text(
                        rupiah(cart.total),
                        style: AppTypography.price(
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Tombol Bayar dengan MiomiPay (Tinggi 52 dp, lebar penuh)
                  PrimaryButton(
                    text: 'Bayar dengan MiomiPay',
                    icon: Icons.qr_code_rounded,
                    loading: _busy,
                    onPressed: _busy ? null : _processPayment,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
