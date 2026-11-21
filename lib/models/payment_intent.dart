class PaymentIntent {
  const PaymentIntent({
    required this.reference,
    required this.status,
    required this.isSimulated,
    this.invoiceNumber,
    this.snapToken,
    this.qrString,
    this.qrImageUrl,
    this.paymentUrl,
    this.errorMessage,
    this.expiresAt,
  });

  final String reference;
  final String status;
  final bool isSimulated;
  final String? invoiceNumber;
  final String? snapToken;
  final String? qrString;
  final String? qrImageUrl;
  final String? paymentUrl;
  final String? errorMessage;
  final DateTime? expiresAt;

  bool get isPaid =>
      status.toLowerCase() == 'paid' ||
      status.toLowerCase() == 'settlement' ||
      status.toLowerCase() == 'success';

  bool get isFailed =>
      status.toLowerCase() == 'failed' ||
      status.toLowerCase() == 'expired' ||
      status.toLowerCase() == 'cancelled';

  /// URL untuk langsung membuka tagihan di MiomiPay Sandbox Simulator
  String? get simulatorUrl {
    final query = snapToken ?? paymentUrl ?? qrImageUrl ?? invoiceNumber ?? reference;
    if (query.isEmpty) return null;
    return 'https://pg.miomidev.com/sandbox/simulator?query=${Uri.encodeComponent(query)}';
  }
}
