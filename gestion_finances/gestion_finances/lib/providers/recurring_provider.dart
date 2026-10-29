import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../data/local/database.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';

final allRecurringProvider = StreamProvider<List<RecurringTransaction>>((ref) {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.watchAll();
});

class RecurringItemStatus {
  final RecurringTransaction recurring;
  final bool isPaidThisMonth;
  final int daysUntilDue; // positif = dans X jours, négatif = passé de X jours, 0 = aujourd'hui

  const RecurringItemStatus({
    required this.recurring,
    required this.isPaidThisMonth,
    required this.daysUntilDue,
  });

  bool get isDueToday => daysUntilDue == 0;
  bool get isPastDue => daysUntilDue < 0 && !isPaidThisMonth;
}

class MonthlyRecurringAnalysis {
  final double totalFixedExpenses;
  final double paidFixedExpenses;
  final double pendingFixedExpenses;
  final double totalFixedIncomes;
  final List<RecurringItemStatus> items;

  const MonthlyRecurringAnalysis({
    required this.totalFixedExpenses,
    required this.paidFixedExpenses,
    required this.pendingFixedExpenses,
    required this.totalFixedIncomes,
    required this.items,
  });
}

final monthlyRecurringAnalysisProvider = Provider<MonthlyRecurringAnalysis>((ref) {
  final recurringList = ref.watch(allRecurringProvider).valueOrNull ?? [];
  final transactions = ref.watch(allTransactionsProvider).valueOrNull ?? [];

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 1);

  // Transactions du mois courant
  final currentMonthTxs = transactions.where((t) {
    return !t.date.isBefore(startOfMonth) && t.date.isBefore(endOfMonth);
  }).toList();

  final items = <RecurringItemStatus>[];
  double totalFixedExpenses = 0;
  double paidFixedExpenses = 0;
  double pendingFixedExpenses = 0;
  double totalFixedIncomes = 0;

  for (final r in recurringList) {
    if (!r.isActive) continue;

    final daysUntil = r.dayOfMonth - now.day;

    // Détection si la charge/revenu a déjà été payé(e) ce mois-ci
    final isPaid = currentMonthTxs.any((t) {
      if (t.type != r.type) return false;
      // Match par catégorie si renseignée
      if (r.categoryId != null && t.categoryId == r.categoryId) {
        return true;
      }
      // Ou match par intitulé / note
      final note = (t.note ?? '').toLowerCase();
      final name = r.name.toLowerCase();
      if (note.contains(name) || name.contains(note)) {
        return true;
      }
      // Ou montant identique
      if ((t.amount - r.amount).abs() < 1) {
        return true;
      }
      return false;
    });

    items.add(RecurringItemStatus(
      recurring: r,
      isPaidThisMonth: isPaid,
      daysUntilDue: daysUntil,
    ));

    if (r.type == TxType.expense) {
      totalFixedExpenses += r.amount;
      if (isPaid) {
        paidFixedExpenses += r.amount;
      } else {
        pendingFixedExpenses += r.amount;
      }
    } else if (r.type == TxType.income) {
      totalFixedIncomes += r.amount;
    }
  }

  // Trier les échéances par jour du mois
  items.sort((a, b) => a.recurring.dayOfMonth.compareTo(b.recurring.dayOfMonth));

  return MonthlyRecurringAnalysis(
    totalFixedExpenses: totalFixedExpenses,
    paidFixedExpenses: paidFixedExpenses,
    pendingFixedExpenses: pendingFixedExpenses,
    totalFixedIncomes: totalFixedIncomes,
    items: items,
  );
});
