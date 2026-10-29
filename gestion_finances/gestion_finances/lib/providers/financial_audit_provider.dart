import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'budget_provider.dart';
import 'category_provider.dart';
import 'savings_goal_provider.dart';
import 'transaction_provider.dart';

/// Découpage selon la méthode éprouvée 50 / 30 / 20 :
/// - 50% Besoins vitaux (Needs)
/// - 30% Envies & Loisirs (Wants)
/// - 20% Épargne & Avenir (Savings)
class Rule503020Breakdown {
  final double needsSpent;
  final double wantsSpent;
  final double savingsAllocated;
  final double totalIncome;

  final double targetNeeds;
  final double targetWants;
  final double targetSavings;

  final double actualNeedsPercent;
  final double actualWantsPercent;
  final double actualSavingsPercent;

  const Rule503020Breakdown({
    required this.needsSpent,
    required this.wantsSpent,
    required this.savingsAllocated,
    required this.totalIncome,
    required this.targetNeeds,
    required this.targetWants,
    required this.targetSavings,
    required this.actualNeedsPercent,
    required this.actualWantsPercent,
    required this.actualSavingsPercent,
  });

  bool get hasIncome => totalIncome > 0;

  /// Écart sur les envies (positif = dépassement des 30% recommandés)
  double get wantsOverspend => (wantsSpent - targetWants).clamp(0.0, double.infinity);

  /// Épargne manquante pour atteindre les 20%
  double get savingsShortfall => (targetSavings - savingsAllocated).clamp(0.0, double.infinity);

  String get diagnosticSummary {
    if (!hasIncome) return 'Enregistrez vos revenus pour calculer votre ratio 50/30/20.';
    if (actualWantsPercent > 35) {
      return 'Vos dépenses "Envies/Plaisirs" représentent ${actualWantsPercent.toStringAsFixed(0)}% (cible : 30%). Il y a ici un gisement d\'économies directes !';
    }
    if (actualSavingsPercent < 15) {
      return 'Votre taux d\'épargne est de ${actualSavingsPercent.toStringAsFixed(0)}% (cible : 20%). Pensez à vous payer en premier au début du mois.';
    }
    return 'Excellente gestion ! Vos proportions respectent les équilibres de la règle 50/30/20.';
  }
}

/// Analyse des "dépenses fourmis" (achats impulsifs répétés de petit montant).
class MicroExpenseAudit {
  final int count;
  final double totalAmount;
  final double percentOfTotalExpenses;
  final double projectedAnnualCost;
  final String? topCategoryName;

  const MicroExpenseAudit({
    required this.count,
    required this.totalAmount,
    required this.percentOfTotalExpenses,
    required this.projectedAnnualCost,
    this.topCategoryName,
  });
}

/// Recommandation d'optimisation financière actionnable.
class FinancialAdvice {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final double? potentialMonthlySavings;

  const FinancialAdvice({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.potentialMonthlySavings,
  });
}

/// Projection patrimoniale de l'épargne dans le temps.
class WealthProjection {
  final double monthlySavingsRate;
  final double in6Months;
  final double in1Year;
  final double in3Years;
  final double in5Years;

  const WealthProjection({
    required this.monthlySavingsRate,
    required this.in6Months,
    required this.in1Year,
    required this.in3Years,
    required this.in5Years,
  });
}

final rule503020Provider = Provider<Rule503020Breakdown>((ref) {
  final health = ref.watch(financialHealthProvider);
  final savingsSummary = ref.watch(savingsGoalsSummaryProvider);

  final income = health.monthlyIncome;
  final needs = health.needsExpense;
  final wants = health.wantsExpense;
  final netSavings = health.netSavings.clamp(0.0, double.infinity);
  final totalSaved = (savingsSummary.totalSaved > 0 && netSavings > 0)
      ? netSavings
      : netSavings;

  final targetNeeds = income * 0.50;
  final targetWants = income * 0.30;
  final targetSavings = income * 0.20;

  final totalEngaged = needs + wants + totalSaved;
  final needsPct = totalEngaged > 0 ? (needs / totalEngaged) * 100 : 0.0;
  final wantsPct = totalEngaged > 0 ? (wants / totalEngaged) * 100 : 0.0;
  final savingsPct = totalEngaged > 0 ? (totalSaved / totalEngaged) * 100 : 0.0;

  return Rule503020Breakdown(
    needsSpent: needs,
    wantsSpent: wants,
    savingsAllocated: totalSaved,
    totalIncome: income,
    targetNeeds: targetNeeds,
    targetWants: targetWants,
    targetSavings: targetSavings,
    actualNeedsPercent: needsPct,
    actualWantsPercent: wantsPct,
    actualSavingsPercent: savingsPct,
  );
});

final microExpenseAuditProvider = Provider<MicroExpenseAudit>((ref) {
  final transactions = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final categories = ref.watch(expenseCategoriesProvider);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 1);

  // Seuil micro-dépenses : dépenses < 15 000 Ar
  const threshold = 15000.0;

  int count = 0;
  double totalMicro = 0;
  double totalExpenses = 0;
  final categoryCounts = <String, int>{};

  for (final t in transactions) {
    if (t.type != TxType.expense) continue;
    if (t.date.isBefore(startOfMonth) || !t.date.isBefore(endOfMonth)) continue;

    totalExpenses += t.amount;
    if (t.amount <= threshold) {
      count++;
      totalMicro += t.amount;
      if (t.categoryId != null) {
        categoryCounts[t.categoryId!] = (categoryCounts[t.categoryId!] ?? 0) + 1;
      }
    }
  }

  String? topCatName;
  if (categoryCounts.isNotEmpty) {
    final topCatId = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    for (final c in categories) {
      if (c.id == topCatId) {
        topCatName = c.name;
        break;
      }
    }
  }

  final percent = totalExpenses > 0 ? (totalMicro / totalExpenses) * 100 : 0.0;
  final annualCost = totalMicro * 12;

  return MicroExpenseAudit(
    count: count,
    totalAmount: totalMicro,
    percentOfTotalExpenses: percent,
    projectedAnnualCost: annualCost,
    topCategoryName: topCatName,
  );
});

final wealthProjectionProvider = Provider<WealthProjection>((ref) {
  final health = ref.watch(financialHealthProvider);
  final monthlySavings = health.netSavings.clamp(0.0, double.infinity);

  return WealthProjection(
    monthlySavingsRate: monthlySavings,
    in6Months: monthlySavings * 6,
    in1Year: monthlySavings * 12,
    in3Years: monthlySavings * 36,
    in5Years: monthlySavings * 60,
  );
});

final financialAdvicesProvider = Provider<List<FinancialAdvice>>((ref) {
  final rule = ref.watch(rule503020Provider);
  final micro = ref.watch(microExpenseAuditProvider);
  final health = ref.watch(financialHealthProvider);

  final list = <FinancialAdvice>[];

  // 1. Alerte Dépenses > Gains (Priorité absolue)
  if (health.isDeficit) {
    list.add(
      FinancialAdvice(
        title: 'Stopper le déficit mensuel en urgence',
        message:
            'Vos dépenses dépassent vos revenus de ${health.monthlyExpense - health.monthlyIncome} Ar. Mettez en pause toutes les dépenses de catégorie "Envie / Plaisir" jusqu\'à la fin du mois.',
        icon: Icons.warning_amber_rounded,
        color: Colors.red,
      ),
    );
  }

  // 2. Optimisation Règle 50/30/20
  if (rule.hasIncome && rule.wantsOverspend > 0) {
    list.add(
      FinancialAdvice(
        title: 'Rééquilibrer la part "Plaisirs & Envies"',
        message:
            'En réduisant vos dépenses non essentielles de ${rule.wantsOverspend.toStringAsFixed(0)} Ar, vous atteignez les 30% d\'or de la règle 50/30/20.',
        icon: Icons.pie_chart_outline,
        color: Colors.orange,
        potentialMonthlySavings: rule.wantsOverspend,
      ),
    );
  }

  // 3. Traquer les dépenses fourmis
  if (micro.count >= 5) {
    list.add(
      FinancialAdvice(
        title: 'Surveiller les micro-dépenses répétées',
        message:
            'Vous avez cumulé ${micro.count} achats de moins de 15 000 Ar ce mois-ci (${micro.totalAmount.toStringAsFixed(0)} Ar au total, soit ${(micro.projectedAnnualCost).toStringAsFixed(0)} Ar par an !). Préparez ces petites sommes à l\'avance.',
        icon: Icons.coffee_outlined,
        color: Colors.amber.shade800,
        potentialMonthlySavings: micro.totalAmount * 0.4,
      ),
    );
  }

  // 4. Se payer en premier
  if (rule.hasIncome && rule.savingsShortfall > 0) {
    list.add(
      FinancialAdvice(
        title: 'Appliquer "Se payer en premier"',
        message:
            'Transférez 20% de vos gains (${rule.targetSavings.toStringAsFixed(0)} Ar) vers votre compte Épargne dès le jour de paye, avant de commencer à dépenser.',
        icon: Icons.savings_outlined,
        color: Colors.teal,
        potentialMonthlySavings: rule.savingsShortfall,
      ),
    );
  }

  // 5. Sas de décompression
  list.add(
    const FinancialAdvice(
      title: 'Activer systématiquement la règle des 48h',
      message:
          'Avant chaque achat de confort supérieur à 50 000 Ar, utilisez l\'onglet "Anti-Pulsions" : 72% des envies d\'achat s\'évanouissent après 2 jours de recul.',
      icon: Icons.hourglass_top_rounded,
      color: Colors.purple,
    ),
  );

  return list;
});
