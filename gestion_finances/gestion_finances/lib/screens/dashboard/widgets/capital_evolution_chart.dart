import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../providers/dashboard_provider.dart';
import 'chart_card.dart';

/// Graphique en ligne montrant l'évolution et la variation du capital
/// sur la période sélectionnée (semaine / mois / année).
class CapitalEvolutionChart extends ConsumerWidget {
  const CapitalEvolutionChart({super.key});

  String _formatTooltipDate(DashboardPeriod period, DateTime date) {
    switch (period) {
      case DashboardPeriod.week:
        return DateFormat('EEEE d MMM', 'fr_FR').format(date);
      case DashboardPeriod.month:
        return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
      case DashboardPeriod.year:
        return DateFormat('MMMM yyyy', 'fr_FR').format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);
    final data = ref.watch(capitalEvolutionProvider);

    if (data == null || data.points.isEmpty) {
      return const ChartCard(
        title: 'Variation du capital',
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text(
              'Aucune donnée de compte disponible',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final values = data.points.map((p) => p.capital).toList();
    var minVal = values.reduce((a, b) => a < b ? a : b);
    var maxVal = values.reduce((a, b) => a > b ? a : b);

    if (minVal == maxVal) {
      if (minVal == 0) {
        minVal = -100;
        maxVal = 100;
      } else {
        final delta = minVal.abs() * 0.1;
        minVal -= delta;
        maxVal += delta;
      }
    } else {
      final padding = (maxVal - minVal) * 0.18;
      minVal -= padding;
      maxVal += padding;
    }

    final minX = data.points.first.x;
    final maxX = data.points.last.x;

    final isPositive = data.netVariation >= 0;
    final lineColor = isPositive ? AppTheme.primary : AppTheme.expense;

    return ChartCard(
      title: 'Variation du capital',
      legend: _VariationBadge(
        variation: data.netVariation,
        percent: data.percentageVariation,
        currency: data.currency,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatAmount(data.endCapital, currency: data.currency),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                period == DashboardPeriod.week
                    ? 'en fin de semaine'
                    : (period == DashboardPeriod.month
                        ? 'en fin de mois'
                        : 'en fin d\'année'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minVal,
                maxY: maxVal,
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: lineColor.withValues(alpha: 0.4),
                          strokeWidth: 1.5,
                          dashArray: const [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, idx) =>
                              FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: lineColor,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    tooltipRoundedRadius: 8,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final point = data.points.firstWhereOrNull(
                          (p) => (p.x - spot.x).abs() < 0.1,
                        );
                        final dateStr = point != null
                            ? _formatTooltipDate(period, point.date)
                            : '';
                        return LineTooltipItem(
                          '$dateStr\n',
                          const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: formatAmount(spot.y, currency: data.currency),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final x = value.round();
                        switch (period) {
                          case DashboardPeriod.week:
                            if (x < 0 || x >= data.points.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                data.points[x].label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );

                          case DashboardPeriod.month:
                            final lastDay = data.points.length;
                            final show = x == 1 ||
                                (x % 5 == 0 && (lastDay - x) >= 2) ||
                                x == lastDay;
                            if (!show || x < 1 || x > lastDay) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '$x',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );

                          case DashboardPeriod.year:
                            if (x < 0 || x >= data.points.length) {
                              return const SizedBox.shrink();
                            }
                            if (x % 2 != 0 && x != data.points.length - 1) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                data.points[x].label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                        }
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final p in data.points) FlSpot(p.x, p.capital),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.15,
                    preventCurveOverShooting: true,
                    color: lineColor,
                    barWidth: 2.8,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: data.points.length <= 7,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: lineColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0.22),
                          lineColor.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariationBadge extends StatelessWidget {
  const _VariationBadge({
    required this.variation,
    required this.percent,
    required this.currency,
  });

  final double variation;
  final double percent;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isPositive = variation > 0;
    final isNegative = variation < 0;
    final color = isPositive
        ? AppTheme.income
        : (isNegative ? AppTheme.expense : Colors.grey.shade600);
    final icon = isPositive
        ? Icons.trending_up_rounded
        : (isNegative ? Icons.trending_down_rounded : Icons.trending_flat_rounded);
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$sign${formatAmount(variation, currency: currency)} ($sign${percent.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
