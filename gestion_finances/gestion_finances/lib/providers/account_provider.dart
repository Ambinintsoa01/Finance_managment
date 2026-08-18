import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import 'database_provider.dart';

/// Liste des comptes, se rafraîchit aussi quand une transaction change
/// (car les soldes affichés en dépendent).
final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAccountsWithBalanceTrigger();
});

/// Solde calculé d'un compte précis.
final accountBalanceProvider =
    FutureProvider.family<double, String>((ref, accountId) async {
  ref.watch(accountsStreamProvider);
  final repo = ref.watch(accountRepositoryProvider);
  return repo.balanceOf(accountId);
});

/// Solde total consolidé de tous les comptes.
final totalBalanceProvider = FutureProvider<double>((ref) async {
  ref.watch(accountsStreamProvider);
  final repo = ref.watch(accountRepositoryProvider);
  return repo.totalBalance();
});

/// Compte actuellement sélectionné sur le Dashboard (null = tous les comptes).
final selectedAccountIdProvider = StateProvider<String?>((ref) => null);
