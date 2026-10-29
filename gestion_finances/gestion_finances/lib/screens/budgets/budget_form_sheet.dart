import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/utils.dart';
import '../../data/local/database.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../widgets/icon_avatar.dart';

Future<void> showBudgetFormSheet(
  BuildContext context, {
  required Category category,
  Budget? currentBudget,
  double currentSpent = 0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _BudgetFormSheet(
      category: category,
      currentBudget: currentBudget,
      currentSpent: currentSpent,
    ),
  );
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  const _BudgetFormSheet({
    required this.category,
    this.currentBudget,
    this.currentSpent = 0,
  });

  final Category category;
  final Budget? currentBudget;
  final double currentSpent;

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool get _hasBudget => widget.currentBudget != null;

  @override
  void initState() {
    super.initState();
    if (_hasBudget) {
      _amountCtrl.text = widget.currentBudget!.amount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final userId = ref.read(currentUserProvider)?.id;
    final repo = ref.read(budgetRepositoryProvider);

    await repo.setBudget(
      categoryId: widget.category.id,
      amount: amount,
      userId: userId,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Budget fixé à ${formatAmount(amount)} pour ${widget.category.name}',
          ),
          backgroundColor: AppTheme.income,
        ),
      );
    }
  }

  Future<void> _delete() async {
    if (!_hasBudget) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce budget ?'),
        content: Text(
          'Le plafond pour "${widget.category.name}" sera désactivé.',
        ),
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
      final repo = ref.read(budgetRepositoryProvider);
      await repo.deleteBudget(widget.currentBudget!.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget supprimé pour ${widget.category.name}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconAvatar(
                  iconKey: widget.category.icon,
                  colorHex: widget.category.color,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasBudget ? 'Modifier le budget' : 'Définir un budget',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.category.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.currentSpent > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Déjà dépensé ce mois : ${formatAmount(widget.currentSpent)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Plafond mensuel max (Ar)',
                hintText: 'Ex: 250000',
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Saisis un montant plafond';
                }
                final num = double.tryParse(v.replaceAll(',', '.'));
                if (num == null || num <= 0) {
                  return 'Le plafond doit être supérieur à 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_hasBudget) ...[
                  IconButton.outlined(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.expense),
                    tooltip: 'Supprimer ce budget',
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
                    label: Text(_hasBudget ? 'Mettre à jour' : 'Activer le budget'),
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
