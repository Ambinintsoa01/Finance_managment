import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../providers/account_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/icon_avatar.dart';
import '../settings/settings_screen.dart';
import '../transactions/transfer_form_screen.dart';
import 'account_form_sheet.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mes comptes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Transférer entre comptes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TransferFormScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Réglages & Sécurité',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.emeraldPine),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Aucun compte pour le moment',
              subtitle: 'Ajoute ton premier compte (Espèces, Banque, Mobile Money...)',
              action: ElevatedButton.icon(
                onPressed: () => showAccountFormSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Créer un compte'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final balanceAsync = ref.watch(accountBalanceProvider(account.id));

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06051F20),
                      blurRadius: 14,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: IconAvatar(
                    iconKey: account.icon,
                    colorHex: account.color,
                    size: 42,
                  ),
                  title: Text(
                    account.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    AccountType.labelFor(account.type),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          balanceAsync.when(
                            loading: () => const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.emeraldPine,
                              ),
                            ),
                            error: (_, __) => const Text('—'),
                            data: (balance) => Text(
                              formatAmount(balance, currency: account.currency),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: balance < 0
                                    ? AppTheme.expense
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            account.currency,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                        onPressed: () => showAccountFormSheet(context, account: account),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
