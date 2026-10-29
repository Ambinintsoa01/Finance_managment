import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'accounts/account_form_sheet.dart';
import 'accounts/accounts_screen.dart';
import 'audit/financial_audit_screen.dart';
import 'budgets/budgets_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transaction_form_screen.dart';
import 'transactions/transactions_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        onNavigateToTransactions: () => setState(() => _index = 1),
      ),
      const TransactionsScreen(),
      const BudgetsScreen(),
      const FinancialAuditScreen(),
      const AccountsScreen(),
    ];
  }

  void _openTransactionForm() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
    );
  }

  void _openAccountForm() {
    showAccountFormSheet(context);
  }

  Widget? _buildFab() {
    switch (_index) {
      case 0:
      case 1:
      case 2:
      case 3:
        return FloatingActionButton(
          key: const ValueKey('fab_transaction'),
          backgroundColor: AppTheme.emeraldDarkest,
          foregroundColor: AppTheme.emeraldMint,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onPressed: _openTransactionForm,
          tooltip: 'Ajouter une transaction',
          child: const Icon(Icons.add_rounded, size: 28),
        );
      case 4:
        return FloatingActionButton(
          key: const ValueKey('fab_account'),
          backgroundColor: AppTheme.emeraldDarkest,
          foregroundColor: AppTheme.emeraldMint,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onPressed: _openAccountForm,
          tooltip: 'Ajouter un compte',
          child: const Icon(Icons.add_rounded, size: 28),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppTheme.cardBorder.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A051F20),
              blurRadius: 16,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.emeraldDarkest,
          unselectedItemColor: const Color(0xFF8FA197),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.space_dashboard_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.space_dashboard_rounded, size: 22),
              ),
              label: 'Synthèse',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.receipt_long_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.receipt_long_rounded, size: 22),
              ),
              label: 'Mouvements',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.pie_chart_outline_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.pie_chart_rounded, size: 22),
              ),
              label: 'Budgets',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.insights_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.insights_rounded, size: 22),
              ),
              label: 'Analyses',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.account_balance_wallet_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.account_balance_wallet_rounded, size: 22),
              ),
              label: 'Comptes',
            ),
          ],
        ),
      ),
    );
  }
}
