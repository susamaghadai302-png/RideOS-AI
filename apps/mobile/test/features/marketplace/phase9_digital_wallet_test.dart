import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/marketplace/core/services/digital_wallet_service.dart';

void main() {
  group('Phase 9 - Rider Digital Wallet & Expenses Tests', () {
    late DigitalWalletService walletService;

    setUp(() {
      walletService = DigitalWalletService();
    });

    test('Computes total spent and budget utilization accurately', () {
      expect(walletService.currentBalance, greaterThan(0));
      expect(walletService.transactions.isNotEmpty, isTrue);

      final spent = walletService.totalSpentThisMonth;
      expect(spent, greaterThan(0));

      final util = walletService.budgetUtilizationPct;
      expect(util, greaterThanOrEqualTo(0.0));
      expect(util, lessThanOrEqualTo(100.0));
    });

    test('Records new ride expense and updates balance and ledger', () {
      final initialBalance = walletService.currentBalance;
      final initialTxCount = walletService.transactions.length;

      walletService.recordExpense(
        title: 'Track Day Entrance Pass',
        amount: 80.0,
        category: ExpenseCategory.serviceMaintenance,
      );

      expect(walletService.transactions.length, equals(initialTxCount + 1));
      expect(walletService.currentBalance, equals(initialBalance - 80.0));
      expect(walletService.transactions.first.title, equals('Track Day Entrance Pass'));
    });
  });
}
