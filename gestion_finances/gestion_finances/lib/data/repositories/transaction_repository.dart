import 'package:drift/drift.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../local/database.dart';

class TransactionRepository {
  TransactionRepository(this._db);
  final AppDatabase _db;

  Stream<List<Transaction>> watchAll() => _db.watchAllTransactions();

  Stream<List<Transaction>> watchByAccount(String accountId) =>
      _db.watchTransactionsByAccount(accountId);

  Future<void> createTransaction({
    required double amount,
    required String type, // income | expense | transfer
    required String accountId,
    String? destinationAccountId,
    String? categoryId,
    required DateTime date,
    String? note,
    String? userId,
  }) async {
    assert(amount > 0, 'Le montant doit être positif');
    if (type == TxType.transfer) {
      assert(destinationAccountId != null && destinationAccountId != accountId,
          'Un transfert nécessite un compte de destination différent');
    }

    final now = DateTime.now();
    await _db.upsertTransaction(
      TransactionsCompanion.insert(
        id: newId(),
        userId: Value(userId),
        accountId: accountId,
        destinationAccountId: Value(destinationAccountId),
        categoryId: Value(type == TxType.transfer ? null : categoryId),
        amount: amount,
        type: type,
        date: date,
        note: Value(note),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateTransaction(Transaction tx, {
    double? amount,
    String? accountId,
    String? destinationAccountId,
    String? categoryId,
    DateTime? date,
    String? note,
  }) async {
    await _db.upsertTransaction(
      TransactionsCompanion(
        id: Value(tx.id),
        userId: Value(tx.userId),
        accountId: Value(accountId ?? tx.accountId),
        destinationAccountId: Value(destinationAccountId ?? tx.destinationAccountId),
        categoryId: Value(categoryId ?? tx.categoryId),
        amount: Value(amount ?? tx.amount),
        type: Value(tx.type),
        date: Value(date ?? tx.date),
        note: Value(note ?? tx.note),
        createdAt: Value(tx.createdAt),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
  }

  Future<void> deleteTransaction(String id) => _db.softDeleteTransaction(id);

  /// Total des revenus / dépenses sur une liste de transactions déjà filtrée.
  ({double income, double expense}) totals(List<Transaction> txs) {
    double income = 0;
    double expense = 0;
    for (final t in txs) {
      if (t.type == TxType.income) income += t.amount;
      if (t.type == TxType.expense) expense += t.amount;
    }
    return (income: income, expense: expense);
  }

  /// Répartition des dépenses par catégorie (pour le camembert du dashboard).
  Map<String, double> expensesByCategory(List<Transaction> txs) {
    final map = <String, double>{};
    for (final t in txs) {
      if (t.type != TxType.expense || t.categoryId == null) continue;
      map[t.categoryId!] = (map[t.categoryId!] ?? 0) + t.amount;
    }
    return map;
  }
}
