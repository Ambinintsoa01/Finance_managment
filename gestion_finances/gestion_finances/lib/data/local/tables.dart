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
  /// Permet de distinguer un besoin vital (loyer, nourriture essentielle...)
  /// d'une envie/plaisir (shopping, sortie, coup de tête).
  BoolColumn get isNeed =>
      boolean().named('is_need').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des plafonds budgétaires mensuels par catégorie de dépense.
/// Utilisée pour le suivi des enveloppes et le calcul du "reste à vivre".
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get categoryId => text().named('category_id')();
  RealColumn get amount => real()(); // Plafond mensuel alloué
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des charges fixes et revenus récurrents (loyer, électricité, abonnements, salaire régulier).
/// Permet de pré-réserver ces montants sur le reste à vivre dès le 1er du mois.
class RecurringTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()(); // ex: Loyer, Facture Jirama, Internet
  RealColumn get amount => real()();
  TextColumn get type => text()(); // income | expense
  TextColumn get accountId => text().named('account_id')();
  TextColumn get categoryId => text().named('category_id').nullable()();
  IntColumn get dayOfMonth => integer().named('day_of_month')(); // 1 - 31
  TextColumn get note => text().nullable()();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des cagnottes d'épargne et fonds d'urgence.
/// Permet d'isoler l'argent économisé et de suivre la progression vers un objectif.
class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()(); // ex: Fonds d'urgence (3 mois), Achat Ordinateur
  RealColumn get targetAmount => real().named('target_amount')();
  RealColumn get currentAmount =>
      real().named('current_amount').withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().named('target_date').nullable()();
  TextColumn get color => text().withDefault(const Constant('#2E7D5B'))();
  TextColumn get icon => text().withDefault(const Constant('savings'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table du sas de réflexion anti-achats impulsifs (Wishlist 48h).
/// Permet de différer une envie d'achat non essentielle pour tester si l'envie persiste
/// et quantifier l'argent économisé grâce à la maîtrise de soi.
class WishlistItems extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()(); // ex: Montre connectée, Chaussures
  RealColumn get amount => real()();
  TextColumn get categoryId => text().named('category_id').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get targetDate => dateTime().named('target_date')(); // fin du délai de réflexion (ex: +48h)
  TextColumn get status => text().withDefault(const Constant('waiting'))(); // waiting | resisted | bought
  TextColumn get note => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
