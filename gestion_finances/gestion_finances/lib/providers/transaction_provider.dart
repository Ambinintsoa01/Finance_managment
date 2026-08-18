import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import 'database_provider.dart';

final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchAll();
});

final transactionsByAccountProvider =
    StreamProvider.family<List<Transaction>, String>((ref, accountId) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchByAccount(accountId);
});
