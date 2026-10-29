import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import 'database_provider.dart';

final allSavingsGoalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final repo = ref.watch(savingsGoalRepositoryProvider);
  return repo.watchAll();
});

class SavingsGoalsSummary {
  final double totalTarget;
  final double totalSaved;
  final double progress;
  final List<SavingsGoal> goals;

  const SavingsGoalsSummary({
    required this.totalTarget,
    required this.totalSaved,
    required this.progress,
    required this.goals,
  });
}

final savingsGoalsSummaryProvider = Provider<SavingsGoalsSummary>((ref) {
  final goals = ref.watch(allSavingsGoalsProvider).valueOrNull ?? [];

  double totalTarget = 0;
  double totalSaved = 0;

  for (final g in goals) {
    totalTarget += g.targetAmount;
    totalSaved += g.currentAmount;
  }

  final progress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

  return SavingsGoalsSummary(
    totalTarget: totalTarget,
    totalSaved: totalSaved,
    progress: progress,
    goals: goals,
  );
});
