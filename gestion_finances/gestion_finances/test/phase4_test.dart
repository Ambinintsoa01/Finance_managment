import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_finances/core/constants.dart';
import 'package:gestion_finances/data/local/database.dart';
import 'package:gestion_finances/providers/budget_provider.dart';
import 'package:gestion_finances/providers/category_provider.dart';
import 'package:gestion_finances/providers/financial_audit_provider.dart';
import 'package:gestion_finances/providers/transaction_provider.dart';

void main() {
  group('Phase 4 Tests : Financial Health Audit & Rule 50/30/20', () {
    test('rule503020Provider calculates exact ratios and targets', () {
      final container = ProviderContainer(
        overrides: [
          financialHealthProvider.overrideWithValue(
            const FinancialHealthStatus(
              monthlyIncome: 1000000,
              monthlyExpense: 800000,
              totalAllocatedBudget: 700000,
              totalBudgetSpent: 600000,
              needsExpense: 500000,
              wantsExpense: 300000,
              pendingFixedExpenses: 0,
              daysRemainingInMonth: 10,
              dailySafeToSpend: 20000,
              monthProgressPercent: 66,
              spendingPacingPercent: 80,
            ),
          ),
        ],
      );

      final rule = container.read(rule503020Provider);

      expect(rule.hasIncome, true);
      expect(rule.targetNeeds, 500000.0); // 50%
      expect(rule.targetWants, 300000.0); // 30%
      expect(rule.targetSavings, 200000.0); // 20%

      expect(rule.actualNeedsPercent, 50.0);
      expect(rule.actualWantsPercent, 30.0);
      expect(rule.actualSavingsPercent, 20.0);

      expect(rule.wantsOverspend, 0.0);
      expect(rule.savingsShortfall, 0.0);
      expect(rule.diagnosticSummary.contains('Excellente gestion'), true);
    });

    test('rule503020Provider detects wants overspend and savings shortfall', () {
      final container = ProviderContainer(
        overrides: [
          financialHealthProvider.overrideWithValue(
            const FinancialHealthStatus(
              monthlyIncome: 1000000,
              monthlyExpense: 900000,
              totalAllocatedBudget: 700000,
              totalBudgetSpent: 600000,
              needsExpense: 450000,
              wantsExpense: 450000, // Wants exceeded 300 000 target by 150 000
              pendingFixedExpenses: 0,
              daysRemainingInMonth: 10,
              dailySafeToSpend: 10000,
              monthProgressPercent: 66,
              spendingPacingPercent: 90,
            ),
          ),
        ],
      );

      final rule = container.read(rule503020Provider);

      expect(rule.wantsOverspend, 150000.0);
      expect(rule.savingsShortfall, 100000.0); // target 200 000 - net 100 000
      expect(rule.actualWantsPercent, 45.0);
      expect(rule.diagnosticSummary.contains('Envies/Plaisirs'), true);
    });

    test('microExpenseAuditProvider tracks micro-transactions <= 15 000 Ar and annual leak', () async {
      final now = DateTime.now();

      final t1 = Transaction(
        id: 'tx-1',
        accountId: 'acc-1',
        amount: 5000, // Micro-dépense
        type: TxType.expense,
        date: DateTime(now.year, now.month, 5),
        note: 'Café',
        categoryId: 'cat-food',
        isNeed: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final t2 = Transaction(
        id: 'tx-2',
        accountId: 'acc-1',
        amount: 10000, // Micro-dépense
        type: TxType.expense,
        date: DateTime(now.year, now.month, 10),
        note: 'Snack',
        categoryId: 'cat-food',
        isNeed: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final t3 = Transaction(
        id: 'tx-3',
        accountId: 'acc-1',
        amount: 60000, // Grande dépense (> 15 000)
        type: TxType.expense,
        date: DateTime(now.year, now.month, 12),
        note: 'Courses supermarché',
        categoryId: 'cat-food',
        isNeed: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final t4 = Transaction(
        id: 'tx-4',
        accountId: 'acc-1',
        amount: 3000, // Micro-dépense d\'un autre mois (ne doit pas être comptée)
        type: TxType.expense,
        date: DateTime(now.year, now.month - 1, 15),
        note: 'Vieux ticket',
        categoryId: 'cat-food',
        isNeed: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final category = Category(
        id: 'cat-food',
        name: 'Alimentation',
        type: 'expense',
        icon: 'restaurant',
        color: '#FF9800',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final container = ProviderContainer(
        overrides: [
          allTransactionsProvider.overrideWith(
            (ref) => Stream.value([t1, t2, t3, t4]),
          ),
          expenseCategoriesProvider.overrideWithValue([category]),
        ],
      );

      await container.read(allTransactionsProvider.future);

      final micro = container.read(microExpenseAuditProvider);

      expect(micro.count, 2);
      expect(micro.totalAmount, 15000.0); // 5000 + 10000
      expect(micro.projectedAnnualCost, 180000.0); // 15000 * 12
      expect(micro.topCategoryName, 'Alimentation');
    });

    test('wealthProjectionProvider projects savings over 6m, 1y, 3y, 5y', () {
      final container = ProviderContainer(
        overrides: [
          financialHealthProvider.overrideWithValue(
            const FinancialHealthStatus(
              monthlyIncome: 1200000,
              monthlyExpense: 900000,
              totalAllocatedBudget: 800000,
              totalBudgetSpent: 700000,
              needsExpense: 600000,
              wantsExpense: 300000,
              pendingFixedExpenses: 0,
              daysRemainingInMonth: 15,
              dailySafeToSpend: 20000,
              monthProgressPercent: 50,
              spendingPacingPercent: 75,
            ),
          ),
        ],
      );

      final wealth = container.read(wealthProjectionProvider);

      // netSavings = 1 200 000 - 900 000 = 300 000 Ar
      expect(wealth.monthlySavingsRate, 300000.0);
      expect(wealth.in6Months, 1800000.0);
      expect(wealth.in1Year, 3600000.0);
      expect(wealth.in3Years, 10800000.0);
      expect(wealth.in5Years, 18000000.0);
    });

    test('financialAdvicesProvider emits high-priority alert on deficit', () {
      final container = ProviderContainer(
        overrides: [
          financialHealthProvider.overrideWithValue(
            const FinancialHealthStatus(
              monthlyIncome: 500000,
              monthlyExpense: 700000, // Deficit!
              totalAllocatedBudget: 600000,
              totalBudgetSpent: 650000,
              needsExpense: 400000,
              wantsExpense: 300000,
              pendingFixedExpenses: 0,
              daysRemainingInMonth: 10,
              dailySafeToSpend: 0,
              monthProgressPercent: 66,
              spendingPacingPercent: 140,
            ),
          ),
        ],
      );

      final advices = container.read(financialAdvicesProvider);

      expect(advices.isNotEmpty, true);
      expect(advices.any((a) => a.title.contains('déficit')), true);
    });
  });
}
