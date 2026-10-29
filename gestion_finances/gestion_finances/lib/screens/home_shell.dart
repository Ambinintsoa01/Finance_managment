import 'dart:ui';
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
        onNavigateToTransactions: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransactionsScreen()),
          );
        },
      ),
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
    // Le FAB ne s'affiche QUE dans l'onglet Comptes (_index == 3) pour créer des comptes
    if (_index == 3) {
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
    }
    return null;
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _index == index;
    // Seul le bouton central "+" est coloré. Les autres onglets restent sobres et élégants (style Apple)
    final color = isSelected ? AppTheme.emeraldDarkest : const Color(0xFF8E8E93);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _index = index),
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return Expanded(
      child: Center(
        child: Tooltip(
          message: 'Ajouter un mouvement',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openTransactionForm,
              customBorder: const CircleBorder(),
              splashColor: AppTheme.emeraldMint.withValues(alpha: 0.3),
              highlightColor: Colors.transparent,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.emeraldDarkest, AppTheme.emeraldPine],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emeraldPine.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppTheme.emeraldMint,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 66,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF051F20).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.6),
                      blurRadius: 1,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.space_dashboard_outlined,
                      activeIcon: Icons.space_dashboard_rounded,
                      label: 'Synthèse',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.pie_chart_outline_rounded,
                      activeIcon: Icons.pie_chart_rounded,
                      label: 'Budgets',
                    ),
                    _buildCenterAddButton(),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.insights_outlined,
                      activeIcon: Icons.insights_rounded,
                      label: 'Analyses',
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.account_balance_wallet_outlined,
                      activeIcon: Icons.account_balance_wallet_rounded,
                      label: 'Comptes',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
