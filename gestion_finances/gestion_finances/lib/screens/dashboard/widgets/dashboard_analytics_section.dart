import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../providers/dashboard_provider.dart';
import '../../audit/financial_audit_screen.dart';
import 'capital_evolution_chart.dart';
import 'category_pie_chart.dart';
import 'income_expense_chart.dart';

enum AnalyticsViewTab {
  flow,
  category,
  evolution,
}

class DashboardAnalyticsSection extends ConsumerStatefulWidget {
  const DashboardAnalyticsSection({super.key});

  @override
  ConsumerState<DashboardAnalyticsSection> createState() =>
      _DashboardAnalyticsSectionState();
}

class _DashboardAnalyticsSectionState
    extends ConsumerState<DashboardAnalyticsSection> {
  AnalyticsViewTab _currentTab = AnalyticsViewTab.flow;

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(dashboardPeriodProvider);
    final refDate = ref.watch(dashboardReferenceDateProvider);

    String dateLabel;
    switch (period) {
      case DashboardPeriod.week:
        final (start, end) = periodRange(refDate, period: 'week');
        dateLabel =
            '${formatDate(start)} - ${formatDate(end.subtract(const Duration(days: 1)))}';
        break;
      case DashboardPeriod.year:
        dateLabel = '${refDate.year}';
        break;
      case DashboardPeriod.month:
        dateLabel = formatMonthYear(refDate);
        break;
    }

    void shift(int direction) {
      final notifier = ref.read(dashboardReferenceDateProvider.notifier);
      switch (period) {
        case DashboardPeriod.week:
          notifier.state = refDate.add(Duration(days: 7 * direction));
          break;
        case DashboardPeriod.month:
          notifier.state = DateTime(refDate.year, refDate.month + direction, 1);
          break;
        case DashboardPeriod.year:
          notifier.state = DateTime(refDate.year + direction, refDate.month, 1);
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06051F20),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Titre & Lien vers l'audit complet
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analyses & Tendances',
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
                      'Audit complet',
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
          const SizedBox(height: 14),

          // Sélecteur d'onglets (Flux / Catégories / Évolution)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabPill(
                    label: 'Flux',
                    isSelected: _currentTab == AnalyticsViewTab.flow,
                    onTap: () => setState(() => _currentTab = AnalyticsViewTab.flow),
                  ),
                ),
                Expanded(
                  child: _TabPill(
                    label: 'Catégories',
                    isSelected: _currentTab == AnalyticsViewTab.category,
                    onTap: () => setState(() => _currentTab = AnalyticsViewTab.category),
                  ),
                ),
                Expanded(
                  child: _TabPill(
                    label: 'Évolution',
                    isSelected: _currentTab == AnalyticsViewTab.evolution,
                    onTap: () => setState(() => _currentTab = AnalyticsViewTab.evolution),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Ligne de filtre temporel (Semaine / Mois / Année + chevrons)
          Row(
            children: [
              // Puces de période (inspirées de 1D, 5D, 1M dans la maquette)
              _PeriodChip(
                label: 'Semaine',
                isSelected: period == DashboardPeriod.week,
                onTap: () => ref.read(dashboardPeriodProvider.notifier).state =
                    DashboardPeriod.week,
              ),
              const SizedBox(width: 6),
              _PeriodChip(
                label: 'Mois',
                isSelected: period == DashboardPeriod.month,
                onTap: () => ref.read(dashboardPeriodProvider.notifier).state =
                    DashboardPeriod.month,
              ),
              const SizedBox(width: 6),
              _PeriodChip(
                label: 'Année',
                isSelected: period == DashboardPeriod.year,
                onTap: () => ref.read(dashboardPeriodProvider.notifier).state =
                    DashboardPeriod.year,
              ),

              const Spacer(),

              // Navigation temporelle
              InkWell(
                onTap: () => shift(-1),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left_rounded, size: 20, color: AppTheme.textSecondary),
                ),
              ),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: () => shift(1),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Graphique actif
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildActiveChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChart() {
    switch (_currentTab) {
      case AnalyticsViewTab.flow:
        return const IncomeExpenseChart(
          key: ValueKey('analytics_flow'),
          showCard: false,
        );
      case AnalyticsViewTab.category:
        return const CategoryPieChart(
          key: ValueKey('analytics_category'),
          showCard: false,
        );
      case AnalyticsViewTab.evolution:
        return const CapitalEvolutionChart(
          key: ValueKey('analytics_evolution'),
          showCard: false,
        );
    }
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldDarkest : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.emeraldMint
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? AppTheme.emeraldDarkest
                : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
