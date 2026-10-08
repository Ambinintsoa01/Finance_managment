import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

/// Point de données pour l'évolution temporelle du capital.
class CapitalPoint {
  final double x;
  final double capital;
  final String label;
  final DateTime date;

  const CapitalPoint({
    required this.x,
    required this.capital,
    required this.label,
    required this.date,
  });
}

/// Données consolidées de variation du capital sur une période donnée.
class CapitalEvolutionData {
  final List<CapitalPoint> points;
  final double startCapital;
  final double endCapital;
  final double netVariation;
  final double percentageVariation;
  final String currency;

  const CapitalEvolutionData({
    required this.points,
    required this.startCapital,
    required this.endCapital,
    required this.netVariation,
    required this.percentageVariation,
    required this.currency,
  });
}

/// Évolution du capital (ou du solde du compte sélectionné) sur la période choisie.
final capitalEvolutionProvider = Provider<CapitalEvolutionData?>((ref) {
  final period = ref.watch(dashboardPeriodProvider);
  final refDate = ref.watch(dashboardReferenceDateProvider);
  final selectedAccountId = ref.watch(selectedAccountIdProvider);
  final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
  final allTxs = ref.watch(allTransactionsProvider).valueOrNull ?? [];

  final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
  if (activeAccounts.isEmpty) return null;

  final activeAccountIds = activeAccounts.map((a) => a.id).toSet();

  Account? selectedAccount;
  if (selectedAccountId != null) {
    selectedAccount = activeAccounts.firstWhereOrNull((a) => a.id == selectedAccountId);
    if (selectedAccount == null) return null;
  }

  final currency = selectedAccount?.currency ??
      (activeAccounts.isNotEmpty ? activeAccounts.first.currency : 'MGA');

  final double baseInitial = selectedAccountId != null
      ? (selectedAccount?.initialBalance ?? 0.0)
      : activeAccounts.fold<double>(0.0, (s, a) => s + a.initialBalance);

  double getImpact(Transaction t) {
    if (t.isDeleted) return 0.0;
    if (selectedAccountId != null) {
      if (t.accountId == selectedAccountId) {
        if (t.type == TxType.income) return t.amount;
        if (t.type == TxType.expense) return -t.amount;
        if (t.type == TxType.transfer) return -t.amount;
      }
      if (t.destinationAccountId == selectedAccountId) {
        if (t.type == TxType.transfer) return t.amount;
      }
      return 0.0;
    } else {
      if (t.type == TxType.income) {
        return activeAccountIds.contains(t.accountId) ? t.amount : 0.0;
      }
      if (t.type == TxType.expense) {
        return activeAccountIds.contains(t.accountId) ? -t.amount : 0.0;
      }
      if (t.type == TxType.transfer) {
        final fromActive = activeAccountIds.contains(t.accountId);
        final toActive = t.destinationAccountId != null &&
            activeAccountIds.contains(t.destinationAccountId);
        if (fromActive && !toActive) return -t.amount;
        if (!fromActive && toActive) return t.amount;
        return 0.0;
      }
      return 0.0;
    }
  }

  final (start, _) = periodRange(refDate, period: _periodKey(period));

  final checkpoints = <({DateTime date, String label, double x})>[];
  switch (period) {
    case DashboardPeriod.week:
      const weekLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      for (int i = 0; i < 7; i++) {
        final dayDate = start.add(Duration(days: i));
        final cutoff = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          23,
          59,
          59,
          999,
        );
        checkpoints.add((
          date: cutoff,
          label: weekLabels[i],
          x: i.toDouble(),
        ));
      }
      break;

    case DashboardPeriod.month:
      final daysInMonth = DateTime(refDate.year, refDate.month + 1, 0).day;
      for (int d = 1; d <= daysInMonth; d++) {
        final cutoff = DateTime(
          refDate.year,
          refDate.month,
          d,
          23,
          59,
          59,
          999,
        );
        checkpoints.add((
          date: cutoff,
          label: '$d',
          x: d.toDouble(),
        ));
      }
      break;

    case DashboardPeriod.year:
      for (int m = 1; m <= 12; m++) {
        final cutoff = DateTime(
          refDate.year,
          m + 1,
          0,
          23,
          59,
          59,
          999,
        );
        final monthLabel = DateFormat.MMM('fr_FR').format(DateTime(refDate.year, m, 1));
        checkpoints.add((
          date: cutoff,
          label: monthLabel,
          x: (m - 1).toDouble(),
        ));
      }
      break;
  }

  // Trier les transactions par ordre chronologique
  final sortedTxs = allTxs.where((t) => !t.isDeleted).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  // 1. Capital au début de la période
  double runningCapital = baseInitial;
  int txIdx = 0;
  while (txIdx < sortedTxs.length && sortedTxs[txIdx].date.isBefore(start)) {
    runningCapital += getImpact(sortedTxs[txIdx]);
    txIdx++;
  }
  final startCapital = runningCapital;

  // 2. Capital à chaque jalon
  final points = <CapitalPoint>[];
  for (final cp in checkpoints) {
    while (txIdx < sortedTxs.length && !sortedTxs[txIdx].date.isAfter(cp.date)) {
      runningCapital += getImpact(sortedTxs[txIdx]);
      txIdx++;
    }
    points.add(CapitalPoint(
      x: cp.x,
      capital: runningCapital,
      label: cp.label,
      date: cp.date,
    ));
  }

  final endCapital = points.isNotEmpty ? points.last.capital : startCapital;
  final netVariation = endCapital - startCapital;
  final double percentageVariation;
  if (startCapital != 0) {
    percentageVariation = (netVariation / startCapital.abs()) * 100;
  } else if (netVariation != 0) {
    percentageVariation = netVariation > 0 ? 100.0 : -100.0;
  } else {
    percentageVariation = 0.0;
  }

  return CapitalEvolutionData(
    points: points,
    startCapital: startCapital,
    endCapital: endCapital,
    netVariation: netVariation,
    percentageVariation: percentageVariation,
    currency: currency,
  );
});

