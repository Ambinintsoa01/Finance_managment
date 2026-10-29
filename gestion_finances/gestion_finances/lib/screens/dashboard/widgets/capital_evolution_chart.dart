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
  const CapitalEvolutionChart({super.key, this.showCard = true});

  final bool showCard;

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
      const emptyContent = SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Aucune donnée de compte disponible',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
      if (!showCard) return emptyContent;
      return const ChartCard(
        title: 'Variation du capital',
        child: emptyContent,
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
    final lineColor = isPositive ? AppTheme.emeraldPine : AppTheme.expense;

    final chartWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  period == DashboardPeriod.week
                      ? 'en fin de semaine'
                      : (period == DashboardPeriod.month
                          ? 'en fin de mois'
                          : 'en fin d\'année'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            _VariationBadge(
              variation: data.netVariation,
              percent: data.percentageVariation,
              currency: data.currency,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
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
                  getTooltipColor: (_) => AppTheme.emeraldDarkest,
                  tooltipRoundedRadius: 10,
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          color: AppTheme.emeraldSage,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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
                horizontalInterval: (maxVal - minVal) > 0 ? (maxVal - minVal) / 4 : 1,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: AppTheme.cardBorder.withValues(alpha: 0.8),
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final x = value.toInt();
                      switch (period) {
                        case DashboardPeriod.week:
                          const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                          if (x < 0 || x >= days.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[x],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          );

                        case DashboardPeriod.month:
                          if (x < 1 || x > data.points.length) {
                            return const SizedBox.shrink();
                          }
                          if (x != 1 && x != 10 && x != 20 && x != data.points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$x',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
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
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          );
                      }
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (final p in data.points) FlSpot(p.x, p.capital),
                  ],
                  isCurved: true,
                  curveSmoothness: 0.2,
                  preventCurveOverShooting: true,
                  color: lineColor,
                  barWidth: 3,
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
                        lineColor.withValues(alpha: 0.25),
                        lineColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!showCard) return chartWidget;

    return ChartCard(
      title: 'Variation du capital',
      child: chartWidget,
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
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
