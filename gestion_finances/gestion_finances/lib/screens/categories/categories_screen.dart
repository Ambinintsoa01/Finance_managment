import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/local/database.dart';
import '../../providers/category_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/icon_avatar.dart';
import 'category_form_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catégories'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Dépenses'), Tab(text: 'Revenus')],
          ),
        ),
        body: TabBarView(
          children: [
            _CategoryList(type: TxType.expense),
            _CategoryList(type: TxType.income),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.type});
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = type == TxType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    return Scaffold(
      body: categories.isEmpty
          ? EmptyState(
              icon: Icons.category_outlined,
              title: 'Aucune catégorie',
              action: ElevatedButton.icon(
                onPressed: () => showCategoryFormSheet(context, type: type),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une catégorie'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final Category c = categories[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: IconAvatar(iconKey: c.icon, colorHex: c.color),
                    title: Text(c.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showCategoryFormSheet(context, type: type, category: c),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_category_$type',
        onPressed: () => showCategoryFormSheet(context, type: type),
        child: const Icon(Icons.add),
      ),
    );
  }
}
