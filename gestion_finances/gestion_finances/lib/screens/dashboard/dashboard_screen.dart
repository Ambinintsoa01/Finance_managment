import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/sync_service.dart';
import '../../providers/sync_provider.dart';
import 'widgets/account_carousel.dart';
import 'widgets/balance_summary.dart';
import 'widgets/capital_evolution_chart.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/income_expense_chart.dart';
import 'widgets/period_selector.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: syncStatus == SyncStatus.syncing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Synchroniser',
            onPressed: syncStatus == SyncStatus.syncing
                ? null
                : () => ref.read(syncStatusProvider.notifier).sync(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: const [
            AccountCarousel(),
            SizedBox(height: 16),
            BalanceSummary(),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: PeriodSelector(),
            ),
            SizedBox(height: 8),
            IncomeExpenseChart(),
            CategoryPieChart(),
            CapitalEvolutionChart(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
