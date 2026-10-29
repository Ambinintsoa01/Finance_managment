import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../data/local/database.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../widgets/color_icon_picker.dart';

Future<void> showSavingsGoalFormSheet(
  BuildContext context, {
  SavingsGoal? editingGoal,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SavingsGoalFormSheet(editingGoal: editingGoal),
  );
}

class _SavingsGoalFormSheet extends ConsumerStatefulWidget {
  const _SavingsGoalFormSheet({this.editingGoal});
  final SavingsGoal? editingGoal;

  @override
  ConsumerState<_SavingsGoalFormSheet> createState() =>
      _SavingsGoalFormSheetState();
}

class _SavingsGoalFormSheetState extends ConsumerState<_SavingsGoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetAmountCtrl = TextEditingController();
  final _currentAmountCtrl = TextEditingController();

  DateTime? _targetDate;
  String _color = AppColors.palette.first;
  String _icon = 'savings';
  bool _saving = false;

  bool get _isEditing => widget.editingGoal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.editingGoal;
    if (g != null) {
      _nameCtrl.text = g.name;
      _targetAmountCtrl.text = g.targetAmount.toStringAsFixed(0);
      _currentAmountCtrl.text = g.currentAmount.toStringAsFixed(0);
      _targetDate = g.targetDate;
      _color = g.color;
      _icon = g.icon;
    } else {
      _currentAmountCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetAmountCtrl.dispose();
    _currentAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final target =
        double.tryParse(_targetAmountCtrl.text.replaceAll(',', '.')) ?? 0;
    final current =
        double.tryParse(_currentAmountCtrl.text.replaceAll(',', '.')) ?? 0;
    final userId = ref.read(currentUserProvider)?.id;
    final repo = ref.read(savingsGoalRepositoryProvider);

    if (_isEditing) {
      await repo.updateGoal(
        widget.editingGoal!,
        name: _nameCtrl.text.trim(),
        targetAmount: target,
        currentAmount: current,
        targetDate: _targetDate,
        color: _color,
        icon: _icon,
      );
    } else {
      await repo.createGoal(
        name: _nameCtrl.text.trim(),
        targetAmount: target,
        initialAmount: current,
        targetDate: _targetDate,
        color: _color,
        icon: _icon,
        userId: userId,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Cagnotte mise à jour' : 'Cagnotte créée avec succès !',
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
        title: const Text('Supprimer cette cagnotte ?'),
        content: Text('Voulez-vous supprimer "${widget.editingGoal!.name}" ?'),
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
      await ref
          .read(savingsGoalRepositoryProvider)
          .deleteGoal(widget.editingGoal!.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cagnotte supprimée')),
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
                        ? 'Modifier la cagnotte'
                        : 'Nouvel objectif d\'épargne',
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
              const SizedBox(height: 12),

              // Suggestions rapides de noms si création
              if (!_isEditing) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    '🛡️ Fonds d\'urgence',
                    '💻 Matériel / Projet',
                    '✈️ Voyage',
                    '🏠 Logement',
                  ].map((s) {
                    return ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        // Supprime l'émoji du début
                        final cleaned = s.replaceFirst(RegExp(r'^[^\w\s]+'), '').trim();
                        _nameCtrl.text = cleaned;
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Nom
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'objectif',
                  hintText: 'Ex: Fonds d\'urgence (3 mois), Achat Ordinateur',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Saisis un nom' : null,
              ),
              const SizedBox(height: 14),

              // Montants Cible & Actuel
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetAmountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Montant cible (Ar)',
                        hintText: 'Ex: 1500000',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      validator: (v) {
                        final val =
                            double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (val == null || val <= 0) return 'Montant invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _currentAmountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Déjà épargné (Ar)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Date cible (optionnelle)
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _targetDate != null
                              ? 'Date cible : ${formatDateLong(_targetDate!)}'
                              : 'Date cible (optionnelle)',
                          style: TextStyle(
                            color: _targetDate != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (_targetDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _targetDate = null),
                          child: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sélecteur Couleur & Icône
              ColorIconPicker(
                colors: AppColors.palette,
                icons: const [
                  'savings',
                  'wallet',
                  'cash',
                  'bank',
                  'home',
                  'transport',
                  'health',
                  'shopping',
                  'travel',
                  'gift',
                ],
                selectedColor: _color,
                selectedIcon: _icon,
                onColorChanged: (c) => setState(() => _color = c),
                onIconChanged: (i) => setState(() => _icon = i),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  if (_isEditing) ...[
                    IconButton.outlined(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.expense,
                      ),
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
                      label: Text(_isEditing ? 'Enregistrer' : 'Créer la cagnotte'),
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
