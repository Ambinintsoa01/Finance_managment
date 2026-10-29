import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/env.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/sync/sync_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/sync_provider.dart';
import '../accounts/accounts_screen.dart';
import '../audit/financial_audit_screen.dart';
import '../auth/login_screen.dart';
import '../categories/categories_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final securityState = ref.watch(securityProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Réglages & Sécurité')),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
        children: [
          // Carte statut connexion / synchro
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06051F20),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: isOnline ? AppTheme.income : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isOnline ? 'Connecté à internet' : 'Hors ligne',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(_syncIcon(syncStatus), color: _syncColor(syncStatus), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _syncLabel(syncStatus),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: syncStatus == SyncStatus.syncing
                        ? null
                        : () => ref.read(syncStatusProvider.notifier).sync(),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Synchroniser maintenant'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Compte utilisateur
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppTheme.emeraldMint,
                child: Icon(
                  user == null ? Icons.person_outline_rounded : Icons.person_rounded,
                  color: AppTheme.emeraldDarkest,
                ),
              ),
              title: Text(
                user?.email ?? 'Non connecté',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                user == null
                    ? 'Connecte-toi pour sauvegarder tes données dans le cloud'
                    : 'Synchronisation multi-appareil active',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              trailing: user == null
                  ? const Icon(Icons.chevron_right_rounded)
                  : IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppTheme.expense),
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
          const SizedBox(height: 14),

          // Accès direct : Gérer les comptes
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.emeraldPine),
              title: const Text('Gérer les comptes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Accès direct : Gérer les catégories
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: ListTile(
              leading: const Icon(Icons.category_outlined, color: AppTheme.emeraldPine),
              title: const Text('Gérer les catégories', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Accès direct : Audit Financier
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.emeraldPine),
            ),
            child: ListTile(
              leading: const Icon(Icons.insights_rounded, color: AppTheme.emeraldPine),
              title: const Text('Audit Financier & Stratégie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Règle 50/30/20, fuites d\'argent et projection', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FinancialAuditScreen()),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sécurité & Verrouillage de l'appareil
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppTheme.emeraldPine),
                      SizedBox(width: 10),
                      Text(
                        'Sécurité & Confidentialité',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.cardBorder.withValues(alpha: 0.6)),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: const Text('Verrouillage biométrique & code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text(
                    'Exiger Face Unlock, l\'empreinte ou le code de l\'appareil',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  activeColor: AppTheme.emeraldDarkest,
                  value: securityState.isSecurityEnabled,
                  onChanged: (val) async {
                    final success = await ref
                        .read(securityProvider.notifier)
                        .toggleSecurity(val);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Authentification requise pour modifier ce paramètre',
                          ),
                        ),
                      );
                    }
                  },
                ),
                if (securityState.isSecurityEnabled) ...[
                  SwitchListTile(
                    secondary: const Icon(Icons.phonelink_lock_outlined),
                    title: const Text('Verrouiller en arrière-plan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text(
                      'Reverrouille dès que vous quittez l\'application',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    activeColor: AppTheme.emeraldDarkest,
                    value: securityState.lockOnBackground,
                    onChanged: (val) {
                      ref
                          .read(securityProvider.notifier)
                          .toggleLockOnBackground(val);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_clock_outlined),
                    title: const Text('Verrouiller maintenant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Testez le verrouillage immédiatement', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      ref.read(securityProvider.notifier).lock();
                    },
                  ),
                ],
                if (!securityState.isDeviceSupported)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aucun moyen de verrouillage (PIN, mot de passe, biométrie) n\'est configuré sur cet appareil.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Informations & Statut Supabase
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuration Cloud',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  Env.isConfigured
                      ? 'Supabase : configuré'
                      : 'Supabase : non configuré (mode 100% local)',
                  style: TextStyle(
                    color: Env.isConfigured ? AppTheme.income : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Application de finances personnelles - Architecture offline-first.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return Icons.check_circle_outline_rounded;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.error:
        return Icons.error_outline_rounded;
      case SyncStatus.offline:
        return Icons.cloud_off_outlined;
      case SyncStatus.notLoggedIn:
        return Icons.lock_outline_rounded;
      case SyncStatus.idle:
        return Icons.cloud_outlined;
    }
  }

  Color _syncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return AppTheme.income;
      case SyncStatus.syncing:
        return AppTheme.emeraldPine;
      case SyncStatus.error:
        return AppTheme.expense;
      case SyncStatus.offline:
      case SyncStatus.notLoggedIn:
      case SyncStatus.idle:
        return Colors.grey;
    }
  }

  String _syncLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'Prêt à synchroniser';
      case SyncStatus.syncing:
        return 'Synchronisation en cours...';
      case SyncStatus.success:
        return 'Synchronisation réussie';
      case SyncStatus.error:
        return 'Erreur de synchronisation';
      case SyncStatus.offline:
        return 'Hors ligne — modifications enregistrées en local';
      case SyncStatus.notLoggedIn:
        return 'Non connecté au cloud';
    }
  }
}
