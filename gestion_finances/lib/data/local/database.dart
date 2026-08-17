import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Accounts, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  static AppDatabase? _instance;

  /// Singleton pratique pour éviter d'ouvrir plusieurs connexions SQLite.
  factory AppDatabase.instance() {
    _instance ??= AppDatabase();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------------
  // ACCOUNTS
  // ---------------------------------------------------------------------

  Stream<List<Account>> watchAllAccounts() {
    return (select(accounts)
          ..where((a) => a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm(expression: a.createdAt)]))
        .watch();
  }

  Future<Account?> getAccountById(String id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<void> upsertAccount(AccountsCompanion account) =>
      into(accounts).insertOnConflictUpdate(account);

  Future<void> softDeleteAccount(String id) =>
      (update(accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(
          isDeleted: const Value(true),
          dirty: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Solde d'un compte = solde initial + revenus - dépenses
  /// - transferts sortants + transferts entrants.
  Future<double> getAccountBalance(String accountId) async {
    final account = await getAccountById(accountId);
    if (account == null) return 0;

    final income = await _sumAmount(
      (t) =>
          t.isDeleted.equals(false) &
          t.accountId.equals(accountId) &
          t.type.equals('income'),
    );
    final expense = await _sumAmount(
      (t) =>
          t.isDeleted.equals(false) &
          t.accountId.equals(accountId) &
          t.type.equals('expense'),
    );
    final transferOut = await _sumAmount(
      (t) =>
          t.isDeleted.equals(false) &
          t.accountId.equals(accountId) &
          t.type.equals('transfer'),
    );
    final transferIn = await _sumAmount(
      (t) =>
          t.isDeleted.equals(false) &
          t.destinationAccountId.equals(accountId) &
          t.type.equals('transfer'),
    );

    return account.initialBalance + income - expense - transferOut + transferIn;
  }

  /// Solde total consolidé de tous les comptes actifs.
  Future<double> getTotalBalance() async {
    final all = await getAllActiveAccounts();
    double total = 0;
    for (final acc in all) {
      total += await getAccountBalance(acc.id);
    }
    return total;
  }

  Future<List<Account>> getAllActiveAccounts() =>
      (select(accounts)..where((a) => a.isDeleted.equals(false))).get();

  /// Émet la liste des comptes à chaque changement... des comptes OU des
  /// transactions (une nouvelle transaction change les soldes calculés
  /// sans changer la table `accounts` elle-même : ce flux combiné permet
  /// à l'UI de se rafraîchir dans les deux cas).
  Stream<List<Account>> watchAccountsWithBalanceTrigger() {
    late StreamController<List<Account>> controller;
    StreamSubscription? accSub;
    StreamSubscription? txSub;
    List<Account> lastAccounts = [];

    controller = StreamController<List<Account>>.broadcast(
      onListen: () {
        accSub = watchAllAccounts().listen((accs) {
          lastAccounts = accs;
          controller.add(accs);
        });
        txSub = watchAllTransactions().listen((_) {
          controller.add(lastAccounts);
        });
      },
      onCancel: () {
        accSub?.cancel();
        txSub?.cancel();
      },
    );
    return controller.stream;
  }

  Future<double> _sumAmount(
    Expression<bool> Function($TransactionsTable t) predicate,
  ) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(predicate(transactions));
    final row = await query.getSingleOrNull();
    return row?.read(transactions.amount.sum()) ?? 0.0;
  }

  // ---------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------

  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm(expression: c.name)]))
        .watch();
  }

  Future<Category?> getCategoryById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<void> upsertCategory(CategoriesCompanion category) =>
      into(categories).insertOnConflictUpdate(category);

  Future<void> softDeleteCategory(String id) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(
          isDeleted: const Value(true),
          dirty: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> countCategories() async {
    final rows = await select(categories).get();
    return rows.length;
  }

  // ---------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------

  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<Transaction>> watchTransactionsByAccount(String accountId) {
    return (select(transactions)
          ..where((t) =>
              t.isDeleted.equals(false) &
              (t.accountId.equals(accountId) |
                  t.destinationAccountId.equals(accountId)))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<void> upsertTransaction(TransactionsCompanion tx) =>
      into(transactions).insertOnConflictUpdate(tx);

  Future<void> softDeleteTransaction(String id) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          isDeleted: const Value(true),
          dirty: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ---------------------------------------------------------------------
  // SYNCHRONISATION
  // ---------------------------------------------------------------------

  Future<List<Account>> getDirtyAccounts() =>
      (select(accounts)..where((a) => a.dirty.equals(true))).get();
  Future<List<Category>> getDirtyCategories() =>
      (select(categories)..where((c) => c.dirty.equals(true))).get();
  Future<List<Transaction>> getDirtyTransactions() =>
      (select(transactions)..where((t) => t.dirty.equals(true))).get();

  Future<void> markAccountSynced(String id) =>
      (update(accounts)..where((a) => a.id.equals(id)))
          .write(const AccountsCompanion(dirty: Value(false)));
  Future<void> markCategorySynced(String id) =>
      (update(categories)..where((c) => c.id.equals(id)))
          .write(const CategoriesCompanion(dirty: Value(false)));
  Future<void> markTransactionSynced(String id) =>
      (update(transactions)..where((t) => t.id.equals(id)))
          .write(const TransactionsCompanion(dirty: Value(false)));

  /// Assigne un user_id à toutes les lignes locales orphelines (créées hors
  /// connexion) au moment où l'utilisateur se connecte pour la première fois.
  Future<void> claimOrphanRows(String userId) async {
    await (update(accounts)..where((a) => a.userId.isNull())).write(
      AccountsCompanion(userId: Value(userId), dirty: const Value(true)),
    );
    await (update(categories)..where((c) => c.userId.isNull())).write(
      CategoriesCompanion(userId: Value(userId), dirty: const Value(true)),
    );
    await (update(transactions)..where((t) => t.userId.isNull())).write(
      TransactionsCompanion(userId: Value(userId), dirty: const Value(true)),
    );
  }

  /// Insère ou remplace une ligne venant du cloud, seulement si la version
  /// distante est plus récente que la version locale (résolution de conflit
  /// simple : last-write-wins basé sur updated_at).
  Future<void> upsertAccountFromRemote(AccountsCompanion remote, DateTime remoteUpdatedAt) async {
    final local = await getAccountById(remote.id.value);
    if (local != null && local.updatedAt.isAfter(remoteUpdatedAt) && local.dirty) {
      return; // la version locale non-synchronisée est plus récente, on la garde
    }
    await into(accounts).insertOnConflictUpdate(
      remote.copyWith(dirty: const Value(false)),
    );
  }

  Future<void> upsertCategoryFromRemote(CategoriesCompanion remote, DateTime remoteUpdatedAt) async {
    final local = await getCategoryById(remote.id.value);
    if (local != null && local.updatedAt.isAfter(remoteUpdatedAt) && local.dirty) {
      return;
    }
    await into(categories).insertOnConflictUpdate(
      remote.copyWith(dirty: const Value(false)),
    );
  }

  Future<void> upsertTransactionFromRemote(TransactionsCompanion remote, DateTime remoteUpdatedAt) async {
    final existing = await (select(transactions)..where((t) => t.id.equals(remote.id.value))).getSingleOrNull();
    if (existing != null && existing.updatedAt.isAfter(remoteUpdatedAt) && existing.dirty) {
      return;
    }
    await into(transactions).insertOnConflictUpdate(
      remote.copyWith(dirty: const Value(false)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gestion_finances.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
