import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../providers/account_provider.dart';
import '../../accounts/accounts_screen.dart';
import '../../audit/financial_audit_screen.dart';
import '../../transactions/transaction_form_screen.dart';
import '../../transactions/transfer_form_screen.dart';

class HeroBalanceCard extends ConsumerWidget {
  const HeroBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAccountId = ref.watch(selectedAccountIdProvider);
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];

    final balanceAsync = selectedAccountId == null
        ? ref.watch(totalBalanceProvider)
        : ref.watch(accountBalanceProvider(selectedAccountId));

    final selectedAccount = selectedAccountId == null
        ? null
        : accounts.where((a) => a.id == selectedAccountId).firstOrNull;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33051F20),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cercles décoratifs d'arrière-plan (effet onde de la maquette)
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 20,
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04),
                  width: 12,
                ),
              ),
            ),
          ),

          // Contenu principal
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne supérieure : Label & Sélecteur / Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selectedAccount != null
                                  ? Icons.account_balance_wallet_rounded
                                  : Icons.wallet_rounded,
                              size: 14,
                              color: AppTheme.emeraldMint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              selectedAccount?.name ?? 'Tous les comptes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AccountsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${accounts.length} cpt${accounts.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: AppTheme.emeraldSage,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, size: 14, color: AppTheme.emeraldSage),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Titre Solde
              const Text(
                'Solde disponible',
                style: TextStyle(
                  color: AppTheme.emeraldSage,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),

              // Montant principal en gros
              balanceAsync.when(
                data: (v) => Text(
                  formatAmount(v, currency: selectedAccount?.currency ?? 'MGA'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                loading: () => const SizedBox(
                  height: 38,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const Text('—', style: TextStyle(color: Colors.white, fontSize: 28)),
              ),
              const SizedBox(height: 22),

              // Dock d'actions rapides (comme la maquette : Entrée, Sortie, Virement, Stratégie)
              // Row(
              //   children: [
              //     Expanded(
              //       child: _QuickActionButton(
              //         icon: Icons.arrow_downward_rounded,
              //         label: 'Revenu',
              //         isHighlight: false,
              //         onTap: () {
              //           Navigator.of(context).push(
              //             MaterialPageRoute(
              //               builder: (_) => const TransactionFormScreen(initialType: TxType.income),
              //             ),
              //           );
              //         },
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     Expanded(
              //       child: _QuickActionButton(
              //         icon: Icons.arrow_upward_rounded,
              //         label: 'Dépense',
              //         isHighlight: false,
              //         onTap: () {
              //           Navigator.of(context).push(
              //             MaterialPageRoute(
              //               builder: (_) => const TransactionFormScreen(initialType: TxType.expense),
              //             ),
              //           );
              //         },
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     Expanded(
              //       child: _QuickActionButton(
              //         icon: Icons.swap_horiz_rounded,
              //         label: 'Virement',
              //         isHighlight: false,
              //         onTap: () {
              //           Navigator.of(context).push(
              //             MaterialPageRoute(
              //               builder: (_) => const TransferFormScreen(),
              //             ),
              //           );
              //         },
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     Expanded(
              //       child: _QuickActionButton(
              //         icon: Icons.auto_graph_rounded,
              //         label: 'Audit',
              //         isHighlight: true, // bouton contrasté vert menthe comme sur la maquette
              //         onTap: () {
              //           Navigator.of(context).push(
              //             MaterialPageRoute(
              //               builder: (_) => const FinancialAuditScreen(),
              //             ),
              //           );
              //         },
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isHighlight
              ? AppTheme.emeraldMint
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: isHighlight
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isHighlight ? AppTheme.emeraldDarkest : Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isHighlight ? AppTheme.emeraldDarkest : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
