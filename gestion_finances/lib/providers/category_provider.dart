import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import 'database_provider.dart';

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategories();
});

final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
  return categories.where((c) => c.type == 'income').toList();
});

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
  return categories.where((c) => c.type == 'expense').toList();
});
