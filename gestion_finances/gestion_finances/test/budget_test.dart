import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_finances/core/constants.dart';
import 'package:gestion_finances/data/local/database.dart';
import 'package:gestion_finances/providers/budget_provider.dart';
import 'package:gestion_finances/providers/category_provider.dart';
import 'package:gestion_finances/providers/transaction_provider.dart';

void main() {
  group('Budget & Financial Health Tests', () {
    final now = DateTime.now();

    final catFood = Category(
      id: 'cat-food',
      name: 'Alimentation',
      type: 'expense',
      icon: 'food',
      color: '#E07A5F',
      isDefault: true,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    final catLeisure = Category(
      id: 'cat-leisure',
      name: 'Loisirs',
      type: 'expense',
      icon: 'movie',
      color: '#3D405B',
      isDefault: false,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    final budgetFood = Budget(
      id: 'b-1',
      categoryId: 'cat-food',
      amount: 300000,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    test('monthlyCategoryBudgetsProvider computes category progress and budget level', () async {
      final txSpentFood = Transaction(
        id: 'tx-1',
        accountId: 'acc-1',
        categoryId: 'cat-food',
        amount: 270000, // 90% -> warning
        type: TxType.expense,
        isNeed: true,
        date: DateTime(now.year, now.month, 5),
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final container = ProviderContainer(
        overrides: [
          expenseCategoriesProvider.overrideWithValue([catFood, catLeisure]),
          allBudgetsProvider.overrideWith((ref) => Stream.value([budgetFood])),
          allTransactionsProvider.overrideWith((ref) => Stream.value([txSpentFood])),
        ],
      );

      await container.read(allBudgetsProvider.future);
      await container.read(allTransactionsProvider.future);

      final list = container.read(monthlyCategoryBudgetsProvider);
      expect(list.length, 2);

      final foodStatus = list.firstWhere((s) => s.category.id == 'cat-food');
      expect(foodStatus.hasBudget, true);
      expect(foodStatus.limit, 300000);
      expect(foodStatus.spent, 270000);
      expect(foodStatus.remaining, 30000);
      expect(foodStatus.level, BudgetLevel.warning);

      final leisureStatus = list.firstWhere((s) => s.category.id == 'cat-leisure');
      expect(leisureStatus.hasBudget, false);
      expect(leisureStatus.level, BudgetLevel.none);
    });

    test('financialHealthProvider detects deficit and calculates daily safe-to-spend', () async {
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

      final expenseNeed = Transaction(
        id: 'tx-exp1',
        accountId: 'acc-1',
        categoryId: 'cat-food',
        amount: 400000,
        type: TxType.expense,
        isNeed: true,
        date: DateTime(now.year, now.month, 3),
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final expenseWant = Transaction(
        id: 'tx-exp2',
        accountId: 'acc-1',
        categoryId: 'cat-leisure',
        amount: 100000,
        type: TxType.expense,
        isNeed: false,
        date: DateTime(now.year, now.month, 4),
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        dirty: false,
      );

      final container = ProviderContainer(
        overrides: [
          expenseCategoriesProvider.overrideWithValue([catFood, catLeisure]),
          allBudgetsProvider.overrideWith((ref) => Stream.value([budgetFood])),
          allTransactionsProvider.overrideWith(
            (ref) => Stream.value([incomeTx, expenseNeed, expenseWant]),
          ),
        ],
      );

      await container.read(allBudgetsProvider.future);
      await container.read(allTransactionsProvider.future);

      final health = container.read(financialHealthProvider);
      expect(health.monthlyIncome, 1000000);
      expect(health.monthlyExpense, 500000);
      expect(health.isDeficit, false);
      expect(health.netSavings, 500000);
      expect(health.needsExpense, 400000);
      expect(health.wantsExpense, 100000);
      expect(health.dailySafeToSpend, greaterThan(0));
    });
  });
}
