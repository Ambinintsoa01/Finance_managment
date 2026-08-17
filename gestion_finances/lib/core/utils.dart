import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

String formatAmount(double amount, {String currency = 'MGA'}) {
  final format = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: currency,
    decimalDigits: currency == 'MGA' ? 0 : 2,
  );
  return format.format(amount);
}

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatDateLong(DateTime date) {
  return DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
}

String formatMonthYear(DateTime date) {
  return DateFormat('MMMM yyyy', 'fr_FR').format(date);
}

/// Retourne (début, fin) de la période contenant [reference].
(DateTime, DateTime) periodRange(DateTime reference, {required String period}) {
  switch (period) {
    case 'week':
      final weekday = reference.weekday; // 1 = lundi
      final start = DateTime(reference.year, reference.month, reference.day)
          .subtract(Duration(days: weekday - 1));
      final end = start.add(const Duration(days: 7));
      return (start, end);
    case 'year':
      return (DateTime(reference.year, 1, 1), DateTime(reference.year + 1, 1, 1));
    case 'month':
    default:
      final start = DateTime(reference.year, reference.month, 1);
      final end = DateTime(reference.year, reference.month + 1, 1);
      return (start, end);
  }
}
