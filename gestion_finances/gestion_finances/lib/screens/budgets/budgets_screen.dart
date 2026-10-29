import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../core/icons_map.dart';
import '../../core/utils.dart';
import '../../providers/budget_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/savings_goal_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/icon_avatar.dart';
import '../recurring/recurring_form_sheet.dart';
import '../savings/savings_deposit_sheet.dart';
import '../savings/savings_goal_form_sheet.dart';
import '../transactions/transaction_form_screen.dart';
import 'budget_form_sheet.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Épargne'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart_outline), text: 'Enveloppes'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Charges fixes'),
            Tab(icon: Icon(Icons.savings_outlined), text: 'Cagnottes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _EnvelopesTab(),
          _RecurringTab(),
          _SavingsGoalsTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// ONGLET 1 : ENVELOPPES & PLAFONDS PAR CATÉGORIE
// =============================================================================
class _EnvelopesTab extends ConsumerWidget {
  const _EnvelopesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryBudgets = ref.watch(monthlyCategoryBudgetsProvider);
    final health = ref.watch(financialHealthProvider);

    final budgetedCount = categoryBudgets.where((b) => b.hasBudget).length;
    final totalLimit = health.totalAllocatedBudget;
    final totalSpent = health.totalBudgetSpent;
    final overallProgress =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;

    if (categoryBudgets.isEmpty) {
      return const EmptyState(
        icon: Icons.pie_chart_outline,
        title: 'Aucune catégorie de dépense',
        subtitle:
            'Crée d\'abord des catégories dans Réglages > Gérer les catégories pour leur fixer un budget.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Synthèse globale
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget mensuel alloué',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$budgetedCount ${budgetedCount > 1 ? 'enveloppes actives' : 'enveloppe active'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatAmount(totalLimit),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: overallProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    totalSpent > totalLimit && totalLimit > 0
                        ? AppTheme.expense
                        : (overallProgress > 0.8 ? Colors.amber : Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dépensé : ${formatAmount(totalSpent)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    totalLimit > totalSpent
                        ? 'Reste : ${formatAmount(totalLimit - totalSpent)}'
                        : (totalLimit > 0
                            ? 'Dépassé de ${formatAmount(totalSpent - totalLimit)}'
                            : 'Aucun plafond fixé'),
                    style: TextStyle(
                      color: totalSpent > totalLimit && totalLimit > 0
                          ? const Color(0xFFFFB4AB)
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Plafonds par catégorie',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        ...categoryBudgets.map((status) {
          return _CategoryBudgetCard(status: status);
        }),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({required this.status});
  final CategoryBudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final cat = status.category;

    Color progressColor;
    String badgeText;
    Color badgeBg;
    Color badgeTextCol;

    switch (status.level) {
      case BudgetLevel.safe:
        progressColor = AppTheme.income;
        badgeText = 'Reste ${formatAmount(status.remaining)}';
        badgeBg = AppTheme.income.withValues(alpha: 0.12);
        badgeTextCol = AppTheme.income;
        break;
      case BudgetLevel.warning:
        progressColor = Colors.orange;
        badgeText = 'Attention : reste ${formatAmount(status.remaining)}';
        badgeBg = Colors.orange.withValues(alpha: 0.12);
        badgeTextCol = Colors.orange.shade800;
        break;
      case BudgetLevel.danger:
        progressColor = AppTheme.expense;
        badgeText = 'Dépassé de ${formatAmount(status.spent - status.limit)}';
        badgeBg = AppTheme.expense.withValues(alpha: 0.12);
        badgeTextCol = AppTheme.expense;
        break;
      case BudgetLevel.none:
        progressColor = Colors.grey;
        badgeText = 'Pas de budget';
        badgeBg = Colors.grey.withValues(alpha: 0.12);
        badgeTextCol = Colors.grey.shade700;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: status.level == BudgetLevel.danger
              ? AppTheme.expense.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showBudgetFormSheet(
            context,
            category: cat,
            currentBudget: status.budget,
            currentSpent: status.spent,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconAvatar(
                    iconKey: cat.icon,
                    colorHex: cat.color,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          status.hasBudget
                              ? '${formatAmount(status.spent)} / ${formatAmount(status.limit)}'
                              : 'Dépensé ce mois : ${formatAmount(status.spent)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextCol,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (status.hasBudget) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: status.progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ONGLET 2 : CHARGES FIXES & REVENUS RÉCURRENTS (ÉCHÉANCIER)
// =============================================================================
class _RecurringTab extends ConsumerWidget {
  const _RecurringTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(monthlyRecurringAnalysisProvider);
    final items = analysis.items;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Carte de synthèse des charges fixes
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Charges fixes du mois',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${items.where((i) => i.recurring.type == TxType.expense).length} charges',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatAmount(analysis.totalFixedExpenses),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Déjà payé',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatAmount(analysis.paidFixedExpenses),
                            style: const TextStyle(
                              color: AppTheme.income,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'En attente (réservé)',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatAmount(analysis.pendingFixedExpenses),
                            style: const TextStyle(
                              color: Color(0xFFFFB4AB),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Échéancier mensuel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter'),
                onPressed: () => showRecurringFormSheet(context),
              ),
            ],
          ),
        ),

        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Aucune charge fixe enregistrée',
              subtitle:
                  'Ajoutez votre loyer, abonnement internet ou facture JIRAMA pour qu\'ils soient pré-bloqués sur votre reste à vivre chaque mois.',
            ),
          )
        else
          ...items.map((item) {
            final r = item.recurring;
            final isExpense = r.type == TxType.expense;

            String statusLabel;
            Color statusBg;
            Color statusCol;

            if (item.isPaidThisMonth) {
              statusLabel = 'Payé ce mois ✅';
              statusBg = AppTheme.income.withValues(alpha: 0.12);
              statusCol = AppTheme.income;
            } else if (item.isDueToday) {
              statusLabel = 'Échéance aujourd\'hui !';
              statusBg = Colors.orange.withValues(alpha: 0.15);
              statusCol = Colors.orange.shade800;
            } else if (item.isPastDue) {
              statusLabel = 'En retard (${-item.daysUntilDue} j)';
              statusBg = AppTheme.expense.withValues(alpha: 0.12);
              statusCol = AppTheme.expense;
            } else {
              statusLabel = 'Dans ${item.daysUntilDue} j';
              statusBg = Colors.grey.withValues(alpha: 0.12);
              statusCol = Colors.grey.shade700;
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: isExpense
                      ? AppTheme.expense.withValues(alpha: 0.15)
                      : AppTheme.income.withValues(alpha: 0.15),
                  child: Icon(
                    isExpense ? Icons.receipt_outlined : Icons.work_outline,
                    color: isExpense ? AppTheme.expense : AppTheme.income,
                  ),
                ),
                title: Text(
                  r.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  'Le ${r.dayOfMonth} du mois • ${formatAmount(r.amount)}',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusCol,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!item.isPaidThisMonth && isExpense) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline,
                            color: AppTheme.primary),
                        tooltip: 'Enregistrer le paiement',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TransactionFormScreen(
                                initialType: TxType.expense,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                onTap: () =>
                    showRecurringFormSheet(context, editingItem: r),
              ),
            );
          }),

        const SizedBox(height: 24),
      ],
    );
  }
}

// =============================================================================
// ONGLET 3 : CAGNOTTES & OBJECTIFS D'ÉPARGNE (FONDS D'URGENCE)
// =============================================================================
class _SavingsGoalsTab extends ConsumerWidget {
  const _SavingsGoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(savingsGoalsSummaryProvider);
    final goals = summary.goals;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Synthèse globale de l'épargne
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E5F74), Color(0xFF133B5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total épargné sur objectifs',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(summary.progress * 100).toStringAsFixed(0)}% atteint',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatAmount(summary.totalSaved),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: summary.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4ECCA3),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cible globale : ${formatAmount(summary.totalTarget)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Reste : ${formatAmount(summary.totalTarget - summary.totalSaved)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mes Cagnottes & Fonds d\'urgence',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Créer'),
                onPressed: () => showSavingsGoalFormSheet(context),
              ),
            ],
          ),
        ),

        if (goals.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: EmptyState(
              icon: Icons.savings_outlined,
              title: 'Aucun objectif d\'épargne créé',
              subtitle:
                  'Créez votre première cagnotte (ex: "Fonds d\'urgence 3 mois", "Projet ordinateur") pour sanctuariser vos économies et résister aux imprévus !',
            ),
          )
        else
          ...goals.map((goal) {
            final progress = goal.targetAmount > 0
                ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                : 0.0;
            final isCompleted = goal.currentAmount >= goal.targetAmount;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isCompleted
                      ? AppTheme.income.withValues(alpha: 0.6)
                      : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconAvatar(
                          iconKey: goal.icon,
                          colorHex: goal.color,
                          size: 42,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${formatAmount(goal.currentAmount)} / ${formatAmount(goal.targetAmount)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.income.withValues(alpha: 0.12)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCompleted
                                ? 'Atteint ! 🎉'
                                : '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isCompleted
                                  ? AppTheme.income
                                  : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? AppTheme.income
                              : colorFromHex(goal.color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          goal.targetDate != null
                              ? 'Cible : ${formatDate(goal.targetDate!)}'
                              : 'Sans date limite',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Modifier',
                              onPressed: () => showSavingsGoalFormSheet(
                                context,
                                editingGoal: goal,
                              ),
                            ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Gérer les fonds'),
                              onPressed: () => showSavingsDepositSheet(
                                context,
                                goal: goal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 24),
      ],
    );
  }
}
