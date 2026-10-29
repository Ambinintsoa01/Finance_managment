import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/utils.dart';
import '../../../providers/budget_provider.dart';
import '../../budgets/budgets_screen.dart';

class SafeToSpendCard extends ConsumerWidget {
  const SafeToSpendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(financialHealthProvider);

    final isDeficit = health.isDeficit;
    final hasIncome = health.monthlyIncome > 0;
    final isPacingFast = health.isPacingTooFast;
    final hasPendingFixed = health.pendingFixedExpenses > 0;

    Color cardBorderColor = Colors.transparent;
    Color statusBgColor = AppTheme.income.withValues(alpha: 0.12);
    Color statusTextColor = AppTheme.income;
    String statusTitle = 'Dépenses inférieures aux gains';
    IconData statusIcon = Icons.check_circle_outline;

    if (isDeficit) {
      cardBorderColor = AppTheme.expense;
      statusBgColor = AppTheme.expense.withValues(alpha: 0.15);
      statusTextColor = AppTheme.expense;
      statusTitle = 'DÉFICIT : Dépenses + Charges > Gains !';
      statusIcon = Icons.warning_amber_rounded;
    } else if (isPacingFast) {
      cardBorderColor = Colors.orange;
      statusBgColor = Colors.orange.withValues(alpha: 0.15);
      statusTextColor = Colors.orange.shade800;
      statusTitle = 'Attention : Rythme de dépenses élevé';
      statusIcon = Icons.speed_rounded;
    } else if (!hasIncome) {
      statusBgColor = Colors.grey.withValues(alpha: 0.12);
      statusTextColor = Colors.grey.shade700;
      statusTitle = 'Aucun revenu enregistré ce mois';
      statusIcon = Icons.info_outline;
    }

    final totalSpentNeedsWants = health.needsExpense + health.wantsExpense;
    final needsPercent = totalSpentNeedsWants > 0
        ? (health.needsExpense / totalSpentNeedsWants) * 100
        : 100.0;
    final wantsPercent = totalSpentNeedsWants > 0
        ? (health.wantsExpense / totalSpentNeedsWants) * 100
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: cardBorderColor.withValues(alpha: 0.6),
          width: isDeficit || isPacingFast ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Règle d'or & Statut
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusTextColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusTitle,
                            style: TextStyle(
                              color: statusTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Gérer', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BudgetsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reste à vivre par jour
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reste à vivre quotidien',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatAmount(health.dailySafeToSpend),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDeficit ? AppTheme.expense : AppTheme.primary,
                        ),
                      ),
                      Text(
                        isDeficit
                            ? 'Déficit de ${formatAmount(health.monthlyExpense + health.pendingFixedExpenses - health.monthlyIncome)} ce mois !'
                            : 'par jour sur les ${health.daysRemainingInMonth} jours restants',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDeficit ? AppTheme.expense : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasIncome && !isDeficit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.income.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Épargne projetée',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          '+${formatAmount(health.netSavings)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.income,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Provision des charges fixes à venir
            if (hasPendingFixed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock_outlined, size: 16, color: Color(0xFF2C3E50)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${formatAmount(health.pendingFixedExpenses)} pré-réservés pour vos charges fixes à venir.',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Comparateur Burn Rate (Avancement du mois vs Consommation des gains)
            if (hasIncome) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rythme : Jour ${DateTime.now().day} (${health.monthProgressPercent.toStringAsFixed(0)}% du mois)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${health.spendingPacingPercent.toStringAsFixed(0)}% des gains engagés',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPacingFast ? Colors.orange.shade800 : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (health.spendingPacingPercent / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDeficit
                            ? AppTheme.expense
                            : (isPacingFast ? Colors.orange : AppTheme.income),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (health.monthProgressPercent / 100).clamp(0.0, 1.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 3,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Repère noir = jour du mois. Votre barre ne doit pas dépasser le repère.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
            ],

            // Répartition Besoins vitaux vs Envies & Plaisirs
            if (totalSpentNeedsWants > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Besoins : ${needsPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_outlined, size: 14, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(
                        'Envies/Plaisirs : ${wantsPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    Expanded(
                      flex: (needsPercent * 10).round().clamp(1, 1000),
                      child: Container(
                        height: 6,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (wantsPercent > 0)
                      Expanded(
                        flex: (wantsPercent * 10).round().clamp(1, 1000),
                        child: Container(
                          height: 6,
                          color: Colors.purple.shade300,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
