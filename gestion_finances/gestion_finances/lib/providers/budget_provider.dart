import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../data/local/database.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'recurring_provider.dart';
import 'transaction_provider.dart';

/// Flux de tous les budgets actifs.
final allBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.watchAll();
});

/// Dictionnaire categoryId -> Budget pour accès direct.
final budgetsByCategoryProvider = Provider<Map<String, Budget>>((ref) {
  final budgetsAsync = ref.watch(allBudgetsProvider);
  final budgets = budgetsAsync.valueOrNull ?? [];
  final map = <String, Budget>{};
  for (final b in budgets) {
    map[b.categoryId] = b;
  }
  return map;
});

enum BudgetLevel {
  safe, // < 80%
  warning, // >= 80% et <= 100%
  danger, // > 100% (dépassé)
  none, // aucun budget fixé
}

/// État budgétaire d'une catégorie pour le mois en cours.
class CategoryBudgetStatus {
  final Category category;
  final Budget? budget;
  final double spent;

  const CategoryBudgetStatus({
    required this.category,
    required this.budget,
    required this.spent,
  });

  bool get hasBudget => budget != null && budget!.amount > 0;
  double get limit => budget?.amount ?? 0;
  double get remaining => hasBudget ? limit - spent : 0;
  double get progress => hasBudget && limit > 0 ? (spent / limit).clamp(0.0, 1.5) : 0;

  BudgetLevel get level {
    if (!hasBudget) return BudgetLevel.none;
    if (spent > limit) return BudgetLevel.danger;
    if (spent >= limit * 0.8) return BudgetLevel.warning;
    return BudgetLevel.safe;
  }
}

/// Statut de toutes les catégories de dépenses pour le mois en cours.
final monthlyCategoryBudgetsProvider = Provider<List<CategoryBudgetStatus>>((ref) {
  final expenseCategories = ref.watch(expenseCategoriesProvider);
  final budgetsMap = ref.watch(budgetsByCategoryProvider);
  final allTransactionsAsync = ref.watch(allTransactionsProvider);

  final transactions = allTransactionsAsync.valueOrNull ?? [];

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 1);

  // Dépenses du mois courant groupées par catégorie
  final expensesMap = <String, double>{};
  for (final t in transactions) {
    if (t.type == TxType.expense &&
        t.categoryId != null &&
        !t.date.isBefore(startOfMonth) &&
        t.date.isBefore(endOfMonth)) {
      expensesMap[t.categoryId!] = (expensesMap[t.categoryId!] ?? 0) + t.amount;
    }
  }

  final list = expenseCategories.map((cat) {
    return CategoryBudgetStatus(
      category: cat,
      budget: budgetsMap[cat.id],
      spent: expensesMap[cat.id] ?? 0.0,
    );
  }).toList();

  // Trier : en premier celles qui ont un budget (puis par pourcentage de dépassement)
  list.sort((a, b) {
    if (a.hasBudget && !b.hasBudget) return -1;
    if (!a.hasBudget && b.hasBudget) return 1;
    return b.progress.compareTo(a.progress);
  });

  return list;
});

/// Indicateurs de santé financière globale du mois courant.
class FinancialHealthStatus {
  final double monthlyIncome;
  final double monthlyExpense;
  final double totalAllocatedBudget;
  final double totalBudgetSpent;
  final double needsExpense;
  final double wantsExpense;
  final double pendingFixedExpenses;
  final int daysRemainingInMonth;
  final double dailySafeToSpend;
  final double monthProgressPercent;
  final double spendingPacingPercent;

  const FinancialHealthStatus({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.totalAllocatedBudget,
    required this.totalBudgetSpent,
    required this.needsExpense,
    required this.wantsExpense,
    required this.pendingFixedExpenses,
    required this.daysRemainingInMonth,
    required this.dailySafeToSpend,
    required this.monthProgressPercent,
    required this.spendingPacingPercent,
  });

  /// Vrai si les dépenses dépassent strictement les gains !
  bool get isDeficit => (monthlyExpense + pendingFixedExpenses) > monthlyIncome && monthlyIncome > 0;

  /// Marge restante (Gains - Dépenses - Charges fixes à venir)
  double get netSavings => monthlyIncome - monthlyExpense - pendingFixedExpenses;

  /// Taux d'épargne (en %)
  double get savingsRate =>
      monthlyIncome > 0 ? (netSavings / monthlyIncome) * 100 : 0;

  /// Vrai si le rythme de dépense est anormalement élevé par rapport au jour du mois
  bool get isPacingTooFast =>
      monthlyIncome > 0 &&
      spendingPacingPercent > (monthProgressPercent + 15) &&
      monthlyExpense > 0;
}

final financialHealthProvider = Provider<FinancialHealthStatus>((ref) {
  final transactions = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final categoryBudgets = ref.watch(monthlyCategoryBudgetsProvider);
  final recurringAnalysis = ref.watch(monthlyRecurringAnalysisProvider);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 1);
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final currentDay = now.day;
  final daysRemaining = (daysInMonth - currentDay + 1).clamp(1, 31);

  double income = 0;
  double expense = 0;
  double needs = 0;
  double wants = 0;

  for (final t in transactions) {
    if (t.date.isBefore(startOfMonth) || !t.date.isBefore(endOfMonth)) continue;

    if (t.type == TxType.income) {
      income += t.amount;
    } else if (t.type == TxType.expense) {
      expense += t.amount;
      if (t.isNeed) {
        needs += t.amount;
      } else {
        wants += t.amount;
      }
    }
  }

  double totalBudget = 0;
  double budgetSpent = 0;
  for (final cb in categoryBudgets) {
    if (cb.hasBudget) {
      totalBudget += cb.limit;
      budgetSpent += cb.spent;
    }
  }

  final pendingFixed = recurringAnalysis.pendingFixedExpenses;

  // Reste à vivre net = Revenus - Dépenses déjà faites - Charges fixes encore dues
  final remaining = income - expense - pendingFixed;
  final dailySafe = remaining > 0 ? (remaining / daysRemaining) : 0.0;

  final monthProgress = (currentDay / daysInMonth) * 100;
  final spendingPacing = income > 0 ? ((expense + pendingFixed) / income) * 100 : 0.0;

  return FinancialHealthStatus(
    monthlyIncome: income,
    monthlyExpense: expense,
    totalAllocatedBudget: totalBudget,
    totalBudgetSpent: budgetSpent,
    needsExpense: needs,
    wantsExpense: wants,
    pendingFixedExpenses: pendingFixed,
    daysRemainingInMonth: daysRemaining,
    dailySafeToSpend: dailySafe,
    monthProgressPercent: monthProgress,
    spendingPacingPercent: spendingPacing,
  );
});
