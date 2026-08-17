import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../providers/dashboard_provider.dart';
import 'chart_card.dart';

class _Bucket {
  _Bucket(this.label);
  final String label;
  double income = 0;
  double expense = 0;
}

class IncomeExpenseChart extends ConsumerWidget {
  const IncomeExpenseChart({super.key});

  List<_Bucket> _buildBuckets(DashboardPeriod period, DateTime refDate) {
    switch (period) {
      case DashboardPeriod.week:
        const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return names.map(_Bucket.new).toList();
      case DashboardPeriod.month:
        return List.generate(5, (i) => _Bucket('S${i + 1}'));
      case DashboardPeriod.year:
        return List.generate(12, (i) => _Bucket(DateFormat.MMM('fr_FR').format(DateTime(2024, i + 1))));
    }
  }

  int _bucketIndex(DashboardPeriod period, DateTime refDate, DateTime date) {
    switch (period) {
      case DashboardPeriod.week:
        return date.weekday - 1; // 0 = lundi
      case DashboardPeriod.month:
        return ((date.day - 1) / 7).floor().clamp(0, 4);
      case DashboardPeriod.year:
        return date.month - 1;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);
    final refDate = ref.watch(dashboardReferenceDateProvider);
    final txs = ref.watch(filteredTransactionsProvider);

    final buckets = _buildBuckets(period, refDate);
    for (final t in txs) {
      if (t.type != TxType.income && t.type != TxType.expense) continue;
      final idx = _bucketIndex(period, refDate, t.date).clamp(0, buckets.length - 1);
      if (t.type == TxType.income) {
        buckets[idx].income += t.amount;
      } else {
        buckets[idx].expense += t.amount;
      }
    }

    final maxY = buckets.fold<double>(
      0,
      (m, b) => [m, b.income, b.expense].reduce((a, c) => a > c ? a : c),
    );

    if (maxY == 0) {
      return const ChartCard(
        title: 'Entrées vs Sorties',
        child: SizedBox(
          height: 160,
          child: Center(child: Text('Aucune donnée sur cette période', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    return ChartCard(
      title: 'Entrées vs Sorties',
      legend: const _Legend(),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.2,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(buckets[i].label, style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: [
              for (var i = 0; i < buckets.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(toY: buckets[i].income, color: AppTheme.income, width: 7, borderRadius: BorderRadius.circular(3)),
                    BarChartRodData(toY: buckets[i].expense, color: AppTheme.expense, width: 7, borderRadius: BorderRadius.circular(3)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _Dot(color: AppTheme.income),
        SizedBox(width: 4),
        Text('Entrées', style: TextStyle(fontSize: 11)),
        SizedBox(width: 10),
        _Dot(color: AppTheme.expense),
        SizedBox(width: 4),
        Text('Sorties', style: TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
