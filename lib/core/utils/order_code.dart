String generateOrderCode([DateTime? dateTime]) {
  final date = dateTime ?? DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  String three(int value) => value.toString().padLeft(3, '0');
  final dateStamp = '${date.year}${two(date.month)}${two(date.day)}';
  final timeStamp =
      '${two(date.hour)}${two(date.minute)}${two(date.second)}'
      '${three(date.millisecond)}${three(date.microsecond)}';
  return 'MP-INV-$dateStamp$timeStamp';
}
