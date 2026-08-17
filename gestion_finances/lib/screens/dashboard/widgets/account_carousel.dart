import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/utils.dart';
import '../../../providers/account_provider.dart';
import '../../../widgets/icon_avatar.dart';

class AccountCarousel extends ConsumerWidget {
  const AccountCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final selectedId = ref.watch(selectedAccountIdProvider);

    if (accounts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: accounts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            // Carte "Tous les comptes"
            final isSelected = selectedId == null;
            return _AccountCard(
              isSelected: isSelected,
              onTap: () => ref.read(selectedAccountIdProvider.notifier).state = null,
              icon: Icons.apps_rounded,
              iconColor: AppTheme.primary,
              label: 'Tous',
              amountWidget: Consumer(
                builder: (context, ref, _) {
                  final total = ref.watch(totalBalanceProvider);
                  return total.when(
                    data: (v) => Text(formatAmount(v), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const Text('—'),
                  );
                },
              ),
            );
          }
          final account = accounts[i - 1];
          final isSelected = selectedId == account.id;
          return _AccountCard(
            isSelected: isSelected,
            onTap: () => ref.read(selectedAccountIdProvider.notifier).state = account.id,
            iconKey: account.icon,
            iconColorHex: account.color,
            label: account.name,
            amountWidget: Consumer(
              builder: (context, ref, _) {
                final balance = ref.watch(accountBalanceProvider(account.id));
                return balance.when(
                  data: (v) => Text(formatAmount(v, currency: account.currency), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const Text('—'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.amountWidget,
    this.icon,
    this.iconColor,
    this.iconKey,
    this.iconColorHex,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final String label;
  final Widget amountWidget;
  final IconData? icon;
  final Color? iconColor;
  final String? iconKey;
  final String? iconColorHex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (icon != null)
              Icon(icon, color: iconColor, size: 28)
            else
              IconAvatar(iconKey: iconKey!, colorHex: iconColorHex!, size: 30),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            amountWidget,
          ],
        ),
      ),
    );
  }
}
