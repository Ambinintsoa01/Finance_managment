import 'package:drift/drift.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../local/database.dart';

class CategoryRepository {
  CategoryRepository(this._db);
  final AppDatabase _db;

  Stream<List<Category>> watchCategories() => _db.watchAllCategories();

  Future<void> createCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
    String? userId,
    bool isDefault = false,
  }) async {
    final now = DateTime.now();
    await _db.upsertCategory(
      CategoriesCompanion.insert(
        id: newId(),
        userId: Value(userId),
        name: name,
        type: type,
        icon: Value(icon),
        color: Value(color),
        isDefault: Value(isDefault),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateCategory(Category category, {
    String? name,
    String? icon,
    String? color,
  }) async {
    await _db.upsertCategory(
      CategoriesCompanion(
        id: Value(category.id),
        userId: Value(category.userId),
        name: Value(name ?? category.name),
        type: Value(category.type),
        icon: Value(icon ?? category.icon),
        color: Value(color ?? category.color),
        isDefault: Value(category.isDefault),
        createdAt: Value(category.createdAt),
        updatedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
  }

  Future<void> deleteCategory(String id) => _db.softDeleteCategory(id);

  /// Insère les catégories par défaut si la base est vide (première ouverture).
  Future<void> seedDefaultCategoriesIfEmpty({String? userId}) async {
    final count = await _db.countCategories();
    if (count > 0) return;

    for (var i = 0; i < DefaultCategories.all.length; i++) {
      final def = DefaultCategories.all[i];
      await createCategory(
        name: def['name']!,
        type: def['type']!,
        icon: def['icon']!,
        color: AppColors.palette[i % AppColors.palette.length],
        userId: userId,
        isDefault: true,
      );
    }
  }
}
