import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_finances/data/local/database.dart';
import 'package:gestion_finances/providers/account_provider.dart';
import 'package:gestion_finances/providers/budget_provider.dart';
import 'package:gestion_finances/providers/wishlist_provider.dart';

void main() {
  group('Phase 3 Tests : Anti-Impulse 48h & Month End Forecast', () {
    final now = DateTime.now();

    final item1 = WishlistItem(
      id: 'w-1',
      name: 'Veste de marque',
      amount: 150000,
      createdAt: now.subtract(const Duration(hours: 50)),
      targetDate: now.subtract(const Duration(hours: 2)), // délai dépassé
      status: 'resisted', // l'utilisateur a renoncé !
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    final item2 = WishlistItem(
      id: 'w-2',
      name: 'Casque Bluetooth',
      amount: 80000,
      createdAt: now.subtract(const Duration(hours: 10)),
      targetDate: now.add(const Duration(hours: 38)),
      status: 'waiting', // en cours de réflexion
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    final item3 = WishlistItem(
      id: 'w-3',
      name: 'Drone jouet',
      amount: 200000,
      createdAt: now.subtract(const Duration(hours: 60)),
      targetDate: now.subtract(const Duration(hours: 12)),
      status: 'resisted', // renoncé aussi !
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    test('wishlistSummaryProvider computes waiting items and resisted impulse savings', () async {
      final container = ProviderContainer(
        overrides: [
          allWishlistProvider.overrideWith(
            (ref) => Stream.value([item1, item2, item3]),
          ),
        ],
      );

      await container.read(allWishlistProvider.future);

      final summary = container.read(wishlistSummaryProvider);
      expect(summary.waitingItems.length, 1);
      expect(summary.resistedItems.length, 2);
      expect(summary.resistedCount, 2);
      expect(summary.totalResistedSavings, 350000); // 150 000 + 200 000 Ar
    });

    test('monthEndForecastProvider calculates projection from current pace', () async {
      const mockHealth = FinancialHealthStatus(
        monthlyIncome: 1200000,
        monthlyExpense: 300000,
        totalAllocatedBudget: 600000,
        totalBudgetSpent: 300000,
        needsExpense: 200000,
        wantsExpense: 100000,
        pendingFixedExpenses: 200000,
        daysRemainingInMonth: 15,
        dailySafeToSpend: 46666,
        monthProgressPercent: 50,
        spendingPacingPercent: 41.6,
      );

      final container = ProviderContainer(
        overrides: [
          totalBalanceProvider.overrideWith((ref) => Future.value(1000000.0)),
          financialHealthProvider.overrideWithValue(mockHealth),
        ],
      );

      await container.read(totalBalanceProvider.future);

      final forecast = container.read(monthEndForecastProvider);
      expect(forecast.currentBalance, 1000000);
      expect(forecast.dailyBurnRate, greaterThan(0));
      expect(forecast.projectedEndBalance, isNotNull);
      expect(forecast.isProjectedDeficit, false);
    });
  });
}
