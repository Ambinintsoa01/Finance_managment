import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/utils.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../audit/financial_audit_screen.dart';

class MinimalStatGrid extends ConsumerWidget {
  const MinimalStatGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(financialHealthProvider);
    final totals = ref.watch(periodTotalsProvider);

    final isDeficit = health.isDeficit;
    final isPacingFast = health.isPacingTooFast;
    final hasIncome = health.monthlyIncome > 0;

    String statusBadge;
    Color statusBadgeBg;
    Color statusBadgeText;

    if (isDeficit) {
      statusBadge = 'Déficit';
      statusBadgeBg = AppTheme.expense.withValues(alpha: 0.12);
      statusBadgeText = AppTheme.expense;
    } else if (isPacingFast) {
      statusBadge = 'Rythme élevé';
      statusBadgeBg = Colors.orange.withValues(alpha: 0.14);
      statusBadgeText = Colors.orange.shade800;
    } else if (!hasIncome) {
      statusBadge = 'En attente';
      statusBadgeBg = Colors.grey.withValues(alpha: 0.12);
      statusBadgeText = Colors.grey.shade700;
    } else {
      statusBadge = 'Optimal';
      statusBadgeBg = AppTheme.emeraldMint;
      statusBadgeText = AppTheme.emeraldDarkest;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Indicateurs clés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FinancialAuditScreen()),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'Audit & Stratégie',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emeraldPine,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.emeraldPine),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Reste à vivre',
                  value: '${formatAmount(health.dailySafeToSpend)} / j',
                  badgeText: statusBadge,
                  badgeBg: statusBadgeBg,
                  badgeColor: statusBadgeText,
                  sublabel: '${health.daysRemainingInMonth}j restants',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Épargne estimée',
                  value: (health.netSavings >= 0 ? '+' : '') + formatAmount(health.netSavings),
                  badgeText: health.savingsRate > 0
                      ? '+${health.savingsRate.toStringAsFixed(0)}%'
                      : '0%',
                  badgeBg: AppTheme.emeraldSage.withValues(alpha: 0.15),
                  badgeColor: AppTheme.emeraldDarkest,
                  sublabel: 'Prévue ce mois',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FlowMiniCard(
                  label: 'Entrées du mois',
                  amount: totals.income,
                  isIncome: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FlowMiniCard(
                  label: 'Sorties du mois',
                  amount: totals.expense,
                  isIncome: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeColor,
    required this.sublabel,
  });

  final String label;
  final String value;
  final String badgeText;
  final Color badgeBg;
  final Color badgeColor;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06051F20),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowMiniCard extends StatelessWidget {
  const _FlowMiniCard({
    required this.label,
    required this.amount,
    required this.isIncome,
  });

  final String label;
  final double amount;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppTheme.income : AppTheme.expense;
    final icon = isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06051F20),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isIncome ? '+' : '-'}${formatAmount(amount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
