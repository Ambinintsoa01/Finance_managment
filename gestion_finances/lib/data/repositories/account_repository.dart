import 'package:drift/drift.dart';

import '../../core/utils.dart';
import '../local/database.dart';

class AccountRepository {
  AccountRepository(this._db);
  final AppDatabase _db;

  Stream<List<Account>> watchAccounts() => _db.watchAllAccounts();

  Future<double> balanceOf(String accountId) => _db.getAccountBalance(accountId);

  Future<double> totalBalance() => _db.getTotalBalance();

  Future<void> createAccount({
    required String name,
    required String type,
    required double initialBalance,
    required String currency,
    required String icon,
    required String color,
    String? userId,
  }) async {
    final now = DateTime.now();
    await _db.upsertAccount(
      AccountsCompanion.insert(
        id: newId(),
        userId: Value(userId),
        name: name,
        type: type,
        initialBalance: Value(initialBalance),
        currency: Value(currency),
        icon: Value(icon),
        color: Value(color),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateAccount(Account account, {
    String? name,
    String? type,
    double? initialBalance,
    String? currency,
    String? icon,
    String? color,
  }) async {
    await _db.upsertAccount(
      AccountsCompanion(
        id: Value(account.id),
        userId: Value(account.userId),
        name: Value(name ?? account.name),
        type: Value(type ?? account.type),
        initialBalance: Value(initialBalance ?? account.initialBalance),
        currency: Value(currency ?? account.currency),
        icon: Value(icon ?? account.icon),
        color: Value(color ?? account.color),
        createdAt: Value(account.createdAt),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
  }

  Future<void> deleteAccount(String id) => _db.softDeleteAccount(id);

  /// Crée une transaction de transfert entre deux comptes.
  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String? note,
    String? userId,
  }) async {
    final now = DateTime.now();
    await _db.upsertTransaction(
      TransactionsCompanion.insert(
        id: newId(),
        userId: Value(userId),
        accountId: fromAccountId,
        destinationAccountId: Value(toAccountId),
        categoryId: const Value(null),
        amount: amount,
        type: 'transfer',
        date: date,
        note: Value(note),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
