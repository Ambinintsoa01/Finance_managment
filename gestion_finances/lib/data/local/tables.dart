import 'package:drift/drift.dart';

/// Table des comptes financiers (Espèces, Banque, Mobile Money, Épargne, ...).
///
/// Le solde n'est PAS stocké directement : il est calculé dynamiquement
/// (soldeInitial + somme des transactions liées) pour éviter toute
/// incohérence entre le solde affiché et l'historique réel.
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get initialBalance =>
      real().named('initial_balance').withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('MGA'))();
  TextColumn get icon => text().withDefault(const Constant('wallet'))();
  TextColumn get color => text().withDefault(const Constant('#2E7D5B'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des catégories (Alimentation, Salaire, Transport, ...).
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // income | expense
  TextColumn get icon => text().withDefault(const Constant('category'))();
  TextColumn get color => text().withDefault(const Constant('#3E7CB1'))();
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des mouvements financiers (revenu, dépense, transfert).
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get accountId => text().named('account_id')();
  TextColumn get destinationAccountId =>
      text().named('destination_account_id').nullable()();
  TextColumn get categoryId => text().named('category_id').nullable()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // income | expense | transfer
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
