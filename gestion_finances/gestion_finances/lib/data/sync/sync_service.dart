import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';

import '../local/database.dart';
import '../remote/supabase_service.dart';

enum SyncStatus { idle, syncing, success, error, offline, notLoggedIn }

/// Stratégie de synchronisation "Local-First" :
///
/// 1. PUSH : toutes les lignes locales marquées `dirty = true` (créées ou
///    modifiées hors-ligne) sont envoyées vers Supabase via `upsert`.
///    Une fois confirmées côté serveur, elles sont marquées `dirty = false`.
///
/// 2. PULL : on récupère depuis Supabase toutes les lignes dont
///    `updated_at` est postérieur à la date du dernier sync réussi.
class SyncService {
  SyncService(this._db);

  final AppDatabase _db;
  final _remote = SupabaseService.instance;

  static const _lastSyncKey = 'last_sync_at';

  Future<DateTime?> _getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_lastSyncKey);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  Future<void> _setLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  Future<SyncStatus> syncAll() async {
    if (!_remote.isLoggedIn) return SyncStatus.notLoggedIn;

    try {
      await _pushAll();
      await _pullAll();
      await _setLastSync(DateTime.now());
      return SyncStatus.success;
    } catch (_) {
      return SyncStatus.error;
    }
  }

  // ---------------------------------------------------------------------
  // PUSH : local -> Supabase
  // ---------------------------------------------------------------------

  Future<void> _pushAll() async {
    final userId = _remote.currentUser!.id;

    // S'assurer que toutes les lignes locales appartiennent bien à l'utilisateur.
    await _db.claimOrphanRows(userId);

    for (final acc in await _db.getDirtyAccounts()) {
      await _remote.pushAccount({
        'id': acc.id,
        'user_id': acc.userId ?? userId,
        'name': acc.name,
        'type': acc.type,
        'initial_balance': acc.initialBalance,
        'currency': acc.currency,
        'icon': acc.icon,
        'color': acc.color,
        'created_at': acc.createdAt.toIso8601String(),
        'is_deleted': acc.isDeleted,
      });
      await _db.markAccountSynced(acc.id);
    }

    for (final cat in await _db.getDirtyCategories()) {
      await _remote.pushCategory({
        'id': cat.id,
        'user_id': cat.userId ?? userId,
        'name': cat.name,
        'type': cat.type,
        'icon': cat.icon,
        'color': cat.color,
        'is_default': cat.isDefault,
        'created_at': cat.createdAt.toIso8601String(),
        'is_deleted': cat.isDeleted,
      });
      await _db.markCategorySynced(cat.id);
    }

    for (final tx in await _db.getDirtyTransactions()) {
      await _remote.pushTransaction({
        'id': tx.id,
        'user_id': tx.userId ?? userId,
        'account_id': tx.accountId,
        'destination_account_id': tx.destinationAccountId,
        'category_id': tx.categoryId,
        'amount': tx.amount,
        'type': tx.type,
        'date': tx.date.toIso8601String(),
        'note': tx.note,
        'is_need': tx.isNeed,
        'created_at': tx.createdAt.toIso8601String(),
        'is_deleted': tx.isDeleted,
      });
      await _db.markTransactionSynced(tx.id);
    }

    try {
      for (final b in await _db.getDirtyBudgets()) {
        await _remote.pushBudget({
          'id': b.id,
          'user_id': b.userId ?? userId,
          'category_id': b.categoryId,
          'amount': b.amount,
          'created_at': b.createdAt.toIso8601String(),
          'is_deleted': b.isDeleted,
        });
        await _db.markBudgetSynced(b.id);
      }
    } catch (_) {}

    try {
      for (final r in await _db.getDirtyRecurring()) {
        await _remote.pushRecurring({
          'id': r.id,
          'user_id': r.userId ?? userId,
          'name': r.name,
          'amount': r.amount,
          'type': r.type,
          'account_id': r.accountId,
          'category_id': r.categoryId,
          'day_of_month': r.dayOfMonth,
          'note': r.note,
          'is_active': r.isActive,
          'created_at': r.createdAt.toIso8601String(),
          'is_deleted': r.isDeleted,
        });
        await _db.markRecurringSynced(r.id);
      }
    } catch (_) {}

    try {
      for (final g in await _db.getDirtySavingsGoals()) {
        await _remote.pushSavingsGoal({
          'id': g.id,
          'user_id': g.userId ?? userId,
          'name': g.name,
          'target_amount': g.targetAmount,
          'current_amount': g.currentAmount,
          'target_date': g.targetDate?.toIso8601String(),
          'color': g.color,
          'icon': g.icon,
          'created_at': g.createdAt.toIso8601String(),
          'is_deleted': g.isDeleted,
        });
        await _db.markSavingsGoalSynced(g.id);
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // PULL : Supabase -> local
  // ---------------------------------------------------------------------

  Future<void> _pullAll() async {
    final since = await _getLastSync();

    for (final row in await _remote.pullAccounts(since)) {
      final updatedAt = DateTime.parse(row['updated_at'] as String);
      await _db.upsertAccountFromRemote(
        AccountsCompanion(
          id: Value(row['id'] as String),
          userId: Value(row['user_id'] as String?),
          name: Value(row['name'] as String),
          type: Value(row['type'] as String),
          initialBalance: Value((row['initial_balance'] as num).toDouble()),
          currency: Value(row['currency'] as String),
          icon: Value(row['icon'] as String),
          color: Value(row['color'] as String),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(updatedAt),
          isDeleted: Value(row['is_deleted'] as bool),
        ),
        updatedAt,
      );
    }

    for (final row in await _remote.pullCategories(since)) {
      final updatedAt = DateTime.parse(row['updated_at'] as String);
      await _db.upsertCategoryFromRemote(
        CategoriesCompanion(
          id: Value(row['id'] as String),
          userId: Value(row['user_id'] as String?),
          name: Value(row['name'] as String),
          type: Value(row['type'] as String),
          icon: Value(row['icon'] as String),
          color: Value(row['color'] as String),
          isDefault: Value(row['is_default'] as bool),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(updatedAt),
          isDeleted: Value(row['is_deleted'] as bool),
        ),
        updatedAt,
      );
    }

    for (final row in await _remote.pullTransactions(since)) {
      final updatedAt = DateTime.parse(row['updated_at'] as String);
      await _db.upsertTransactionFromRemote(
        TransactionsCompanion(
          id: Value(row['id'] as String),
          userId: Value(row['user_id'] as String?),
          accountId: Value(row['account_id'] as String),
          destinationAccountId: Value(row['destination_account_id'] as String?),
          categoryId: Value(row['category_id'] as String?),
          amount: Value((row['amount'] as num).toDouble()),
          type: Value(row['type'] as String),
          date: Value(DateTime.parse(row['date'] as String)),
          note: Value(row['note'] as String?),
          isNeed: Value(row['is_need'] as bool? ?? true),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
          updatedAt: Value(updatedAt),
          isDeleted: Value(row['is_deleted'] as bool),
        ),
        updatedAt,
      );
    }

    try {
      for (final row in await _remote.pullBudgets(since)) {
        final updatedAt = DateTime.parse(row['updated_at'] as String);
        await _db.upsertBudgetFromRemote(
          BudgetsCompanion(
            id: Value(row['id'] as String),
            userId: Value(row['user_id'] as String?),
            categoryId: Value(row['category_id'] as String),
            amount: Value((row['amount'] as num).toDouble()),
            createdAt: Value(DateTime.parse(row['created_at'] as String)),
            updatedAt: Value(updatedAt),
            isDeleted: Value(row['is_deleted'] as bool),
          ),
          updatedAt,
        );
      }
    } catch (_) {}

    try {
      for (final row in await _remote.pullRecurring(since)) {
        final updatedAt = DateTime.parse(row['updated_at'] as String);
        await _db.upsertRecurringFromRemote(
          RecurringTransactionsCompanion(
            id: Value(row['id'] as String),
            userId: Value(row['user_id'] as String?),
            name: Value(row['name'] as String),
            amount: Value((row['amount'] as num).toDouble()),
            type: Value(row['type'] as String),
            accountId: Value(row['account_id'] as String),
            categoryId: Value(row['category_id'] as String?),
            dayOfMonth: Value(row['day_of_month'] as int),
            note: Value(row['note'] as String?),
            isActive: Value(row['is_active'] as bool? ?? true),
            createdAt: Value(DateTime.parse(row['created_at'] as String)),
            updatedAt: Value(updatedAt),
            isDeleted: Value(row['is_deleted'] as bool),
          ),
          updatedAt,
        );
      }
    } catch (_) {}

    try {
      for (final row in await _remote.pullSavingsGoals(since)) {
        final updatedAt = DateTime.parse(row['updated_at'] as String);
        await _db.upsertSavingsGoalFromRemote(
          SavingsGoalsCompanion(
            id: Value(row['id'] as String),
            userId: Value(row['user_id'] as String?),
            name: Value(row['name'] as String),
            targetAmount: Value((row['target_amount'] as num).toDouble()),
            currentAmount: Value((row['current_amount'] as num).toDouble()),
            targetDate: Value(row['target_date'] != null
                ? DateTime.parse(row['target_date'] as String)
                : null),
            color: Value(row['color'] as String? ?? '#2E7D5B'),
            icon: Value(row['icon'] as String? ?? 'savings'),
            createdAt: Value(DateTime.parse(row['created_at'] as String)),
            updatedAt: Value(updatedAt),
            isDeleted: Value(row['is_deleted'] as bool),
          ),
          updatedAt,
        );
      }
    } catch (_) {}
  }
}
