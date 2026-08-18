import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../data/local/database.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_filter_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/icon_avatar.dart';
import 'transaction_filter_sheet.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsAsync = ref.watch(allTransactionsProvider);
    final filteredTxs = ref.watch(filteredTransactionsListProvider);
    final filter = ref.watch(transactionFilterProvider);
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];

    Account? accountOf(String id) => accounts.firstWhereOrNull((a) => a.id == id);
    Category? categoryOf(String? id) =>
        id == null ? null : categories.firstWhereOrNull((c) => c.id == id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mouvements'),
        actions: [
          IconButton(
            tooltip: 'Filtrer',
            onPressed: () => showTransactionFilterSheet(context),
            icon: Badge(
              isLabelVisible: filter.activeGroupCount > 0,
              label: Text('${filter.activeGroupCount}'),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (filter.isActive)
            Container(
              width: double.infinity,
              color: AppTheme.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${filteredTxs.length} résultat${filteredTxs.length > 1 ? 's' : ''} filtré${filteredTxs.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(transactionFilterProvider.notifier).state = const TransactionFilter(),
                    child: const Text('Tout effacer', style: TextStyle(fontSize: 12, color: AppTheme.primary, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: txsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (_) {
                if (filteredTxs.isEmpty) {
                  return filter.isActive
                      ? const EmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'Aucun résultat pour ces filtres',
                          subtitle: 'Essaie d\'élargir ta recherche ou de réinitialiser les filtres',
                        )
                      : const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Aucun mouvement enregistré',
                          subtitle: 'Appuie sur + pour ajouter ta première transaction',
                        );
                }

                final grouped = groupBy(filteredTxs, (Transaction t) => DateTime(t.date.year, t.date.month, t.date.day));
                final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90, top: 8),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, i) {
                    final date = dateKeys[i];
                    final dayTxs = grouped[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Text(
                            formatDate(date),
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        ...dayTxs.map((tx) {
                          final account = accountOf(tx.accountId);
                          final destAccount = accountOf(tx.destinationAccountId ?? '');
                          final category = categoryOf(tx.categoryId);
                          final isExpense = tx.type == TxType.expense;
                          final isTransfer = tx.type == TxType.transfer;
                          final color = isTransfer
                              ? AppTheme.transfer
                              : (isExpense ? AppTheme.expense : AppTheme.income);

                          final title = isTransfer
                              ? '${account?.name ?? '?'} → ${destAccount?.name ?? '?'}'
                              : (category?.name ?? 'Sans catégorie');

                          final subtitle = isTransfer
                              ? (tx.note?.isNotEmpty == true ? tx.note! : 'Transfert')
                              : '${account?.name ?? '?'}${tx.note?.isNotEmpty == true ? ' · ${tx.note}' : ''}';

                          return ListTile(
                            leading: IconAvatar(
                              iconKey: isTransfer ? 'wallet' : (category?.icon ?? 'other'),
                              colorHex: isTransfer ? '#3E7CB1' : (category?.color ?? '#999999'),
                              size: 40,
                            ),
                            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Text(
                              '${isExpense ? '-' : (isTransfer ? '' : '+')}${formatAmount(tx.amount, currency: account?.currency ?? 'MGA')}',
                              style: TextStyle(color: color, fontWeight: FontWeight.w700),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TransactionFormScreen(
                                  initialType: tx.type,
                                  editingTransaction: tx,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
