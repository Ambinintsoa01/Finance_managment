import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../data/sync/sync_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../settings/settings_screen.dart';
import 'widgets/account_chip_bar.dart';
import 'widgets/dashboard_analytics_section.dart';
import 'widgets/hero_balance_card.dart';
import 'widgets/minimal_stat_grid.dart';
import 'widgets/recent_transactions_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.onNavigateToTransactions});

  final VoidCallback? onNavigateToTransactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final user = ref.watch(currentUserProvider);

    // Extraction du prénom ou salutation
    String greeting = 'Bonjour 👋';
    if (user?.email != null && user!.email!.isNotEmpty) {
      final namePart = user.email!.split('@').first;
      final capitalized = namePart[0].toUpperCase() + namePart.substring(1);
      greeting = 'Bonjour, $capitalized';
    }

    final dateFormatted = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final capitalizedDate = dateFormatted[0].toUpperCase() + dateFormatted.substring(1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              capitalizedDate,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Bouton Synchronisation Cloud
          IconButton(
            icon: syncStatus == SyncStatus.syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldPine),
                  )
                : Icon(
                    Icons.cloud_done_outlined,
                    color: syncStatus == SyncStatus.error ? AppTheme.expense : AppTheme.emeraldPine,
                    size: 22,
                  ),
            tooltip: 'Synchroniser avec le cloud',
            onPressed: syncStatus == SyncStatus.syncing
                ? null
                : () => ref.read(syncStatusProvider.notifier).sync(),
          ),

          // Avatar / Paramètres (comme la photo de profil en haut à droite sur la maquette)
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.emeraldMint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cardBorder, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    user != null && user.email != null && user.email!.isNotEmpty
                        ? user.email![0].toUpperCase()
                        : 'J',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.emeraldDarkest,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.emeraldPine,
        onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 90),
          children: [
            // Carte Solde Hero (Inspirée de la maquette Screen 1 & 2)
            const HeroBalanceCard(),
            const SizedBox(height: 14),

            // Barre de sélection rapide de comptes (puces horizontales sans encombrement)
            const AccountChipBar(),
            const SizedBox(height: 22),

            // Indicateurs clés légers et aérés (comme Bearish / Bullish sur la maquette)
            const MinimalStatGrid(),
            const SizedBox(height: 24),

            // Section interactive des analyses et graphiques (1 seul conteneur épuré avec onglets)
            const DashboardAnalyticsSection(),
            const SizedBox(height: 24),

            // Derniers mouvements récents (comme Stock Activities sur la maquette)
            RecentTransactionsSection(
              onViewAll: onNavigateToTransactions,
            ),
          ],
        ),
      ),
    );
  }
}
