import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/icons_map.dart';
import '../../data/local/database.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/database_provider.dart';

Future<void> showRecurringFormSheet(
  BuildContext context, {
  RecurringTransaction? editingItem,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _RecurringFormSheet(editingItem: editingItem),
  );
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  const _RecurringFormSheet({this.editingItem});
  final RecurringTransaction? editingItem;

  @override
  ConsumerState<_RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late String _type;
  String? _accountId;
  String? _categoryId;
  bool _saving = false;

  bool get _isEditing => widget.editingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editingItem;
    _type = item?.type ?? TxType.expense;
    _accountId = item?.accountId;
    _categoryId = item?.categoryId;
    if (item != null) {
      _nameCtrl.text = item.name;
      _amountCtrl.text = item.amount.toStringAsFixed(0);
      _dayCtrl.text = item.dayOfMonth.toString();
      _noteCtrl.text = item.note ?? '';
    } else {
      _dayCtrl.text = '5'; // 5 par défaut
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _dayCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionne un compte associé')),
      );
      return;
    }

    setState(() => _saving = true);
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final day = int.tryParse(_dayCtrl.text) ?? 1;
    final userId = ref.read(currentUserProvider)?.id;
    final repo = ref.read(recurringRepositoryProvider);

    if (_isEditing) {
      await repo.updateRecurring(
        widget.editingItem!,
        name: _nameCtrl.text.trim(),
        amount: amount,
        type: _type,
        accountId: _accountId,
        categoryId: _categoryId,
        dayOfMonth: day,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
    } else {
      await repo.createRecurring(
        name: _nameCtrl.text.trim(),
        amount: amount,
        type: _type,
        accountId: _accountId!,
        categoryId: _categoryId,
        dayOfMonth: day,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        userId: userId,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Charge récurrente mise à jour'
                : 'Charge récurrente créée',
          ),
          backgroundColor: AppTheme.income,
        ),
      );
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette charge récurrente ?'),
        content: Text('Voulez-vous supprimer "${widget.editingItem!.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _saving = true);
      await ref.read(recurringRepositoryProvider).deleteRecurring(widget.editingItem!.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Charge récurrente supprimée')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final categories = _type == TxType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing
                        ? 'Modifier la charge fixe'
                        : 'Nouvelle charge / revenu récurrent',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Sélecteur Type
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: TxType.expense,
                    label: Text('Charge fixe (Dépense)'),
                    icon: Icon(Icons.receipt_long),
                  ),
                  ButtonSegment(
                    value: TxType.income,
                    label: Text('Revenu régulier'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 16),

              // Intitulé
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de la charge',
                  hintText: 'Ex: Loyer, Facture Jirama, Internet, Salaire',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Saisis un nom' : null,
              ),
              const SizedBox(height: 14),

              // Montant & Jour du mois
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Montant (Ar)',
                        hintText: 'Ex: 400000',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                      validator: (v) {
                        final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (val == null || val <= 0) return 'Montant invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _dayCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jour du mois',
                        hintText: '1 - 31',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (v) {
                        final d = int.tryParse(v ?? '');
                        if (d == null || d < 1 || d > 31) return '1-31';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Compte
              DropdownButtonFormField<String>(
                value: _accountId,
                decoration: const InputDecoration(
                  labelText: 'Compte associé',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: accounts.map((a) {
                  return DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name),
                  );
                }).toList(),
                onChanged: (id) => setState(() => _accountId = id),
                validator: (v) => v == null ? 'Sélectionne un compte' : null,
              ),
              const SizedBox(height: 14),

              // Catégorie
              if (categories.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie (optionnelle)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Aucune')),
                    ...categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Icon(iconFromKey(c.icon), size: 16),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: 14),
              ],

              // Note
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optionnelle)',
                  hintText: 'Ex: Payable avant le 10',
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  if (_isEditing) ...[
                    IconButton.outlined(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.expense),
                      onPressed: _saving ? null : _delete,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isEditing ? 'Enregistrer' : 'Créer la charge'),
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
