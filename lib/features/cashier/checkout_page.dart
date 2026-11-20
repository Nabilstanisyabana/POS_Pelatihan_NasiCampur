import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_code.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../models/payment_intent.dart';
import '../../services/app_services.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../shared/receipt_sheet.dart';
import 'cash_payment_sheet.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final List<CartItem> _items;
  late final int _total;
  late final String _code;

  String _method = 'qris';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartController>();
    _items = List<CartItem>.of(cart.items);
    _total = cart.total;
    _code = generateOrderCode();
  }

  List<OrderItem> get _orderItems => _items
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

  Future<void> _pay() async {
    if (_busy) return;
    if (_method == 'qris') {
      await _payWithQris();
    } else {
      await _payWithCash();
    }
  }

  Future<void> _payWithQris() async {
    final user = context.read<AuthController>().user;
    if (user == null) return;
    final services = context.read<AppServices>();
    setState(() => _busy = true);

    try {
      final order = Order(
        id: '',
        code: _code,
        cashierId: user.uid,
        cashierName: user.name,
        items: _orderItems,
        total: _total,
        paymentMethod: 'qris',
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime.now(),
      );
      final saved = await services.orders.createOrder(order);

      late final PaymentIntent intent;
      try {
        intent = await services.payments.createQrisPayment(order: saved);
      } catch (error) {
        try {
          await services.orders.markFailed(saved.id);
        } catch (_) {
          // Abaikan kegagalan update status; error utama tetap ditampilkan.
        }
        rethrow;
      }

      if (!mounted) return;
      setState(() => _busy = false);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentPage(order: saved, intent: intent),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Gagal membuat pembayaran QRIS.\n$error');
    }
  }

  Future<void> _payWithCash() async {
    final cash = await showCashPaymentSheet(context, total: _total);
    if (cash == null || !mounted) return;

    final user = context.read<AuthController>().user;
    if (user == null) return;
    final services = context.read<AppServices>();
    setState(() => _busy = true);

    try {
      final now = DateTime.now();
      final order = Order(
        id: '',
        code: _code,
        cashierId: user.uid,
        cashierName: user.name,
        items: _orderItems,
        total: _total,
        paymentMethod: 'cash',
        paymentStatus: PaymentStatus.paid,
        createdAt: now,
        paidAt: now,
        paymentReference: 'CASH-$_code',
      );
      final saved = await services.orders.createOrder(order);
      if (!mounted) return;
      context.read<CartController>().clear();
      setState(() => _busy = false);

      final action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _CashSuccessDialog(
          order: saved,
          cashReceived: cash,
          change: cash - _total,
        ),
      );
      if (!mounted) return;

      if (action == 'receipt') {
        await showReceiptSheet(context, saved);
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Gagal menyimpan transaksi tunai.\n$error');
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Transaksi gagal'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembayaran')),
        body: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Keranjang kosong',
          message: 'Tambahkan menu terlebih dahulu sebelum checkout.',
          action: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali ke kasir'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        leading: IconButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 860;
                  final summary = _OrderSummaryCard(
                    code: _code,
                    items: _items,
                    total: _total,
                  );
                  final payment = _PaymentCard(
                    method: _method,
                    busy: _busy,
                    total: _total,
                    simulated: services.isPaymentSimulated,
                    onMethodChanged: (value) =>
                        setState(() => _method = value),
                    onPay: _pay,
                  );

                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summary,
                        const SizedBox(height: 14),
                        payment,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: summary),
                      const SizedBox(width: 16),
                      SizedBox(width: 400, child: payment),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.code,
    required this.items,
    required this.total,
  });

  final String code;
  final List<CartItem> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Periksa kembali pesanan pelanggan.',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.menu.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.menu.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.quantity} x ${rupiah(item.menu.price)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    rupiah(item.subtotal),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 18),
          Row(
            children: [
              const Text(
                'Total pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                rupiah(total),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.method,
    required this.busy,
    required this.total,
    required this.simulated,
    required this.onMethodChanged,
    required this.onPay,
  });

  final String method;
  final bool busy;
  final int total;
  final bool simulated;
  final ValueChanged<String> onMethodChanged;
  final Future<void> Function() onPay;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Metode pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Pilih cara pelanggan membayar.',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          _MethodCard(
            selected: method == 'qris',
            icon: Icons.qr_code_2_rounded,
            title: 'QRIS • MiomiPay',
            subtitle: 'Scan QR dari aplikasi bank / e-wallet.',
            badge: simulated ? 'Simulator' : 'Rekomendasi',
            accent: AppColors.primary,
            background: AppColors.primarySoft,
            onTap: busy ? null : () => onMethodChanged('qris'),
          ),
          const SizedBox(height: 10),
          _MethodCard(
            selected: method == 'cash',
            icon: Icons.payments_rounded,
            title: 'Tunai',
            subtitle: 'Terima uang cash dan hitung kembalian.',
            accent: AppColors.mint,
            background: AppColors.mintSoft,
            onTap: busy ? null : () => onMethodChanged('cash'),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  rupiah(total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: method == 'qris'
                ? 'Bayar dengan QRIS'
                : 'Bayar tunai',
            icon: method == 'qris'
                ? Icons.qr_code_scanner_rounded
                : Icons.payments_outlined,
            loading: busy,
            onPressed: busy ? null : onPay,
          ),
          const SizedBox(height: 10),
          Text(
            method == 'qris'
                ? (simulated
                      ? 'MiomiPay belum dikonfigurasi. QR simulasi akan dibuat untuk demo.'
                      : 'QR dibuat melalui MiomiPay dan status dicek otomatis.')
                : 'Pastikan uang sudah diterima sebelum menyelesaikan transaksi.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.background,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color background;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? background.withValues(alpha: 0.55) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.white,
                border: Border.all(
                  color: selected ? accent : AppColors.border,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CashSuccessDialog extends StatelessWidget {
  const _CashSuccessDialog({
    required this.order,
    required this.cashReceived,
    required this.change,
  });

  final Order order;
  final int cashReceived;
  final int change;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.mint,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pembayaran berhasil',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.code,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _MoneyRow(label: 'Total belanja', value: rupiah(order.total)),
                const SizedBox(height: 7),
                _MoneyRow(label: 'Uang diterima', value: rupiah(cashReceived)),
                const Divider(height: 18),
                _MoneyRow(
                  label: 'Kembalian',
                  value: rupiah(change),
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('receipt'),
          child: const Text('Lihat struk'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop('done'),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 15 : 12,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.mint : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
