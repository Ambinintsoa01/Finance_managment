import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_finances/core/constants.dart';
import 'package:gestion_finances/data/local/database.dart';
import 'package:gestion_finances/providers/account_provider.dart';
import 'package:gestion_finances/providers/dashboard_provider.dart';
import 'package:gestion_finances/providers/transaction_provider.dart';

void main() {
  test('capitalEvolutionProvider computes weekly capital points and variation correctly', () async {
    final testDate = DateTime(2026, 10, 7); // Wednesday
    final now = DateTime.now();

    final account = Account(
      id: 'acc-1',
      name: 'Courant',
      type: 'bank',
      initialBalance: 100000,
      currency: 'MGA',
      icon: 'bank',
      color: '#2E7D5B',
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    // Monday 2026-10-05: Income +50 000
    final tx1 = Transaction(
      id: 'tx-1',
      accountId: 'acc-1',
      amount: 50000,
      type: TxType.income,
      date: DateTime(2026, 10, 5, 10, 0),
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    // Tuesday 2026-10-06: Expense -20 000
    final tx2 = Transaction(
      id: 'tx-2',
      accountId: 'acc-1',
      amount: 20000,
      type: TxType.expense,
      date: DateTime(2026, 10, 6, 14, 0),
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    final container = ProviderContainer(
      overrides: [
        dashboardPeriodProvider.overrideWith((ref) => DashboardPeriod.week),
        dashboardReferenceDateProvider.overrideWith((ref) => testDate),
        accountsStreamProvider.overrideWith((ref) => Stream.value([account])),
        allTransactionsProvider.overrideWith((ref) => Stream.value([tx1, tx2])),
      ],
    );

    await container.read(accountsStreamProvider.future);
    await container.read(allTransactionsProvider.future);

    final data = container.read(capitalEvolutionProvider);

    expect(data, isNotNull);
    expect(data!.points.length, 7);
    expect(data.startCapital, 100000); // Base before week
    expect(data.points[0].capital, 150000); // Lun end
    expect(data.points[1].capital, 130000); // Mar end
    expect(data.points[2].capital, 130000); // Mer end
    expect(data.endCapital, 130000);
    expect(data.netVariation, 30000); // +30 000 MGA
    expect(data.percentageVariation, 30.0); // +30%
  });

  test('capitalEvolutionProvider handles internal transfers between accounts and negative variation', () async {
    final testDate = DateTime(2026, 10, 15);
    final now = DateTime.now();

    final acc1 = Account(
      id: 'acc-1',
      name: 'Banque',
      type: 'bank',
      initialBalance: 200000,
      currency: 'MGA',
      icon: 'bank',
      color: '#2E7D5B',
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    final acc2 = Account(
      id: 'acc-2',
      name: 'Mobile Money',
      type: 'mobile_money',
      initialBalance: 50000,
      currency: 'MGA',
      icon: 'mobile',
      color: '#3E7CB1',
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    // Transfer 30 000 from acc-1 to acc-2 on Oct 2
    final transferTx = Transaction(
      id: 'tx-t1',
      accountId: 'acc-1',
      destinationAccountId: 'acc-2',
      amount: 30000,
      type: TxType.transfer,
      date: DateTime(2026, 10, 2, 10, 0),
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    // Expense 80 000 on acc-2 on Oct 10
    final expenseTx = Transaction(
      id: 'tx-e1',
      accountId: 'acc-2',
      amount: 80000,
      type: TxType.expense,
      date: DateTime(2026, 10, 10, 11, 0),
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      dirty: false,
    );

    // Case 1: Global view (all accounts)
    final containerGlobal = ProviderContainer(
      overrides: [
        dashboardPeriodProvider.overrideWith((ref) => DashboardPeriod.month),
        dashboardReferenceDateProvider.overrideWith((ref) => testDate),
        accountsStreamProvider.overrideWith((ref) => Stream.value([acc1, acc2])),
        allTransactionsProvider.overrideWith((ref) => Stream.value([transferTx, expenseTx])),
      ],
    );

    await containerGlobal.read(accountsStreamProvider.future);
    await containerGlobal.read(allTransactionsProvider.future);

    final globalData = containerGlobal.read(capitalEvolutionProvider);
    expect(globalData, isNotNull);
    expect(globalData!.startCapital, 250000); // 200k + 50k
    // Transfer does not change global capital on Oct 2: 250k
    expect(globalData.points[1].capital, 250000);
    // Expense changes global capital on Oct 10: 250k - 80k = 170k
    expect(globalData.points[9].capital, 170000);
    expect(globalData.endCapital, 170000);
    expect(globalData.netVariation, -80000);
    expect(globalData.percentageVariation, -32.0);

    // Case 2: Specific account view (acc-1 selected)
    final containerAcc1 = ProviderContainer(
      overrides: [
        dashboardPeriodProvider.overrideWith((ref) => DashboardPeriod.month),
        dashboardReferenceDateProvider.overrideWith((ref) => testDate),
        selectedAccountIdProvider.overrideWith((ref) => 'acc-1'),
        accountsStreamProvider.overrideWith((ref) => Stream.value([acc1, acc2])),
        allTransactionsProvider.overrideWith((ref) => Stream.value([transferTx, expenseTx])),
      ],
    );

    await containerAcc1.read(accountsStreamProvider.future);
    await containerAcc1.read(allTransactionsProvider.future);

    final acc1Data = containerAcc1.read(capitalEvolutionProvider);
    expect(acc1Data, isNotNull);
    expect(acc1Data!.startCapital, 200000);
    // acc-1 sent transfer 30k on Oct 2 -> 170k
    expect(acc1Data.points[1].capital, 170000);
    expect(acc1Data.endCapital, 170000);
    expect(acc1Data.netVariation, -30000);
    expect(acc1Data.percentageVariation, -15.0);
  });
}
