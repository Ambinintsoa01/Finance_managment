import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/icons_map.dart';
import '../../core/utils.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_filter_provider.dart';

Future<void> showTransactionFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const TransactionFilterSheet(),
  );
}

class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key});

  @override
  ConsumerState<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends ConsumerState<TransactionFilterSheet> {
  // État local : les changements ne s'appliquent qu'au clic sur "Appliquer",
  // pour éviter de recalculer la liste à chaque interaction dans la feuille.
  late TransactionFilter _draft;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(transactionFilterProvider);
    _minCtrl = TextEditingController(text: _draft.minAmount?.toStringAsFixed(0) ?? '');
    _maxCtrl = TextEditingController(text: _draft.maxAmount?.toStringAsFixed(0) ?? '');
    _searchCtrl = TextEditingController(text: _draft.searchText);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyQuickRange(DateTime start, DateTime end) {
    setState(() => _draft = _draft.copyWith(startDate: start, endDate: end));
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _draft.startDate : _draft.endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _draft = isStart ? _draft.copyWith(startDate: picked) : _draft.copyWith(endDate: picked);
    });
  }

  void _toggleInSet(Set<String> current, String value, void Function(Set<String>) onChanged) {
    final next = Set<String>.from(current);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    onChanged(next);
  }

  void _applyAndClose() {
    final min = double.tryParse(_minCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_maxCtrl.text.replaceAll(',', '.'));
    final finalFilter = _draft.copyWith(
      minAmount: min,
      clearMinAmount: min == null,
      maxAmount: max,
      clearMaxAmount: max == null,
      searchText: _searchCtrl.text,
    );
    ref.read(transactionFilterProvider.notifier).state = finalFilter;
    Navigator.of(context).pop();
  }

  void _resetAll() {
    setState(() {
      _draft = const TransactionFilter();
      _minCtrl.clear();
      _maxCtrl.clear();
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final now = DateTime.now();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    const Text('Filtrer les mouvements',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(onPressed: _resetAll, child: const Text('Réinitialiser')),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // --- Recherche texte ---
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher (note, catégorie, compte...)',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Période ---
                    const _SectionTitle('Période'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickChip(
                          label: "Aujourd'hui",
                          onTap: () => _applyQuickRange(now, now),
                        ),
                        _QuickChip(
                          label: '7 derniers jours',
                          onTap: () => _applyQuickRange(now.subtract(const Duration(days: 6)), now),
                        ),
                        _QuickChip(
                          label: 'Ce mois-ci',
                          onTap: () {
                            final (start, end) = periodRange(now, period: 'month');
                            _applyQuickRange(start, end.subtract(const Duration(days: 1)));
                          },
                        ),
                        _QuickChip(
                          label: 'Cette année',
                          onTap: () {
                            final (start, end) = periodRange(now, period: 'year');
                            _applyQuickRange(start, end.subtract(const Duration(days: 1)));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Du',
                            date: _draft.startDate,
                            onTap: () => _pickDate(isStart: true),
                            onClear: () => setState(() => _draft = _draft.copyWith(clearStartDate: true)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateField(
                            label: 'Au',
                            date: _draft.endDate,
                            onTap: () => _pickDate(isStart: false),
                            onClear: () => setState(() => _draft = _draft.copyWith(clearEndDate: true)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Type de mouvement ---
                    const _SectionTitle('Type de mouvement'),
                    Wrap(
                      spacing: 8,
                      children: [
                        _ToggleChip(
                          label: 'Dépenses',
                          selected: _draft.types.contains(TxType.expense),
                          color: AppTheme.expense,
                          onTap: () => setState(() => _toggleInSet(
                              _draft.types, TxType.expense, (s) => _draft = _draft.copyWith(types: s))),
                        ),
                        _ToggleChip(
                          label: 'Revenus',
                          selected: _draft.types.contains(TxType.income),
                          color: AppTheme.income,
                          onTap: () => setState(() => _toggleInSet(
                              _draft.types, TxType.income, (s) => _draft = _draft.copyWith(types: s))),
                        ),
                        _ToggleChip(
                          label: 'Transferts',
                          selected: _draft.types.contains(TxType.transfer),
                          color: AppTheme.transfer,
                          onTap: () => setState(() => _toggleInSet(
                              _draft.types, TxType.transfer, (s) => _draft = _draft.copyWith(types: s))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Comptes ---
                    if (accounts.isNotEmpty) ...[
                      const _SectionTitle('Comptes'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: accounts.map((a) {
                          final selected = _draft.accountIds.contains(a.id);
                          return _ToggleChip(
                            label: a.name,
                            selected: selected,
                            color: colorFromHex(a.color),
                            leading: Icon(iconFromKey(a.icon), size: 14,
                                color: selected ? colorFromHex(a.color) : Colors.grey.shade600),
                            onTap: () => setState(() => _toggleInSet(
                                _draft.accountIds, a.id, (s) => _draft = _draft.copyWith(accountIds: s))),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- Catégories ---
                    if (categories.isNotEmpty) ...[
                      const _SectionTitle('Catégories'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((c) {
                          final selected = _draft.categoryIds.contains(c.id);
                          return _ToggleChip(
                            label: c.name,
                            selected: selected,
                            color: colorFromHex(c.color),
                            leading: Icon(iconFromKey(c.icon), size: 14,
                                color: selected ? colorFromHex(c.color) : Colors.grey.shade600),
                            onTap: () => setState(() => _toggleInSet(
                                _draft.categoryIds, c.id, (s) => _draft = _draft.copyWith(categoryIds: s))),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- Montant ---
                    const _SectionTitle('Montant'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Min'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _maxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Max'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: ElevatedButton(
                    onPressed: _applyAndClose,
                    child: const Text('Appliquer les filtres'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      onPressed: onTap,
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: selected ? color : Colors.black87, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap, required this.onClear});
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null ? label : formatDate(date!),
                style: TextStyle(color: date == null ? Colors.grey.shade600 : Colors.black87, fontSize: 13),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }
}
