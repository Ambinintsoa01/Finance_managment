import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../data/local/database.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/icon_avatar.dart';
import '../../transactions/transaction_form_screen.dart';

class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsAsync = ref.watch(allTransactionsProvider);
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];

    Account? accountOf(String id) =>
        accounts.where((a) => a.id == id).firstOrNull;
    Category? categoryOf(String? id) =>
        id == null ? null : categories.where((c) => c.id == id).firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Derniers mouvements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: const Row(
                    children: [
                      Text(
                        'Voir tout',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.emeraldPine,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.emeraldPine),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Liste des 4 transactions les plus récentes
          txsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (allTxs) {
              if (allTxs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 36,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aucun mouvement récent',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final recent = allTxs.take(4).toList();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06051F20),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 64,
                    endIndent: 16,
                    color: AppTheme.cardBorder.withValues(alpha: 0.6),
                  ),
                  itemBuilder: (context, i) {
                    final tx = recent[i];
                    final account = accountOf(tx.accountId);
                    final destAccount = accountOf(tx.destinationAccountId ?? '');
                    final category = categoryOf(tx.categoryId);
                    final isExpense = tx.type == TxType.expense;
                    final isTransfer = tx.type == TxType.transfer;

                    final color = isTransfer
                        ? AppTheme.transfer
                        : (isExpense ? AppTheme.textPrimary : AppTheme.income);

                    final title = isTransfer
                        ? '${account?.name ?? '?'} → ${destAccount?.name ?? '?'}'
                        : (category?.name ?? (tx.note?.isNotEmpty == true ? tx.note! : 'Sans catégorie'));

                    final dateFormatted = DateFormat('d MMM', 'fr_FR').format(tx.date);
                    final subtitle = isTransfer
                        ? 'Virement · $dateFormatted'
                        : '${account?.name ?? '?'}${tx.note != null && tx.note!.isNotEmpty && category != null ? ' · ${tx.note}' : ''} · $dateFormatted';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: IconAvatar(
                        iconKey: isTransfer ? 'wallet' : (category?.icon ?? 'other'),
                        colorHex: isTransfer ? '#2E6F7E' : (category?.color ?? '#235347'),
                        size: 40,
                      ),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      trailing: Text(
                        '${isExpense ? '-' : (isTransfer ? '' : '+')}${formatAmount(tx.amount, currency: account?.currency ?? 'MGA')}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TransactionFormScreen(
                              initialType: tx.type,
                              editingTransaction: tx,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
