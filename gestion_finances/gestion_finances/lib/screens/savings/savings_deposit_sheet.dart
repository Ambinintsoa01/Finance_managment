import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/utils.dart';
import '../../data/local/database.dart';
import '../../providers/database_provider.dart';
import '../../widgets/icon_avatar.dart';

Future<void> showSavingsDepositSheet(
  BuildContext context, {
  required SavingsGoal goal,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SavingsDepositSheet(goal: goal),
  );
}

class _SavingsDepositSheet extends ConsumerStatefulWidget {
  const _SavingsDepositSheet({required this.goal});
  final SavingsGoal goal;

  @override
  ConsumerState<_SavingsDepositSheet> createState() => _SavingsDepositSheetState();
}

class _SavingsDepositSheetState extends ConsumerState<_SavingsDepositSheet> {
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isDeposit = true; // true = ajouter, false = retirer
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final rawAmount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final delta = _isDeposit ? rawAmount : -rawAmount;

    final repo = ref.read(savingsGoalRepositoryProvider);
    await repo.adjustFunds(widget.goal.id, delta);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDeposit
                ? '+${formatAmount(rawAmount)} ajoutés à ${widget.goal.name} !'
                : '-${formatAmount(rawAmount)} retirés de ${widget.goal.name}',
          ),
          backgroundColor: _isDeposit ? AppTheme.income : Colors.orange.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final g = widget.goal;

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
                IconAvatar(iconKey: g.icon, colorHex: g.color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Solde actuel : ${formatAmount(g.currentAmount)} / ${formatAmount(g.targetAmount)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 13,
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

            // Sélecteur Ajouter ou Retirer
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Ajouter des fonds'),
                  icon: Icon(Icons.add_circle_outline),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Retirer des fonds'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
              ],
              selected: {_isDeposit},
              onSelectionChanged: (s) => setState(() => _isDeposit = s.first),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isDeposit ? AppTheme.income : AppTheme.expense,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0 Ar',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Montant invalide';
                if (!_isDeposit && val > g.currentAmount) {
                  return 'Le montant dépasse le solde disponible (${formatAmount(g.currentAmount)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Puces de montants rapides
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [20000, 50000, 100000, 200000].map((amt) {
                return ActionChip(
                  label: Text('+${formatAmount(amt.toDouble())}'),
                  onPressed: () {
                    _amountCtrl.text = amt.toString();
                    setState(() {});
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _isDeposit ? AppTheme.income : AppTheme.expense,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isDeposit ? 'Confirmer le dépôt' : 'Confirmer le retrait',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
