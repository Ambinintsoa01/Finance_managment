import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_finances/core/constants.dart';
import 'package:gestion_finances/data/local/database.dart';
import 'package:gestion_finances/providers/budget_provider.dart';
import 'package:gestion_finances/providers/category_provider.dart';
import 'package:gestion_finances/providers/recurring_provider.dart';
import 'package:gestion_finances/providers/savings_goal_provider.dart';
import 'package:gestion_finances/providers/transaction_provider.dart';

void main() {
  group('Phase 2 Tests : Recurring charges & Savings goals', () {
    final now = DateTime.now();

    final rentRecurring = RecurringTransaction(
      id: 'rec-rent',
      name: 'Loyer',
      amount: 400000,
      type: TxType.expense,
      accountId: 'acc-1',
      dayOfMonth: 5,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    final internetRecurring = RecurringTransaction(
      id: 'rec-net',
      name: 'Internet',
      amount: 100000,
      type: TxType.expense,
      accountId: 'acc-1',
      dayOfMonth: 20,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    test('monthlyRecurringAnalysisProvider computes paid vs pending fixed expenses', () async {
      // Transaction for rent already paid
      final paidRentTx = Transaction(
        id: 'tx-rent',
        accountId: 'acc-1',
        amount: 400000,
        type: TxType.expense,
        note: 'Paiement Loyer',
        isNeed: true,
        date: DateTime(now.year, now.month, 4),
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final container = ProviderContainer(
        overrides: [
          allRecurringProvider.overrideWith(
            (ref) => Stream.value([rentRecurring, internetRecurring]),
          ),
          allTransactionsProvider.overrideWith(
            (ref) => Stream.value([paidRentTx]),
          ),
        ],
      );

      await container.read(allRecurringProvider.future);
      await container.read(allTransactionsProvider.future);

      final analysis = container.read(monthlyRecurringAnalysisProvider);
      expect(analysis.totalFixedExpenses, 500000);
      expect(analysis.paidFixedExpenses, 400000);
      expect(analysis.pendingFixedExpenses, 100000); // Internet remains pending!
    });

    test('dailySafeToSpend reserves pending fixed charges from monthly income', () async {
      final incomeTx = Transaction(
        id: 'tx-inc',
        accountId: 'acc-1',
        amount: 1000000,
        type: TxType.income,
        isNeed: true,
        date: DateTime(now.year, now.month, 1),
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final container = ProviderContainer(
        overrides: [
          expenseCategoriesProvider.overrideWithValue([]),
          allBudgetsProvider.overrideWith((ref) => Stream.value([])),
          allRecurringProvider.overrideWith(
            (ref) => Stream.value([rentRecurring, internetRecurring]),
          ), // 500 000 pending
          allTransactionsProvider.overrideWith(
            (ref) => Stream.value([incomeTx]),
          ),
        ],
      );

      await container.read(allRecurringProvider.future);
      await container.read(allTransactionsProvider.future);

      final health = container.read(financialHealthProvider);
      expect(health.monthlyIncome, 1000000);
      expect(health.pendingFixedExpenses, 500000);
      // Net remaining = 1 000 000 - 500 000 = 500 000
      expect(health.netSavings, 500000);
      expect(health.dailySafeToSpend, greaterThan(0));
    });

    test('savingsGoalsSummaryProvider computes total saved and progress', () async {
      final goal1 = SavingsGoal(
        id: 'g-1',
        name: 'Fonds d urgence',
        targetAmount: 1000000,
        currentAmount: 400000,
        color: '#2E7D5B',
        icon: 'savings',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final goal2 = SavingsGoal(
        id: 'g-2',
        name: 'Achat PC',
        targetAmount: 2000000,
        currentAmount: 600000,
        color: '#3E7CB1',
        icon: 'wallet',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final container = ProviderContainer(
        overrides: [
          allSavingsGoalsProvider.overrideWith(
            (ref) => Stream.value([goal1, goal2]),
          ),
        ],
      );

      await container.read(allSavingsGoalsProvider.future);

      final summary = container.read(savingsGoalsSummaryProvider);
      expect(summary.totalTarget, 3000000);
      expect(summary.totalSaved, 1000000);
      expect(summary.progress, closeTo(0.333, 0.01));
    });
  });
}
