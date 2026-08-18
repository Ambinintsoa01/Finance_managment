import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/sync_service.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';
import 'database_provider.dart';

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier(ref);
});

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier(this._ref) : super(SyncStatus.idle) {
    // Tente une synchronisation automatique dès qu'une connexion revient
    // et que l'utilisateur est connecté.
    _ref.listen(isOnlineProvider, (previous, online) {
      if (online && (previous == false || previous == null)) {
        sync();
      }
    });
  }

  final Ref _ref;

  Future<void> sync() async {
    final online = _ref.read(isOnlineProvider);
    if (!online) {
      state = SyncStatus.offline;
      return;
    }
    if (!_ref.read(isLoggedInProvider)) {
      state = SyncStatus.notLoggedIn;
      return;
    }

    state = SyncStatus.syncing;
    final service = _ref.read(syncServiceProvider);
    final result = await service.syncAll();
    state = result;
  }
}
