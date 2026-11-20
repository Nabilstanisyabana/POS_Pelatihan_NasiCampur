import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../models/order.dart';
import '../models/payment_intent.dart';

/// Service Integrasi Pembayaran MiomiPay Gateway:
/// Mendukung 3 mode:
/// 1. Backend Proxy (http://localhost:3000/api/payment/create) - Bebas CORS & Aman
/// 2. Direct API (https://pg.miomidev.com/api/v1/payment/create)
/// 3. Sandbox Simulator Fallback (Jika API offline/CORS, otomatis muncul QR simulator)
class MiomiPayService {
  MiomiPayService({
    bool? simulate,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : isSimulated = simulate ?? !AppConfig.hasMiomiPayConfig,
       _client = client ?? http.Client();

  final bool isSimulated;
  final Duration timeout;
  final http.Client _client;

  final Set<String> _simulatedPaid = {};

  /// Backend lokal default untuk proxy bebas CORS
  static String get _localBackendUrl {
    if (kIsWeb) return 'http://localhost:3000/api/payment';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/payment';
    }
    return 'http://localhost:3000/api/payment';
  }

  /// Membuat transaksi tagihan QRIS ke MiomiPay.
  /// Jika terjadi kendala jaringan atau CORS pada Flutter Web,
  /// otomatis dialihkan ke Sandbox Simulator agar pengujian kasir tidak terhenti.
  Future<PaymentIntent> createQrisPayment({required Order order}) async {
    // 1. Jika mode simulasi aktif secara eksplisit
    if (isSimulated) {
      return _generateSimulatorIntent(order);
    }

    // 2. Coba request via Backend Proxy (Express server.js) terlebih dahulu (Bebas CORS)
    try {
      final backendResponse = await _client
          .post(
            Uri.parse('$_localBackendUrl/create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'external_id': order.code,
              'amount': order.total,
              'customer_name': 'Pelanggan - ${order.code}',
              'customer_email': 'kasir@nusapos.id',
              'customer_phone': '081234567890',
              'description': 'Pembayaran POS ${order.code} - ${AppConfig.storeName}',
              'success_redirect_url': AppConfig.miomiPaySuccessUrl,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (backendResponse.statusCode >= 200 && backendResponse.statusCode < 300) {
        final decoded = jsonDecode(backendResponse.body);
        final data = decoded['data'] ?? decoded;
        return _parseIntent(data, order, isSim: false);
      }
    } catch (_) {
      // Backend lokal tidak aktif, lanjutkan ke Direct API
    }

    // 3. Coba Direct API ke https://pg.miomidev.com/api/v1/payment/create
    try {
      final payload = {
        'external_id': order.code,
        'amount': order.total,
        'customer_name': 'Pelanggan - ${order.code}',
        'customer_email': 'kasir@nusapos.id',
        'customer_phone': '081234567890',
        'description': 'Pembayaran POS ${order.code} - ${AppConfig.storeName}',
        'success_redirect_url': AppConfig.miomiPaySuccessUrl,
      };

      final response = await _client
          .post(
            Uri.parse(AppConfig.createPaymentUrl),
            headers: {
              'Authorization': 'Bearer ${AppConfig.miomiPayApiKey}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'] ?? decoded;
        return _parseIntent(data, order, isSim: false);
      } else {
        debugPrint('[MiomiPay API Error] Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('[MiomiPay Direct Connection Error (CORS/Network)]: $e');
    }

    // 4. Fallback ke Sandbox Simulator agar kasir tetap bisa melakukan simulasi pembayaran
    return _generateSimulatorIntent(order);
  }

  PaymentIntent _generateSimulatorIntent(Order order) {
    return PaymentIntent(
      reference: 'MP-SB-SIM-${order.code}',
      status: 'pending',
      isSimulated: true,
      qrString:
          '00020101021226660014ID.CO.GOPAY.WWW0118936009143000000000520458125303360540${order.total}5802ID5911${AppConfig.storeName}6007BANDUNG62190115${order.code}6304',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  PaymentIntent _parseIntent(dynamic data, Order order, {required bool isSim}) {
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final reference = _stringOf(map, ['reference', 'reference_id', 'id'], fallback: order.code)!;
    final qrString = _stringOf(map, ['qr_string', 'qris', 'qr_code']);
    final qrImageUrl = _stringOf(map, ['qr_image_url', 'qr_url']);
    final checkoutUrl = _stringOf(map, ['checkout_url', 'payment_url', 'redirect_url']);

    return PaymentIntent(
      reference: reference,
      status: (_stringOf(map, ['status']) ?? 'pending').toLowerCase(),
      isSimulated: isSim,
      qrString: qrString,
      qrImageUrl: qrImageUrl,
      paymentUrl: checkoutUrl,
      expiresAt: _dateOf(map, ['expires_at', 'expired_at']) ??
          DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  /// Cek status transaksi pembayaran
  Future<String> checkStatus(String reference) async {
    if (isSimulated || reference.startsWith('MP-SB-SIM-')) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return _simulatedPaid.contains(reference) ? 'paid' : 'pending';
    }

    // Coba via Backend Proxy
    try {
      final backendRes = await _client.get(
        Uri.parse('$_localBackendUrl/$reference/status'),
      ).timeout(const Duration(seconds: 4));

      if (backendRes.statusCode == 200) {
        final decoded = jsonDecode(backendRes.body);
        final data = decoded['data'] ?? decoded;
        final rawStatus = _stringOf(data, ['status', 'payment_status']) ?? 'pending';
        return rawStatus.toLowerCase();
      }
    } catch (_) {}

    // Coba Direct API
    try {
      final response = await _client
          .get(
            Uri.parse(AppConfig.statusPaymentUrl(reference)),
            headers: {
              'Authorization': 'Bearer ${AppConfig.miomiPayApiKey}',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      final decoded = jsonDecode(response.body);
      final data = decoded['data'] ?? decoded;
      final rawStatus = _stringOf(data, ['status', 'payment_status']) ?? 'pending';
      return rawStatus.toLowerCase();
    } catch (e) {
      debugPrint('[MiomiPay Check Status Error]: $e');
      return _simulatedPaid.contains(reference) ? 'paid' : 'pending';
    }
  }

  /// Simulasi pembayaran berhasil (khusus mode Sandbox simulator).
  Future<void> simulateSuccess(String reference) async {
    _simulatedPaid.add(reference);
  }

  String? _stringOf(
    Map<String, dynamic> map,
    List<String> keys, {
    String? fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  DateTime? _dateOf(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is int) {
        final ms = value > 1000000000000 ? value : value * 1000;
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  void dispose() => _client.close();
}
