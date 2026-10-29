import 'package:drift/drift.dart';

import '../../core/utils.dart';
import '../local/database.dart';

class BudgetRepository {
  BudgetRepository(this._db);
  final AppDatabase _db;

  Stream<List<Budget>> watchAll() => _db.watchAllBudgets();

  Future<List<Budget>> getAllActive() => _db.getAllActiveBudgets();

  Future<Budget?> getByCategory(String categoryId) =>
      _db.getBudgetByCategoryId(categoryId);

  /// Crée ou met à jour le plafond budgétaire d'une catégorie.
  Future<void> setBudget({
    required String categoryId,
    required double amount,
    String? userId,
  }) async {
    assert(amount > 0, 'Le montant du budget doit être supérieur à 0');
    final existing = await getByCategory(categoryId);
    final now = DateTime.now();

    if (existing != null) {
      await _db.upsertBudget(
        BudgetsCompanion(
          id: Value(existing.id),
          userId: Value(userId ?? existing.userId),
          categoryId: Value(categoryId),
          amount: Value(amount),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
          isDeleted: const Value(false),
          dirty: const Value(true),
        ),
      );
    } else {
      await _db.upsertBudget(
        BudgetsCompanion.insert(
          id: newId(),
          userId: Value(userId),
          categoryId: categoryId,
          amount: amount,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  Future<void> deleteBudget(String id) => _db.softDeleteBudget(id);
}
