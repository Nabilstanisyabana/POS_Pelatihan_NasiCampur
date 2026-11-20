import 'package:intl/intl.dart';

final NumberFormat _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Format angka menjadi Rupiah tanpa desimal sesuai PRD: `Rp 25.000`
String rupiah(num value) {
  return _rupiahFormat.format(value).replaceAll('\u00A0', ' ');
}

/// Format ringkas untuk ringkasan nominal: Rp 1,2 jt
String compactRupiah(num value) {
  if (value >= 1000000000) {
    return 'Rp ${(value / 1000000000).toStringAsFixed(1).replaceAll('.', ',')} M';
  }
  if (value >= 1000000) {
    return 'Rp ${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')} jt';
  }
  if (value >= 1000) {
    return 'Rp ${(value / 1000).toStringAsFixed(0)} rb';
  }
  return rupiah(value);
}

const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

const List<String> _dayNames = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];

String shortDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

String timeOnly(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String dateTimeLabel(DateTime date) =>
    '${shortDate(date)} • ${timeOnly(date)}';

String dayName(DateTime date) => _dayNames[date.weekday - 1];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
