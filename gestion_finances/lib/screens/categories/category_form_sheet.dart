import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/local/database.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../widgets/color_icon_picker.dart';

Future<void> showCategoryFormSheet(BuildContext context, {required String type, Category? category}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CategoryFormSheet(type: type, category: category),
  );
}

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, required this.type, this.category});
  final String type;
  final Category? category;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late String _color;
  late String _icon;
  bool _saving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _color = widget.category?.color ?? AppColors.palette.first;
    _icon = widget.category?.icon ?? CategoryIcons.all.first;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(categoryRepositoryProvider);
    final userId = ref.read(currentUserProvider)?.id;

    if (_isEditing) {
      await repo.updateCategory(widget.category!, name: _nameCtrl.text.trim(), icon: _icon, color: _color);
    } else {
      await repo.createCategory(
        name: _nameCtrl.text.trim(),
        type: widget.type,
        icon: _icon,
        color: _color,
        userId: userId,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).softDeleteCategory(widget.category!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    _isEditing ? 'Modifier la catégorie' : (widget.type == TxType.income ? 'Nouvelle catégorie de revenu' : 'Nouvelle catégorie de dépense'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_isEditing)
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 20),
              ColorIconPicker(
                colors: AppColors.palette,
                icons: CategoryIcons.all,
                selectedColor: _color,
                selectedIcon: _icon,
                onColorChanged: (c) => setState(() => _color = c),
                onIconChanged: (i) => setState(() => _icon = i),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Enregistrer' : 'Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
