import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import 'account_provider.dart';
import 'category_provider.dart';
import 'transaction_provider.dart';

/// Ensemble des critères de filtre applicables à la liste de mouvements.
/// Immuable : chaque modification passe par [copyWith].
class TransactionFilter {
  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.categoryIds = const {},
    this.accountIds = const {},
    this.types = const {},
    this.minAmount,
    this.maxAmount,
    this.searchText = '',
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> categoryIds;
  final Set<String> accountIds;
  final Set<String> types; // income | expense | transfer
  final double? minAmount;
  final double? maxAmount;
  final String searchText;

  bool get isActive =>
      startDate != null ||
      endDate != null ||
      categoryIds.isNotEmpty ||
      accountIds.isNotEmpty ||
      types.isNotEmpty ||
      minAmount != null ||
      maxAmount != null ||
      searchText.trim().isNotEmpty;

  /// Nombre de groupes de critères actifs (pour le badge sur le bouton filtre).
  int get activeGroupCount {
    var count = 0;
    if (startDate != null || endDate != null) count++;
    if (categoryIds.isNotEmpty) count++;
    if (accountIds.isNotEmpty) count++;
    if (types.isNotEmpty) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (searchText.trim().isNotEmpty) count++;
    return count;
  }

  TransactionFilter copyWith({
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    Set<String>? categoryIds,
    Set<String>? accountIds,
    Set<String>? types,
    double? minAmount,
    bool clearMinAmount = false,
    double? maxAmount,
    bool clearMaxAmount = false,
    String? searchText,
  }) {
    return TransactionFilter(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      categoryIds: categoryIds ?? this.categoryIds,
      accountIds: accountIds ?? this.accountIds,
      types: types ?? this.types,
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      searchText: searchText ?? this.searchText,
    );
  }
}

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());

/// Liste des mouvements après application du filtre actif.
final filteredTransactionsListProvider = Provider<List<Transaction>>((ref) {
  final all = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final filter = ref.watch(transactionFilterProvider);
  if (!filter.isActive) return all;

  final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
  final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
  final query = filter.searchText.trim().toLowerCase();

  String categoryName(String? id) =>
      categories.firstWhereOrNull((c) => c.id == id)?.name ?? '';
  String accountName(String id) =>
      accounts.firstWhereOrNull((a) => a.id == id)?.name ?? '';

  return all.where((t) {
    if (filter.startDate != null) {
      final start = DateTime(filter.startDate!.year, filter.startDate!.month, filter.startDate!.day);
      if (t.date.isBefore(start)) return false;
    }
    if (filter.endDate != null) {
      final endExclusive = DateTime(filter.endDate!.year, filter.endDate!.month, filter.endDate!.day + 1);
      if (!t.date.isBefore(endExclusive)) return false;
    }
    if (filter.categoryIds.isNotEmpty) {
      if (t.categoryId == null || !filter.categoryIds.contains(t.categoryId)) return false;
    }
    if (filter.accountIds.isNotEmpty) {
      final matches = filter.accountIds.contains(t.accountId) ||
          (t.destinationAccountId != null && filter.accountIds.contains(t.destinationAccountId));
      if (!matches) return false;
    }
    if (filter.types.isNotEmpty && !filter.types.contains(t.type)) return false;
    if (filter.minAmount != null && t.amount < filter.minAmount!) return false;
    if (filter.maxAmount != null && t.amount > filter.maxAmount!) return false;
    if (query.isNotEmpty) {
      final haystack = [
        t.note ?? '',
        categoryName(t.categoryId),
        accountName(t.accountId),
        if (t.destinationAccountId != null) accountName(t.destinationAccountId!),
      ].join(' ').toLowerCase();
      if (!haystack.contains(query)) return false;
    }
    return true;
  }).toList();
});
