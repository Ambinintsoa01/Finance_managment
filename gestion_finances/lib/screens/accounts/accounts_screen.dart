import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../providers/account_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/icon_avatar.dart';
import '../transactions/transfer_form_screen.dart';
import 'account_form_sheet.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes comptes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transférer entre comptes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TransferFormScreen()),
            ),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final balanceAsync = ref.watch(accountBalanceProvider(account.id));

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: IconAvatar(iconKey: account.icon, colorHex: account.color),
                  title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(AccountType.labelFor(account.type)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      balanceAsync.when(
                        loading: () => const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const Text('—'),
                        data: (balance) => Text(
                          formatAmount(balance, currency: account.currency),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: balance < 0 ? AppTheme.expense : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => showAccountFormSheet(context, account: account),
                        child: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_account',
        onPressed: () => showAccountFormSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
