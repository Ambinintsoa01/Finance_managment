import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../../core/icons_map.dart';
import '../../../core/utils.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/dashboard_provider.dart';
import 'chart_card.dart';

class CategoryPieChart extends ConsumerStatefulWidget {
  const CategoryPieChart({super.key});

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final expensesByCategory = ref.watch(expensesByCategoryProvider);
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];

    if (expensesByCategory.isEmpty) {
      return const ChartCard(
        title: 'Dépenses par catégorie',
        child: SizedBox(
          height: 160,
          child: Center(child: Text('Aucune dépense sur cette période', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    final entries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return ChartCard(
      title: 'Dépenses par catégorie',
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
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
                      final color = colorFromHex(category?.color ?? '#9E9E9E');
                      final isTouched = i == _touchedIndex;
                      return PieChartSectionData(
                        color: color,
                        value: entries[i].value,
                        radius: isTouched ? 34 : 28,
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
              children: [
                for (var i = 0; i < entries.length && i < 5; i++)
                  () {
                    final category = categories.where((c) => c.id == entries[i].key).firstOrNull;
                    final color = colorFromHex(category?.color ?? '#9E9E9E');
                    final percent = total == 0 ? 0 : (entries[i].value / total * 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(iconFromKey(category?.icon ?? 'other'), size: 14, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              category?.name ?? '?',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    );
                  }(),
                if (entries.length > 5)
                  Text('+ ${entries.length - 5} autres', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
