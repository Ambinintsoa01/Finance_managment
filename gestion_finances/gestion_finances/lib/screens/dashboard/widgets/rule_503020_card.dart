import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/utils.dart';
import '../../../providers/financial_audit_provider.dart';
import '../../audit/financial_audit_screen.dart';

/// Carte de synthèse sur le Tableau de bord pour la répartition 50 / 30 / 20
/// (50% Besoins · 30% Envies · 20% Épargne).
class Rule503020Card extends ConsumerWidget {
  const Rule503020Card({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(rule503020Provider);

    final needsPct = rule.actualNeedsPercent;
    final wantsPct = rule.actualWantsPercent;
    final savingsPct = rule.actualSavingsPercent;
    final hasIncome = rule.hasIncome;

    // Couleurs distinctes pour chaque pilier
    const needsColor = AppTheme.primary;
    const wantsColor = Colors.orange;
    const savingsColor = AppTheme.income;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FinancialAuditScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : Titre & Badge d'accès à l'audit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.balance_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Équilibre 50 / 30 / 20',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Besoins · Envies · Épargne',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Audit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Barre de distribution visuelle
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: hasIncome && (needsPct + wantsPct + savingsPct) > 0
                      ? Row(
                          children: [
                            if (needsPct > 0)
                              Expanded(
                                flex: (needsPct * 10).round().clamp(1, 1000),
                                child: Container(color: needsColor),
                              ),
                            if (wantsPct > 0)
                              Expanded(
                                flex: (wantsPct * 10).round().clamp(1, 1000),
                                child: Container(color: wantsColor),
                              ),
                            if (savingsPct > 0)
                              Expanded(
                                flex: (savingsPct * 10).round().clamp(1, 1000),
                                child: Container(color: savingsColor),
                              ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(flex: 50, child: Container(color: needsColor.withValues(alpha: 0.3))),
                            Expanded(flex: 30, child: Container(color: wantsColor.withValues(alpha: 0.3))),
                            Expanded(flex: 20, child: Container(color: savingsColor.withValues(alpha: 0.3))),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // 3 Piliers chiffrés
              Row(
                children: [
                  Expanded(
                    child: _PillarMetric(
                      label: 'Besoins (50%)',
                      percent: hasIncome ? '${needsPct.toStringAsFixed(0)}%' : '50%',
                      amount: formatAmount(rule.needsSpent),
                      color: needsColor,
                      isOver: needsPct > 55,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _PillarMetric(
                      label: 'Envies (30%)',
                      percent: hasIncome ? '${wantsPct.toStringAsFixed(0)}%' : '30%',
                      amount: formatAmount(rule.wantsSpent),
                      color: wantsColor,
                      isOver: wantsPct > 35,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _PillarMetric(
                      label: 'Épargne (20%)',
                      percent: hasIncome ? '${savingsPct.toStringAsFixed(0)}%' : '20%',
                      amount: formatAmount(rule.savingsAllocated),
                      color: savingsColor,
                      isOver: false,
                    ),
                  ),
                ],
              ),

              // Alerte dépassement envies si pertinent
              if (rule.wantsOverspend > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Envies supérieures au seuil de 30% (+${formatAmount(rule.wantsOverspend)})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PillarMetric extends StatelessWidget {
  final String label;
  final String percent;
  final String amount;
  final Color color;
  final bool isOver;

  const _PillarMetric({
    required this.label,
    required this.percent,
    required this.amount,
    required this.color,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              percent,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isOver ? Colors.orange.shade800 : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
