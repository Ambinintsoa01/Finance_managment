import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/utils.dart';
import '../../providers/budget_provider.dart';
import '../../providers/financial_audit_provider.dart';
import '../../providers/savings_goal_provider.dart';

class FinancialAuditScreen extends ConsumerWidget {
  const FinancialAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(rule503020Provider);
    final micro = ref.watch(microExpenseAuditProvider);
    final wealth = ref.watch(wealthProjectionProvider);
    final advices = ref.watch(financialAdvicesProvider);
    final health = ref.watch(financialHealthProvider);
    final savings = ref.watch(savingsGoalsSummaryProvider);

    // Calcul d'un Score d'Efficacité Financière (0 - 100)
    int score = 50;
    if (health.monthlyIncome > 0) {
      if (!health.isDeficit) score += 20;
      if (rule.actualWantsPercent <= 30) score += 15;
      if (rule.actualSavingsPercent >= 15) score += 15;
    }
    if (savings.totalSaved > 0) score += 10;
    if (health.isDeficit) score = (score - 40).clamp(10, 100);
    score = score.clamp(10, 100);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Audit Financier & Stratégie'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 90),
        children: [
          // Carte Score Global (Inspirée du style sombre de la maquette)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: score >= 70
                    ? [AppTheme.emeraldDarkest, AppTheme.emeraldDeep]
                    : (score >= 50
                        ? [const Color(0xFF1B382F), const Color(0xFF285043)]
                        : [const Color(0xFF5E1B24), const Color(0xFF7D2B35)]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22051F20),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Score de Maîtrise Financière',
                        style: TextStyle(
                          color: AppTheme.emeraldSage,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        score >= 70
                            ? 'Excellent contrôle 🛡️'
                            : (score >= 50 ? 'Équilibre fragile ⚖️' : 'Alerte déficit 🚨'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        health.isDeficit
                            ? 'Vos dépenses dépassent vos revenus : action recommandée.'
                            : 'Vos dépenses restent sous contrôle par rapport à vos revenus.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldMint,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        color: AppTheme.emeraldDarkest,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 1. RAPPORT RÈGLE 50 / 30 / 20
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, color: AppTheme.emeraldPine, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Règle d\'or 50 / 30 / 20',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rule.diagnosticSummary,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Barre de répartition visuelle
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (rule.actualNeedsPercent * 10).round().clamp(1, 1000),
                        child: Container(
                          height: 12,
                          color: AppTheme.emeraldPine,
                        ),
                      ),
                      Expanded(
                        flex: (rule.actualWantsPercent * 10).round().clamp(1, 1000),
                        child: Container(
                          height: 12,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      Expanded(
                        flex: (rule.actualSavingsPercent * 10).round().clamp(1, 1000),
                        child: Container(
                          height: 12,
                          color: AppTheme.income,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Détail des 3 piliers
                _PillarRow(
                  label: '50% Besoins essentiels (Needs)',
                  actualAmount: rule.needsSpent,
                  targetAmount: rule.targetNeeds,
                  actualPercent: rule.actualNeedsPercent,
                  targetPercent: 50,
                  color: AppTheme.emeraldPine,
                  icon: Icons.shield_outlined,
                ),
                Divider(height: 16, color: AppTheme.cardBorder.withValues(alpha: 0.6)),
                _PillarRow(
                  label: '30% Envies & Confort (Wants)',
                  actualAmount: rule.wantsSpent,
                  targetAmount: rule.targetWants,
                  actualPercent: rule.actualWantsPercent,
                  targetPercent: 30,
                  color: Colors.amber.shade800,
                  icon: Icons.auto_awesome_outlined,
                  isWarning: rule.actualWantsPercent > 35,
                ),
                Divider(height: 16, color: AppTheme.cardBorder.withValues(alpha: 0.6)),
                _PillarRow(
                  label: '20% Épargne & Avenir (Savings)',
                  actualAmount: rule.savingsAllocated,
                  targetAmount: rule.targetSavings,
                  actualPercent: rule.actualSavingsPercent,
                  targetPercent: 20,
                  color: AppTheme.income,
                  icon: Icons.savings_outlined,
                  isWarning: rule.actualSavingsPercent < 15,
                ),
              ],
            ),
          ),

          // 2. RADAR DES DÉPENSES FOURMIS (MICRO-FUITES)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.radar_rounded, color: Colors.amber.shade900, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Radar des "Dépenses Fourmis"',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Les petits achats de moins de 15 000 Ar paraissent inoffensifs isolément, mais constituent la 1ère fuite d\'argent inconsciente.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${micro.count} micro-achats',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total : ${formatAmount(micro.totalAmount)}',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldSage.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${formatAmount(micro.projectedAnnualCost)}/an',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.emeraldDarkest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${micro.percentOfTotalExpenses.toStringAsFixed(0)}% des sorties',
                              style: const TextStyle(fontSize: 12, color: AppTheme.emeraldPine),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. SIMULATEUR D'ACCUMULATION PATRIMONIALE
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: AppTheme.emeraldPine, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Projection d\'Épargne dans le temps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Si vous maintenez votre capacité d\'épargne actuelle (${formatAmount(wealth.monthlySavingsRate)}/mois) :',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HorizonCard(label: 'Dans 6 mois', amount: wealth.in6Months),
                    const SizedBox(width: 8),
                    _HorizonCard(label: 'Dans 1 an', amount: wealth.in1Year),
                    const SizedBox(width: 8),
                    _HorizonCard(label: 'Dans 3 ans', amount: wealth.in3Years),
                  ],
                ),
              ],
            ),
          ),

          // 4. PLAN D'ACTIONS & CONSEILS PERSONNALISÉS
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Actions Recommandées',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),

          ...advices.map((ad) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder, width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  backgroundColor: ad.color.withValues(alpha: 0.12),
                  child: Icon(ad.icon, color: ad.color),
                ),
                title: Text(
                  ad.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(ad.message, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    if (ad.potentialMonthlySavings != null && ad.potentialMonthlySavings! > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldMint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Économie potentielle : +${formatAmount(ad.potentialMonthlySavings!)}/mois',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.emeraldDarkest,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  const _PillarRow({
    required this.label,
    required this.actualAmount,
    required this.targetAmount,
    required this.actualPercent,
    required this.targetPercent,
    required this.color,
    required this.icon,
    this.isWarning = false,
  });

  final String label;
  final double actualAmount;
  final double targetAmount;
  final double actualPercent;
  final double targetPercent;
  final Color color;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Réel : ${formatAmount(actualAmount)} (${actualPercent.toStringAsFixed(0)}%) • Cible : ${formatAmount(targetAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isWarning ? Colors.orange.shade800 : AppTheme.textMuted,
                  fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${actualPercent.toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _HorizonCard extends StatelessWidget {
  const _HorizonCard({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              formatAmount(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
