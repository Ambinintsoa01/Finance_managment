import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/icons_map.dart';
import '../../core/utils.dart';
import '../../data/local/database.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/database_provider.dart';
import '../../widgets/icon_avatar.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.initialType = TxType.expense,
    this.editingTransaction,
  });

  final String initialType;
  final Transaction? editingTransaction;

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late String _type;
  String? _accountId;
  String? _destinationAccountId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _isNeed = true;
  bool _saving = false;

  bool get _isEditing => widget.editingTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.editingTransaction;
    _type = tx?.type ?? widget.initialType;
    _accountId = tx?.accountId;
    _destinationAccountId = tx?.destinationAccountId;
    _categoryId = tx?.categoryId;
    _date = tx?.date ?? DateTime.now();
    _isNeed = tx?.isNeed ?? true;
    if (tx != null) {
      _amountCtrl.text = tx.amount.toStringAsFixed(0);
      _noteCtrl.text = tx.note ?? '';
    }
    _amountCtrl.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      _showError('Sélectionne un compte');
      return;
    }
    if (_type == TxType.transfer && (_destinationAccountId == null || _destinationAccountId == _accountId)) {
      _showError('Sélectionne un compte de destination différent du compte source');
      return;
    }
    if (_type != TxType.transfer && _categoryId == null) {
      _showError('Sélectionne une catégorie');
      return;
    }

    setState(() => _saving = true);
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final userId = ref.read(currentUserProvider)?.id;
    final repo = ref.read(transactionRepositoryProvider);

    if (_isEditing) {
      await repo.updateTransaction(
        widget.editingTransaction!,
        amount: amount,
        accountId: _accountId,
        destinationAccountId: _type == TxType.transfer ? _destinationAccountId : null,
        categoryId: _type == TxType.transfer ? null : _categoryId,
        date: _date,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        isNeed: _isNeed,
      );
    } else {
      await repo.createTransaction(
        amount: amount,
        type: _type,
        accountId: _accountId!,
        destinationAccountId: _type == TxType.transfer ? _destinationAccountId : null,
        categoryId: _type == TxType.transfer ? null : _categoryId,
        date: _date,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        isNeed: _isNeed,
        userId: userId,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Color get _typeColor {
    switch (_type) {
      case TxType.income:
        return AppTheme.income;
      case TxType.transfer:
        return AppTheme.transfer;
      default:
        return AppTheme.expense;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final categories = _type == TxType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);
    final categoryBudgets = ref.watch(monthlyCategoryBudgetsProvider);

    // Calcul de l'alerte budget en direct
    CategoryBudgetStatus? selectedBudgetStatus;
    double enteredAmount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (_type == TxType.expense && _categoryId != null) {
      for (final cb in categoryBudgets) {
        if (cb.category.id == _categoryId) {
          selectedBudgetStatus = cb;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifier le mouvement' : 'Nouveau mouvement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sélecteur de type
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: TxType.expense, label: Text('Dépense'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: TxType.income, label: Text('Revenu'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: TxType.transfer, label: Text('Transfert'), icon: Icon(Icons.swap_horiz)),
              ],
              selected: {_type},
              onSelectionChanged: _isEditing
                  ? null
                  : (s) => setState(() {
                        _type = s.first;
                        _categoryId = null;
                      }),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _typeColor.withValues(alpha: 0.15),
                selectedForegroundColor: _typeColor,
              ),
            ),
            const SizedBox(height: 20),

            // Montant
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _typeColor),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
              ),
              validator: (v) {
                final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Montant invalide';
                return null;
              },
            ),

            // Alerte budget préventive en direct
            if (selectedBudgetStatus != null && selectedBudgetStatus.hasBudget && enteredAmount > 0) ...[
              _LiveBudgetAlert(
                status: selectedBudgetStatus,
                enteredAmount: enteredAmount,
                isEditing: _isEditing,
                originalAmount: widget.editingTransaction?.amount ?? 0,
              ),
            ],

            const Divider(height: 32),

            // Compte source
            _SectionLabel(_type == TxType.transfer ? 'Compte source' : 'Compte'),
            _AccountPicker(
              accounts: accounts,
              selectedId: _accountId,
              onSelected: (id) => setState(() => _accountId = id),
            ),

            if (_type == TxType.transfer) ...[
              const SizedBox(height: 20),
              const _SectionLabel('Compte destination'),
              _AccountPicker(
                accounts: accounts.where((a) => a.id != _accountId).toList(),
                selectedId: _destinationAccountId,
                onSelected: (id) => setState(() => _destinationAccountId = id),
              ),
            ],

            if (_type != TxType.transfer) ...[
              const SizedBox(height: 20),
              const _SectionLabel('Catégorie'),
              _CategoryPicker(
                categories: categories,
                selectedId: _categoryId,
                onSelected: (id) => setState(() => _categoryId = id),
              ),
            ],

            // Nature de la dépense (Besoin vital vs Envie/Plaisir)
            if (_type == TxType.expense) ...[
              const SizedBox(height: 20),
              const _SectionLabel('Nature de la dépense (Anticipation)'),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Besoin essentiel'),
                        ],
                      ),
                      selected: _isNeed,
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) setState(() => _isNeed = true);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Envie / Plaisir'),
                        ],
                      ),
                      selected: !_isNeed,
                      selectedColor: Colors.purple.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) setState(() => _isNeed = false);
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            const _SectionLabel('Date'),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(formatDateLong(_date)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const _SectionLabel('Note (optionnel)'),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Ex : Courses au marché'),
            ),

            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: _typeColor),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enregistrer'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(databaseProvider).softDeleteTransaction(widget.editingTransaction!.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveBudgetAlert extends StatelessWidget {
  const _LiveBudgetAlert({
    required this.status,
    required this.enteredAmount,
    required this.isEditing,
    required this.originalAmount,
  });

  final CategoryBudgetStatus status;
  final double enteredAmount;
  final bool isEditing;
  final double originalAmount;

  @override
  Widget build(BuildContext context) {
    final alreadySpent = isEditing
        ? (status.spent - originalAmount).clamp(0.0, double.infinity)
        : status.spent;
    final totalProjected = alreadySpent + enteredAmount;
    final limit = status.limit;
    final isExceeded = totalProjected > limit;
    final isClose = totalProjected >= limit * 0.8 && !isExceeded;

    if (!isExceeded && !isClose) return const SizedBox.shrink();

    final color = isExceeded ? AppTheme.expense : Colors.orange.shade800;
    final bgColor = isExceeded
        ? AppTheme.expense.withValues(alpha: 0.12)
        : Colors.orange.withValues(alpha: 0.12);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isExceeded ? Icons.warning_amber_rounded : Icons.info_outline,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isExceeded
                  ? 'Alerte : cette dépense va dépasser votre budget ${status.category.name} de ${formatAmount(totalProjected - limit)} !'
                  : 'Attention : vous consommerez ${((totalProjected / limit) * 100).toStringAsFixed(0)}% du budget ${status.category.name}.',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({required this.accounts, required this.selectedId, required this.onSelected});
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Text('Aucun compte disponible', style: TextStyle(color: Colors.grey.shade600));
    }
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final a = accounts[i];
          final isSelected = a.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(a.id),
            child: Container(
              width: 96,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconAvatar(iconKey: a.icon, colorHex: a.color, size: 32),
                  const SizedBox(height: 4),
                  Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.categories, required this.selectedId, required this.onSelected});
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text('Aucune catégorie — ajoute-en une dans Réglages > Catégories', style: TextStyle(color: Colors.grey.shade600));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((c) {
        final isSelected = c.id == selectedId;
        final color = colorFromHex(c.color);
        return GestureDetector(
          onTap: () => onSelected(c.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconFromKey(c.icon), size: 16, color: color),
                const SizedBox(width: 6),
                Text(c.name, style: TextStyle(color: isSelected ? color : Colors.black87, fontSize: 13)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
