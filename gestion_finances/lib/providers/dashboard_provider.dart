import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../data/local/database.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';

/// Période affichée sur le dashboard (semaine / mois / année).
final dashboardPeriodProvider =
    StateProvider<DashboardPeriod>((ref) => DashboardPeriod.month);

/// Date de référence pour la période affichée (permet de naviguer
/// mois précédent / suivant, etc. — par défaut : aujourd'hui).
final dashboardReferenceDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

String _periodKey(DashboardPeriod p) {
  switch (p) {
    case DashboardPeriod.week:
      return 'week';
    case DashboardPeriod.year:
      return 'year';
    case DashboardPeriod.month:
      return 'month';
  }
}

/// Transactions filtrées par la période sélectionnée et, le cas échéant,
/// par le compte sélectionné sur le dashboard.
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final period = ref.watch(dashboardPeriodProvider);
  final refDate = ref.watch(dashboardReferenceDateProvider);
  final selectedAccountId = ref.watch(selectedAccountIdProvider);
  final all = ref.watch(allTransactionsProvider).valueOrNull ?? [];

  final (start, end) = periodRange(refDate, period: _periodKey(period));

  return all.where((t) {
    final inPeriod = !t.date.isBefore(start) && t.date.isBefore(end);
    if (!inPeriod) return false;
    if (selectedAccountId == null) return true;
    return t.accountId == selectedAccountId ||
        t.destinationAccountId == selectedAccountId;
  }).toList();
});

/// (revenus, dépenses) sur la période/compte filtrés.
/// Les transferts entre comptes ne sont pas comptés comme revenu/dépense
/// au niveau global (ils ne font que déplacer de l'argent), sauf lorsqu'un
/// compte précis est sélectionné où ils affectent bien son solde.
final periodTotalsProvider = Provider<({double income, double expense})>((ref) {
  final txs = ref.watch(filteredTransactionsProvider);
  final selectedAccountId = ref.watch(selectedAccountIdProvider);

  double income = 0;
  double expense = 0;

  for (final t in txs) {
    if (t.type == TxType.income) {
      income += t.amount;
    } else if (t.type == TxType.expense) {
      expense += t.amount;
    } else if (t.type == TxType.transfer && selectedAccountId != null) {
      if (t.accountId == selectedAccountId) expense += t.amount;
      if (t.destinationAccountId == selectedAccountId) income += t.amount;
    }
  }

  return (income: income, expense: expense);
});

/// Répartition des dépenses par catégorie sur la période filtrée
/// (pour le camembert du dashboard).
final expensesByCategoryProvider = Provider<Map<String, double>>((ref) {
  final txs = ref.watch(filteredTransactionsProvider);
  final map = <String, double>{};
  for (final t in txs) {
    if (t.type != TxType.expense || t.categoryId == null) continue;
    map[t.categoryId!] = (map[t.categoryId!] ?? 0) + t.amount;
  }
  return map;
});
