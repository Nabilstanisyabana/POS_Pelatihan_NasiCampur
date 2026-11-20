class PaymentIntent {
  const PaymentIntent({
    required this.reference,
    required this.status,
    required this.isSimulated,
    this.qrString,
    this.qrImageUrl,
    this.paymentUrl,
    this.expiresAt,
  });

  final String reference;
  final String status;
  final bool isSimulated;
  final String? qrString;
  final String? qrImageUrl;
  final String? paymentUrl;
  final DateTime? expiresAt;

  bool get isPaid =>
      status.toLowerCase() == 'paid' ||
      status.toLowerCase() == 'settlement' ||
      status.toLowerCase() == 'success';

  bool get isFailed =>
      status.toLowerCase() == 'failed' ||
      status.toLowerCase() == 'expired' ||
      status.toLowerCase() == 'cancelled';
}
