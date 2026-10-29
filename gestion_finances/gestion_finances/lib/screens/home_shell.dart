import 'package:flutter/material.dart';

import 'accounts/account_form_sheet.dart';
import 'accounts/accounts_screen.dart';
import 'budgets/budgets_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'settings/settings_screen.dart';
import 'transactions/transaction_form_screen.dart';
import 'transactions/transactions_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    AccountsScreen(),
    SettingsScreen(),
  ];

  void _openTransactionForm() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
    );
  }

  void _openAccountForm() {
    showAccountFormSheet(context);
  }

  /// Le bouton "+" change de comportement selon l'onglet actif :
  /// - Dashboard / Mouvements / Budgets -> ajouter une transaction
  /// - Comptes -> ajouter un compte
  /// - Réglages -> pas de bouton
  Widget? _buildFab() {
    switch (_index) {
      case 0:
      case 1:
      case 2:
        return FloatingActionButton(
          key: const ValueKey('fab_transaction'),
          onPressed: _openTransactionForm,
          tooltip: 'Ajouter une transaction',
          child: const Icon(Icons.add),
        );
      case 3:
        return FloatingActionButton(
          key: const ValueKey('fab_account'),
          onPressed: _openAccountForm,
          tooltip: 'Ajouter un compte',
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Mouvements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Comptes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Réglages',
          ),
        ],
      ),
    );
  }
}
