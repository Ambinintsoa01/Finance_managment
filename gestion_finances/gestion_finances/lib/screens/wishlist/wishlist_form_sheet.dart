import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/icons_map.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/database_provider.dart';

Future<void> showWishlistFormSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _WishlistFormSheet(),
  );
}

class _WishlistFormSheet extends ConsumerStatefulWidget {
  const _WishlistFormSheet();

  @override
  ConsumerState<_WishlistFormSheet> createState() => _WishlistFormSheetState();
}

class _WishlistFormSheetState extends ConsumerState<_WishlistFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  Duration _selectedDelay = const Duration(hours: 48); // 48h par défaut
  String? _categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final userId = ref.read(currentUserProvider)?.id;
    final repo = ref.read(wishlistRepositoryProvider);

    await repo.createWishlistItem(
      name: _nameCtrl.text.trim(),
      amount: amount,
      categoryId: _categoryId,
      delay: _selectedDelay,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      userId: userId,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Achat placé en réflexion pendant ${_selectedDelay.inHours}h. Bravo pour la retenue ! ⏳',
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final expenseCategories = ref.watch(expenseCategoriesProvider);

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
                  const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: Colors.purple, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Sas anti-achat impulsif',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Envie subite d\'acheter un article non vital ? Mettez-le en pause ici. Si l\'envie a disparu après le délai, vous aurez économisé cette somme !',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Qu\'avez-vous envie d\'acheter ?',
                  hintText: 'Ex: Paire de baskets, Nouveau casque, Montre',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Saisis le nom de l\'article' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Prix de l\'article (Ar)',
                  hintText: 'Ex: 120000',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
                validator: (v) {
                  final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (val == null || val <= 0) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Délai de réflexion (Cooling-off) :',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),

              SegmentedButton<Duration>(
                segments: const [
                  ButtonSegment(
                    value: Duration(hours: 24),
                    label: Text('24h'),
                  ),
                  ButtonSegment(
                    value: Duration(hours: 48),
                    label: Text('48h (Idéal)'),
                  ),
                  ButtonSegment(
                    value: Duration(days: 7),
                    label: Text('7 jours'),
                  ),
                ],
                selected: {_selectedDelay},
                onSelectionChanged: (s) => setState(() => _selectedDelay = s.first),
              ),
              const SizedBox(height: 16),

              if (expenseCategories.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie associée',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Autre / Shopping')),
                    ...expenseCategories.map((c) {
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

              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pourquoi cette envie ? (Optionnel)',
                  hintText: 'Ex: Vu sur les réseaux, promo limitée...',
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.timer_outlined),
                label: const Text('Mettre en pause pour réfléchir'),
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
