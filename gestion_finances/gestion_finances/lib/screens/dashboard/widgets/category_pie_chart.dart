import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../../core/app_theme.dart';
import '../../../core/icons_map.dart';
import '../../../core/utils.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/dashboard_provider.dart';
import 'chart_card.dart';

class CategoryPieChart extends ConsumerStatefulWidget {
  const CategoryPieChart({super.key, this.showCard = true});

  final bool showCard;

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final expensesByCategory = ref.watch(expensesByCategoryProvider);
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];

    Widget content;

    if (expensesByCategory.isEmpty) {
      content = const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Aucune dépense sur cette période',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    } else {
      final entries = expensesByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final total = entries.fold<double>(0, (s, e) => s + e.value);

      content = Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 32,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response?.touchedSection?.touchedSectionIndex;
                    });
                  },
                ),
                sections: [
                  for (var i = 0; i < entries.length; i++)
                    () {
                      final category = categories.where((c) => c.id == entries[i].key).firstOrNull;
                      final color = colorFromHex(category?.color ?? '#235347');
                      final isTouched = i == _touchedIndex;
                      return PieChartSectionData(
                        color: color,
                        value: entries[i].value,
                        radius: isTouched ? 32 : 26,
                        showTitle: false,
                      );
                    }(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < entries.length && i < 4; i++)
                  () {
                    final category = categories.where((c) => c.id == entries[i].key).firstOrNull;
                    final color = colorFromHex(category?.color ?? '#235347');
                    final percent = total == 0 ? 0 : (entries[i].value / total * 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category?.name ?? 'Autre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${percent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }(),
                if (entries.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${entries.length - 4} autres catégories',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    if (!widget.showCard) {
      return content;
    }

    return ChartCard(
      title: 'Dépenses par catégorie',
      child: content,
    );
  }
}
