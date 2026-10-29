import 'package:drift/drift.dart';

import '../../core/utils.dart';
import '../local/database.dart';

class WishlistRepository {
  WishlistRepository(this._db);
  final AppDatabase _db;

  Stream<List<WishlistItem>> watchAll() => _db.watchAllWishlist();

  Future<void> createWishlistItem({
    required String name,
    required double amount,
    String? categoryId,
    required Duration delay, // e.g. Duration(hours: 48)
    String? note,
    String? userId,
  }) async {
    assert(amount > 0, 'Le montant doit être supérieur à 0');
    final now = DateTime.now();
    final targetDate = now.add(delay);

    await _db.upsertWishlistItem(
      WishlistItemsCompanion.insert(
        id: newId(),
        userId: Value(userId),
        name: name,
        amount: amount,
        categoryId: Value(categoryId),
        createdAt: now,
        targetDate: targetDate,
        status: const Value('waiting'),
        note: Value(note),
        updatedAt: now,
      ),
    );
  }

  /// Victoire sur une impulsion ! L'utilisateur a renoncé à la dépense.
  Future<void> markResisted(String id) =>
      _db.updateWishlistStatus(id, 'resisted');

  /// L'utilisateur a décidé d'acheter l'objet après le délai de réflexion.
  Future<void> markBought(String id) =>
      _db.updateWishlistStatus(id, 'bought');

  Future<void> deleteWishlistItem(String id) =>
      _db.softDeleteWishlistItem(id);
}
