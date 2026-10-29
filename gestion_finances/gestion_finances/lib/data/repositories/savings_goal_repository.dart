import 'package:drift/drift.dart';

import '../../core/utils.dart';
import '../local/database.dart';

class SavingsGoalRepository {
  SavingsGoalRepository(this._db);
  final AppDatabase _db;

  Stream<List<SavingsGoal>> watchAll() => _db.watchAllSavingsGoals();

  Future<List<SavingsGoal>> getAllActive() => _db.getAllActiveSavingsGoals();

  Future<void> createGoal({
    required String name,
    required double targetAmount,
    double initialAmount = 0,
    DateTime? targetDate,
    String color = '#2E7D5B',
    String icon = 'savings',
    String? userId,
  }) async {
    assert(targetAmount > 0, 'Le montant cible doit être supérieur à 0');
    final now = DateTime.now();

    await _db.upsertSavingsGoal(
      SavingsGoalsCompanion.insert(
        id: newId(),
        userId: Value(userId),
        name: name,
        targetAmount: targetAmount,
        currentAmount: Value(initialAmount),
        targetDate: Value(targetDate),
        color: Value(color),
        icon: Value(icon),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateGoal(
    SavingsGoal goal, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? color,
    String? icon,
  }) async {
    await _db.upsertSavingsGoal(
      SavingsGoalsCompanion(
        id: Value(goal.id),
        userId: Value(goal.userId),
        name: Value(name ?? goal.name),
        targetAmount: Value(targetAmount ?? goal.targetAmount),
        currentAmount: Value(currentAmount ?? goal.currentAmount),
        targetDate: Value(targetDate ?? goal.targetDate),
        color: Value(color ?? goal.color),
        icon: Value(icon ?? goal.icon),
        createdAt: Value(goal.createdAt),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
  }

  Future<void> adjustFunds(String id, double delta) async {
    final goal = await _db.getSavingsGoalById(id);
    if (goal == null) return;
    final newAmount = (goal.currentAmount + delta).clamp(0.0, double.infinity);
    await _db.updateSavingsGoalAmount(id, newAmount);
  }

  Future<void> deleteGoal(String id) => _db.softDeleteSavingsGoal(id);
}
