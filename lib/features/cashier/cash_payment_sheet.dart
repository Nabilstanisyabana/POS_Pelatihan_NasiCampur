import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/gradient_button.dart';

Future<int?> showCashPaymentSheet(
  BuildContext context, {
  required int total,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 500),
    builder: (context) => _CashPaymentSheet(total: total),
  );
}

class _CashPaymentSheet extends StatefulWidget {
  const _CashPaymentSheet({required this.total});

  final int total;

  @override
  State<_CashPaymentSheet> createState() => _CashPaymentSheetState();
}

class _CashPaymentSheetState extends State<_CashPaymentSheet> {
  final _controller = TextEditingController();
  int _received = 0;

  List<int> get _quickAmounts {
    final values = <int>{widget.total, 50000, 100000, 200000, 500000};
    return values.where((value) => value >= widget.total).take(4).toList()
      ..sort();
  }

  int get _change => _received - widget.total;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    _controller.text = '$amount';
    setState(() => _received = amount);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: AppColors.mint,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembayaran tunai',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Total tagihan ${rupiah(widget.total)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              onChanged: (value) => setState(
                () => _received = int.tryParse(value) ?? 0,
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.ink,
              ),
              decoration: const InputDecoration(
                labelText: 'Uang diterima',
                hintText: '0',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.wallet_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                final selected = _received == amount;
                return ChoiceChip(
                  label: Text(rupiah(amount)),
                  selected: selected,
                  onSelected: (_) => _setAmount(amount),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _received == 0
                    ? AppColors.background
                    : (_change >= 0
                          ? AppColors.mintSoft
                          : AppColors.dangerSoft),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    _received == 0
                        ? Icons.calculate_outlined
                        : (_change >= 0
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded),
                    size: 19,
                    color: _received == 0
                        ? AppColors.muted
                        : (_change >= 0
                              ? AppColors.mint
                              : AppColors.danger),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _received == 0
                          ? 'Masukkan nominal uang yang diterima.'
                          : (_change >= 0
                                ? 'Kembalian'
                                : 'Uang masih kurang'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _received == 0
                            ? AppColors.muted
                            : (_change >= 0
                                  ? AppColors.mint
                                  : AppColors.danger),
                      ),
                    ),
                  ),
                  if (_received > 0)
                    Text(
                      rupiah(_change.abs()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _change >= 0
                            ? AppColors.mint
                            : AppColors.danger,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Konfirmasi pembayaran',
              icon: Icons.check_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF19C6A3), Color(0xFF0EA47F)],
              ),
              onPressed: _change >= 0 && _received > 0
                  ? () => Navigator.of(context).pop(_received)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
