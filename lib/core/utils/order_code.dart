String generateOrderCode([DateTime? dateTime]) {
  final date = dateTime ?? DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  final year = date.year.toString().substring(2);
  final stamp = '$year${two(date.month)}${two(date.day)}';
  final time = '${two(date.hour)}${two(date.minute)}${two(date.second)}';
  final suffix = two(date.millisecond % 100);
  return 'INV-$stamp-$time$suffix';
}
