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

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(allTransactionsProvider);
    final filteredTxs = ref.watch(filteredTransactionsListProvider);
    final filter = ref.watch(transactionFilterProvider);
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];

    Account? accountOf(String id) => accounts.firstWhereOrNull((a) => a.id == id);
    Category? categoryOf(String? id) =>
        id == null ? null : categories.firstWhereOrNull((c) => c.id == id);

    void setTypeFilter(String? type) {
      final current = filter.types;
      Set<String> newTypes;
      if (type == null) {
        newTypes = const {};
      } else if (current.contains(type) && current.length == 1) {
        newTypes = const {};
      } else {
        newTypes = {type};
      }
      ref.read(transactionFilterProvider.notifier).state =
          filter.copyWith(types: newTypes);
    }

    final isAllType = filter.types.isEmpty;
    final isExpenseType = filter.types.contains(TxType.expense);
    final isIncomeType = filter.types.contains(TxType.income);
    final isTransferType = filter.types.contains(TxType.transfer);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mouvements'),
        actions: [
          IconButton(
            tooltip: 'Filtres avancés',
            onPressed: () => showTransactionFilterSheet(context),
            icon: Badge(
              isLabelVisible: filter.activeGroupCount > 0,
              backgroundColor: AppTheme.emeraldDarkest,
              textColor: AppTheme.emeraldMint,
              label: Text('${filter.activeGroupCount}'),
              child: const Icon(Icons.filter_list_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche pillule (comme Try "amazon" sur la maquette)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.cardBorder, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06051F20),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) {
                  ref.read(transactionFilterProvider.notifier).state =
                      filter.copyWith(searchText: val);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher une transaction...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(transactionFilterProvider.notifier).state =
                                filter.copyWith(searchText: '');
                          },
                        )
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Puces de filtre rapide (Tous, Dépenses, Revenus, Virements)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TypePill(
                  label: 'Tous',
                  isSelected: isAllType,
                  onTap: () => setTypeFilter(null),
                ),
                const SizedBox(width: 8),
                _TypePill(
                  label: 'Dépenses',
                  isSelected: isExpenseType,
                  onTap: () => setTypeFilter(TxType.expense),
                ),
                const SizedBox(width: 8),
                _TypePill(
                  label: 'Revenus',
                  isSelected: isIncomeType,
                  onTap: () => setTypeFilter(TxType.income),
                ),
                const SizedBox(width: 8),
                _TypePill(
                  label: 'Virements',
                  isSelected: isTransferType,
                  onTap: () => setTypeFilter(TxType.transfer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Alerte filtres actifs
          if (filter.isActive)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.emeraldMint.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, size: 15, color: AppTheme.emeraldDarkest),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${filteredTxs.length} résultat${filteredTxs.length > 1 ? 's' : ''} filtré${filteredTxs.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.emeraldDarkest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      ref.read(transactionFilterProvider.notifier).state =
                          const TransactionFilter();
                    },
                    child: const Text(
                      'Réinitialiser',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.emeraldDarkest,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Liste des mouvements groupée par jour
          Expanded(
            child: txsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.emeraldPine),
              ),
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

                final grouped = groupBy(
                  filteredTxs,
                  (Transaction t) => DateTime(t.date.year, t.date.month, t.date.day),
                );
                final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90, top: 4),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, i) {
                    final date = dateKeys[i];
                    final dayTxs = grouped[date]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                            child: Text(
                              formatDate(date),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.cardBorder, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x06051F20),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: dayTxs.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                indent: 64,
                                endIndent: 16,
                                color: AppTheme.cardBorder.withValues(alpha: 0.6),
                              ),
                              itemBuilder: (context, txIndex) {
                                final tx = dayTxs[txIndex];
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
                                    : (category?.name ?? 'Sans catégorie');

                                final subtitle = isTransfer
                                    ? (tx.note?.isNotEmpty == true ? tx.note! : 'Transfert')
                                    : '${account?.name ?? '?'}${tx.note?.isNotEmpty == true ? ' · ${tx.note}' : ''}';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
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
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
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
                              },
                            ),
                          ),
                        ],
                      ),
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

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldDarkest : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.emeraldDarkest : AppTheme.cardBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.emeraldDarkest.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
