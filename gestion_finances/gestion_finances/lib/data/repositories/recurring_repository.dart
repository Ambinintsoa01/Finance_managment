import 'package:drift/drift.dart';

import '../../core/utils.dart';
import '../local/database.dart';

class RecurringRepository {
  RecurringRepository(this._db);
  final AppDatabase _db;

  Stream<List<RecurringTransaction>> watchAll() => _db.watchAllRecurring();

  Future<List<RecurringTransaction>> getAllActive() => _db.getAllActiveRecurring();

  Future<void> createRecurring({
    required String name,
    required double amount,
    required String type, // income | expense
    required String accountId,
    String? categoryId,
    required int dayOfMonth,
    String? note,
    String? userId,
  }) async {
    assert(amount > 0, 'Le montant doit être supérieur à 0');
    assert(dayOfMonth >= 1 && dayOfMonth <= 31, 'Jour du mois invalide (1-31)');

    final now = DateTime.now();
    await _db.upsertRecurring(
      RecurringTransactionsCompanion.insert(
        id: newId(),
        userId: Value(userId),
        name: name,
        amount: amount,
        type: type,
        accountId: accountId,
        categoryId: Value(categoryId),
        dayOfMonth: dayOfMonth,
        note: Value(note),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateRecurring(
    RecurringTransaction item, {
    String? name,
    double? amount,
    String? type,
    String? accountId,
    String? categoryId,
    int? dayOfMonth,
    String? note,
    bool? isActive,
  }) async {
    await _db.upsertRecurring(
      RecurringTransactionsCompanion(
        id: Value(item.id),
        userId: Value(item.userId),
        name: Value(name ?? item.name),
        amount: Value(amount ?? item.amount),
        type: Value(type ?? item.type),
        accountId: Value(accountId ?? item.accountId),
        categoryId: Value(categoryId ?? item.categoryId),
        dayOfMonth: Value(dayOfMonth ?? item.dayOfMonth),
        note: Value(note ?? item.note),
        isActive: Value(isActive ?? item.isActive),
        createdAt: Value(item.createdAt),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
  }

  Future<void> deleteRecurring(String id) => _db.softDeleteRecurring(id);
}
