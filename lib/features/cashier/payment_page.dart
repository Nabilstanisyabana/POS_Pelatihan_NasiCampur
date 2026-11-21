import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/order.dart';
import '../../models/payment_intent.dart';
import '../../services/app_services.dart';
import '../../state/cart_controller.dart';
import '../shared/receipt_sheet.dart';

/// Layar Pembayaran MiomiPay & Layar Sukses sesuai PRD Section 6 (Layar 7 & 8), 8, 16, 17, 18, 19:
/// - Layar penuh tanpa bottom navigation (Section 17)
/// - Menampilkan detail tagihan, QR/link, status, countdown (Layar 7)
/// - Integrasi Sandbox Simulator MiomiPay (Buka langsung / Salin Snap Token)
/// - Status real-time: Menunggu, Berhasil, Gagal/Kedaluwarsa (POS-06)
/// - Layar sukses dengan ringkasan & tombol "Pesanan Baru" (POS-08)
class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.order,
    required this.intent,
  });

  final Order order;
  final PaymentIntent intent;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Timer? _countdownTimer;
  Timer? _pollTimer;
  bool _paid = false;
  bool _checking = false;
  bool _failed = false;
  bool _allowPop = false;
  String? _statusMessage;
  Order? _paidOrder;
  int _secondsLeft = 0;

  DateTime get _expiresAt =>
      widget.intent.expiresAt ??
      widget.order.createdAt.add(const Duration(minutes: 15));

  bool get _expired => _secondsLeft <= 0 && !_paid;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _remainingSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paid) return;
      final remaining = _remainingSeconds;
      if (remaining != _secondsLeft) {
        setState(() => _secondsLeft = remaining);
      }
      if (remaining <= 0) {
        _pollTimer?.cancel();
        _markExpired();
      }
    });

    if (!widget.intent.isSimulated) {
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _checkStatus(silent: true);
      });
    }
  }

  int get _remainingSeconds {
    final remaining = _expiresAt.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_paid || _checking) return;
    setState(() {
      _checking = true;
      if (!silent) _statusMessage = null;
    });

    try {
      final services = context.read<AppServices>();
      final status = await services.payments.checkStatus(
        widget.intent.reference,
      );
      if (!mounted) return;
      final normalized = PaymentStatus.fromValue(status);
      if (normalized == PaymentStatus.paid) {
        await _completePayment();
        return;
      }
      if (normalized == PaymentStatus.failed ||
          normalized == PaymentStatus.expired) {
        setState(() {
          _failed = true;
          _statusMessage = 'Pembayaran gagal atau sudah kedaluwarsa.';
        });
        return;
      }
      if (!silent) {
        setState(
          () => _statusMessage =
              'Pembayaran belum diterima. Selesaikan scan lalu cek lagi.',
        );
      }
    } catch (error) {
      if (!silent && mounted) {
        setState(() => _statusMessage = 'Gagal mengecek status: $error');
      }
    } finally {
      if (mounted && !_paid) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _simulatePayment() async {
    if (_paid || _checking) return;
    setState(() {
      _checking = true;
      _statusMessage = null;
    });
    try {
      final services = context.read<AppServices>();
      await services.payments.simulateSuccess(widget.intent.reference);
      final status = await services.payments.checkStatus(
        widget.intent.reference,
      );
      if (!mounted) return;
      if (PaymentStatus.fromValue(status) == PaymentStatus.paid) {
        await _completePayment();
      } else {
        setState(
          () => _statusMessage = 'Simulasi belum berhasil. Coba lagi.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Simulasi gagal: $error');
    } finally {
      if (mounted && !_paid) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _completePayment() async {
    if (_paid) return;
    final services = context.read<AppServices>();
    final now = DateTime.now();
    final paidOrder = widget.order.copyWith(
      paymentStatus: PaymentStatus.paid,
      paymentReference: widget.intent.reference,
      paidAt: now,
    );

    try {
      await services.orders.markPaid(
        widget.order.id,
        paymentReference: widget.intent.reference,
        paidAt: now,
      );
    } catch (_) {}

    if (!mounted) return;
    context.read<CartController>().clear();
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    setState(() {
      _paid = true;
      _checking = false;
      _paidOrder = paidOrder;
      _statusMessage = null;
    });
  }

  Future<void> _markExpired() async {
    try {
      await context.read<AppServices>().orders.markExpired(widget.order.id);
    } catch (_) {}
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan transaksi?'),
        content: const Text(
          'QR akan kedaluwarsa dan pesanan ini akan dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Lanjutkan Bayar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _requestClose() async {
    if (_paid) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await _confirmLeave();
    if (!leave || !mounted) return;
    try {
      await context.read<AppServices>().orders.markFailed(widget.order.id);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _allowPop = true);
    await Future<void>.delayed(Duration.zero);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openPaymentUrl() async {
    final url = widget.intent.paymentUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openSimulator() async {
    final url = widget.intent.simulatorUrl ??
        'https://pg.miomidev.com/sandbox/simulator';
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyText(String text, String label) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$label berhasil disalin.'),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Gagal menyalin $label: $error'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  String get _countdown {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Layar Sukses (PRD Section 6 Layar 8 & POS-08)
    if (_paid && _paidOrder != null) {
      return _PaymentSuccessView(
        order: _paidOrder!,
        onNewOrder: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      );
    }

    final invoiceCode = widget.intent.invoiceNumber ?? widget.order.code;
    final snapToken = widget.intent.snapToken;

    return PopScope(
      canPop: _paid || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestClose();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Pembayaran MiomiPay'),
          leading: IconButton(
            onPressed: _requestClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Peringatan jika koneksi API MiomiPay ditolak / offline
                    if (widget.intent.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFB45309),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Peringatan Kredensial MiomiPay',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Server merespons: ${widget.intent.errorMessage}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Aplikasi dialihkan ke Simulasi Offline internal NusaPOS. Agar dapat diuji di Sandbox Simulator MiomiPay online, pastikan API Key berstatus "Active" di dashboard https://pg.miomidev.com.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Kartu Total Tagihan & Countdown
                    Card(
                      elevation: 0,
                      color: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: AppTypography.caption(
                                color: Colors.white70,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              rupiah(widget.order.total),
                              style: AppTypography.display(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _expired
                                      ? 'Waktu Pembayaran Habis'
                                      : 'Sisa Waktu: $_countdown',
                                  style: AppTypography.caption(
                                    color: Colors.white,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      invoiceCode,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _copyText(
                                    invoiceCode,
                                    'Kode Invoice',
                                  ),
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: const Text('Salin'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kartu QRIS MiomiPay
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.outline),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StatusBadge(
                                  status: _expired
                                      ? PaymentStatus.expired
                                      : (_failed
                                          ? PaymentStatus.failed
                                          : PaymentStatus.pending),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Scan QRIS untuk Membayar',
                              style: AppTypography.title(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.intent.isSimulated
                                  ? 'Mode Sandbox Simulator NusaPOS'
                                  : 'Mendukung GoPay, OVO, Dana, BCA, dan bank lainnya.',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption(),
                            ),
                            const SizedBox(height: 16),
                            _QrBox(
                              intent: widget.intent,
                              expired: _expired,
                              onOpenUrl: _openPaymentUrl,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ID Referensi: ${widget.intent.reference}',
                              style: AppTypography.caption(),
                            ),
                            if (snapToken != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Token: $snapToken',
                                    style: AppTypography.caption(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Salin Snap Token',
                                    onPressed: () => _copyText(
                                      snapToken,
                                      'Snap Token',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pesan status
                    if (_statusMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _failed
                              ? AppColors.errorSoft
                              : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _failed
                                  ? Icons.error_outline_rounded
                                  : Icons.info_outline_rounded,
                              size: 18,
                              color: _failed
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: AppTypography.caption(
                                  color: _failed
                                      ? AppColors.error
                                      : AppColors.primary,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Tombol Buka Sandbox Simulator MiomiPay
                    FilledButton.icon(
                      onPressed: _openSimulator,
                      icon: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      label: const Text(
                        'Buka Simulator MiomiPay',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE600),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tombol Aksi Simulasi Lokal (jika API offline / mode simulasi)
                    if (widget.intent.isSimulated) ...[
                      PrimaryButton(
                        text: 'Simulasikan Pembayaran Berhasil (Offline)',
                        icon: Icons.check_circle_outline_rounded,
                        loading: _checking,
                        onPressed: (_checking || _expired)
                            ? null
                            : _simulatePayment,
                      ),
                      const SizedBox(height: 10),
                    ],

                    SecondaryButton(
                      text: 'Cek Status Pembayaran',
                      icon: Icons.refresh_rounded,
                      onPressed: _checking ? null : () => _checkStatus(),
                    ),
                    const SizedBox(height: 10),

                    if (widget.intent.paymentUrl != null) ...[
                      OutlinedButton.icon(
                        onPressed: _openPaymentUrl,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Buka Link Pembayaran'),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Tombol Batalkan Transaksi
                    TextButton(
                      onPressed: _requestClose,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Batalkan Transaksi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrBox extends StatelessWidget {
  const _QrBox({
    required this.intent,
    required this.expired,
    required this.onOpenUrl,
  });

  final PaymentIntent intent;
  final bool expired;
  final VoidCallback onOpenUrl;

  @override
  Widget build(BuildContext context) {
    Widget qrWidget;
    if (intent.qrString != null && intent.qrString!.isNotEmpty) {
      qrWidget = QrImageView(
        data: intent.qrString!,
        version: QrVersions.auto,
        size: 200,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
      );
    } else if (intent.qrImageUrl != null && intent.qrImageUrl!.isNotEmpty) {
      qrWidget = Image.network(
        intent.qrImageUrl!,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const _QrPlaceholder(),
      );
    } else {
      qrWidget = const _QrPlaceholder();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: expired ? 0.25 : 1, child: qrWidget),
        if (expired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error),
            ),
            child: Text(
              'KEDALUWARSA',
              style: AppTypography.caption(
                color: AppColors.error,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 56,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 6),
          Text('QR Code MiomiPay', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Layar Sukses Pembayaran sesuai PRD Section 6 (Layar 8), POS-08 & Microcopy 19:
/// - Display total pembayaran
/// - Status Berhasil: "Pembayaran berhasil!"
/// - Ringkasan pesanan
/// - Tombol primer: "Pesanan Baru" (kembali ke POS, reset keranjang)
class _PaymentSuccessView extends StatelessWidget {
  const _PaymentSuccessView({required this.order, required this.onNewOrder});

  final Order order;
  final VoidCallback onNewOrder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ikon centang hijau besar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.successSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Teks: Pembayaran berhasil! (Microcopy 19)
                  Text(
                    'Pembayaran berhasil!',
                    textAlign: TextAlign.center,
                    style: AppTypography.heading1(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pesanan telah tercatat di sistem.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyM(),
                  ),
                  const SizedBox(height: 24),

                  // Ringkasan Pembayaran
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.outline),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Display Total (PRD Section 14)
                          Text(
                            rupiah(order.total),
                            style: AppTypography.display(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(order.code, style: AppTypography.caption()),
                          const Divider(height: 24),
                          _DetailRow(
                            label: 'Metode Pembayaran',
                            value: 'QRIS • MiomiPay',
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Kasir', value: order.cashierName),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Waktu',
                            value: dateTimeLabel(
                              order.paidAt ?? DateTime.now(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Jumlah Item',
                            value: '${order.itemCount} item',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Pesanan Baru (Microcopy 19)
                  PrimaryButton(
                    text: 'Pesanan Baru',
                    icon: Icons.add_rounded,
                    onPressed: onNewOrder,
                  ),
                  const SizedBox(height: 10),

                  // Tombol Lihat Struk
                  OutlinedButton.icon(
                    onPressed: () => showReceiptSheet(context, order),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Lihat Struk'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyM()),
        Text(
          value,
          style: AppTypography.bodyM(
            color: AppColors.textPrimary,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
