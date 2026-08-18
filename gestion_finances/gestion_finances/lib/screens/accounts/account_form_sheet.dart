import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/local/database.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../widgets/color_icon_picker.dart';

Future<void> showAccountFormSheet(BuildContext context, {Account? account}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AccountFormSheet(account: account),
  );
}

class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.account});
  final Account? account;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  late String _type;
  late String _currency;
  late String _color;
  late String _icon;
  bool _saving = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _balanceCtrl = TextEditingController(text: a != null ? a.initialBalance.toStringAsFixed(0) : '0');
    _type = a?.type ?? AccountType.cash;
    _currency = a?.currency ?? Currencies.all.first;
    _color = a?.color ?? AppColors.palette.first;
    _icon = a?.icon ?? AccountIcons.all.first;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(accountRepositoryProvider);
    final userId = ref.read(currentUserProvider)?.id;
    final balance = double.tryParse(_balanceCtrl.text.replaceAll(',', '.')) ?? 0;

    if (_isEditing) {
      await repo.updateAccount(
        widget.account!,
        name: _nameCtrl.text.trim(),
        type: _type,
        initialBalance: balance,
        currency: _currency,
        icon: _icon,
        color: _color,
      );
    } else {
      await repo.createAccount(
        name: _nameCtrl.text.trim(),
        type: _type,
        initialBalance: balance,
        currency: _currency,
        icon: _icon,
        color: _color,
        userId: userId,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce compte ?'),
        content: const Text(
          'Le compte et son historique de transactions seront masqués. Cette action est réversible depuis Supabase uniquement.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(databaseProvider).softDeleteAccount(widget.account!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    _isEditing ? 'Modifier le compte' : 'Nouveau compte',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _delete,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom du compte'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type de compte'),
                items: AccountType.all
                    .map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _type = v!;
                  _icon = AccountType.all.firstWhere((e) => e['value'] == v)['icon']!;
                }),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _balanceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: _isEditing ? 'Solde initial' : 'Solde de départ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Devise'),
                      items: Currencies.all
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ColorIconPicker(
                colors: AppColors.palette,
                icons: AccountIcons.all,
                selectedColor: _color,
                selectedIcon: _icon,
                onColorChanged: (c) => setState(() => _color = c),
                onIconChanged: (i) => setState(() => _icon = i),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Enregistrer' : 'Créer le compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
