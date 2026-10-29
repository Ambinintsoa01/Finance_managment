import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import 'account_provider.dart';
import 'budget_provider.dart';
import 'database_provider.dart';

final allWishlistProvider = StreamProvider<List<WishlistItem>>((ref) {
  final repo = ref.watch(wishlistRepositoryProvider);
  return repo.watchAll();
});

class WishlistSummary {
  final List<WishlistItem> waitingItems;
  final List<WishlistItem> resistedItems;
  final List<WishlistItem> boughtItems;
  final double totalResistedSavings;
  final int resistedCount;

  const WishlistSummary({
    required this.waitingItems,
    required this.resistedItems,
    required this.boughtItems,
    required this.totalResistedSavings,
    required this.resistedCount,
  });
}

final wishlistSummaryProvider = Provider<WishlistSummary>((ref) {
  final items = ref.watch(allWishlistProvider).valueOrNull ?? [];

  final waiting = <WishlistItem>[];
  final resisted = <WishlistItem>[];
  final bought = <WishlistItem>[];
  double totalResistedSavings = 0;

  for (final w in items) {
    if (w.status == 'waiting') {
      waiting.add(w);
    } else if (w.status == 'resisted') {
      resisted.add(w);
      totalResistedSavings += w.amount;
    } else if (w.status == 'bought') {
      bought.add(w);
    }
  }

  return WishlistSummary(
    waitingItems: waiting,
    resistedItems: resisted,
    boughtItems: bought,
    totalResistedSavings: totalResistedSavings,
    resistedCount: resisted.length,
  );
});

/// Simulation & Projection de fin de mois (Forecast).
class MonthEndForecast {
  final double currentBalance;
  final double projectedEndBalance;
  final double projectedSavings;
  final double dailyBurnRate;
  final bool isProjectedDeficit;

  const MonthEndForecast({
    required this.currentBalance,
    required this.projectedEndBalance,
    required this.projectedSavings,
    required this.dailyBurnRate,
    required this.isProjectedDeficit,
  });
}

final monthEndForecastProvider = Provider<MonthEndForecast>((ref) {
  final totalBalance = ref.watch(totalBalanceProvider).valueOrNull ?? 0.0;
  final health = ref.watch(financialHealthProvider);

  final now = DateTime.now();
  final currentDay = now.day;
  final daysRemaining = health.daysRemainingInMonth;

  // Rythme moyen de dépenses variables par jour écoulé
  final dailyBurn = currentDay > 0 ? (health.monthlyExpense / currentDay) : 0.0;
  final projectedRemainingExpenses = dailyBurn * daysRemaining;

  // Solde projeté en fin de mois
  final projectedEndBalance =
      totalBalance - health.pendingFixedExpenses - projectedRemainingExpenses;

  // Épargne nette prévisionnelle du mois : Gains - (Dépenses faites + Dépenses projetées + Charges en attente)
  final totalProjectedMonthExpense =
      health.monthlyExpense + health.pendingFixedExpenses + projectedRemainingExpenses;
  final projectedSavings = health.monthlyIncome - totalProjectedMonthExpense;

  final isDeficit = health.monthlyIncome > 0 && projectedSavings < 0;

  return MonthEndForecast(
    currentBalance: totalBalance,
    projectedEndBalance: projectedEndBalance,
    projectedSavings: projectedSavings,
    dailyBurnRate: dailyBurn,
    isProjectedDeficit: isDeficit,
  );
});
