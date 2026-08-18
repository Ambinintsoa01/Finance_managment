import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../providers/dashboard_provider.dart';

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);
    final refDate = ref.watch(dashboardReferenceDateProvider);

    String label;
    switch (period) {
      case DashboardPeriod.week:
        final (start, end) = periodRange(refDate, period: 'week');
        label = '${formatDate(start)} - ${formatDate(end.subtract(const Duration(days: 1)))}';
        break;
      case DashboardPeriod.year:
        label = '${refDate.year}';
        break;
      case DashboardPeriod.month:
        label = formatMonthYear(refDate);
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

    return Column(
      children: [
        SegmentedButton<DashboardPeriod>(
          segments: const [
            ButtonSegment(value: DashboardPeriod.week, label: Text('Semaine')),
            ButtonSegment(value: DashboardPeriod.month, label: Text('Mois')),
            ButtonSegment(value: DashboardPeriod.year, label: Text('Année')),
          ],
          selected: {period},
          onSelectionChanged: (s) => ref.read(dashboardPeriodProvider.notifier).state = s.first,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: () => shift(-1), icon: const Icon(Icons.chevron_left)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(onPressed: () => shift(1), icon: const Icon(Icons.chevron_right)),
          ],
        ),
      ],
    );
  }
}
