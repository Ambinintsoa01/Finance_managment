import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/env.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/sync/sync_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/sync_provider.dart';
import '../categories/categories_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte statut connexion / synchro
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off,
                        color: isOnline ? AppTheme.income : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(isOnline ? 'Connecté à internet' : 'Hors ligne',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(_syncIcon(syncStatus), color: _syncColor(syncStatus), size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_syncLabel(syncStatus))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: syncStatus == SyncStatus.syncing
                          ? null
                          : () => ref.read(syncStatusProvider.notifier).sync(),
                      icon: const Icon(Icons.sync),
                      label: const Text('Synchroniser maintenant'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Compte utilisateur
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                child: Icon(user == null ? Icons.person_outline : Icons.person, color: AppTheme.primary),
              ),
              title: Text(user?.email ?? 'Non connecté'),
              subtitle: Text(user == null
                  ? 'Connecte-toi pour sauvegarder tes données dans le cloud'
                  : 'Synchronisation multi-appareil active'),
              trailing: user == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: () async {
                        await SupabaseService.instance.signOut();
                      },
                    ),
              onTap: user == null
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Gérer les catégories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!Env.isConfigured)
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '⚠️ Synchronisation cloud non configurée.\n\n'
                  "Renseigne SUPABASE_URL et SUPABASE_ANON_KEY dans lib/core/env.dart "
                  "pour activer la sauvegarde et le multi-appareil (voir README).",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),

          const SizedBox(height: 24),
          Center(
            child: Text('Mes Finances · v1.0.0', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  IconData _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return Icons.check_circle_outline;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.error:
        return Icons.error_outline;
      case SyncStatus.offline:
        return Icons.cloud_off_outlined;
      case SyncStatus.notLoggedIn:
        return Icons.lock_outline;
      case SyncStatus.idle:
        return Icons.cloud_outlined;
    }
  }

  Color _syncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return AppTheme.income;
      case SyncStatus.error:
        return AppTheme.expense;
      default:
        return Colors.grey;
    }
  }

  String _syncLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return 'Dernière synchronisation réussie';
      case SyncStatus.syncing:
        return 'Synchronisation en cours...';
      case SyncStatus.error:
        return 'Erreur lors de la synchronisation';
      case SyncStatus.offline:
        return 'Pas de connexion — les données seront synchronisées dès le retour du réseau';
      case SyncStatus.notLoggedIn:
        return 'Connecte-toi pour activer la synchronisation';
      case SyncStatus.idle:
        return 'En attente de synchronisation';
    }
  }
}
