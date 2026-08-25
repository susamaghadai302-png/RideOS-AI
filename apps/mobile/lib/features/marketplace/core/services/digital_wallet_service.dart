import 'package:flutter/foundation.dart';

enum ExpenseCategory {
  fuel,
  toll,
  serviceMaintenance,
  riderGear,
  insurance,
}

@immutable
class WalletTransaction {
  final String id;
  final String title;
  final double amountUsd;
  final ExpenseCategory category;
  final DateTime timestamp;
  final String receiptRef;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amountUsd,
    required this.category,
    required this.timestamp,
    required this.receiptRef,
  });
}

class DigitalWalletService {
  static final DigitalWalletService _instance = DigitalWalletService._internal();
  factory DigitalWalletService() => _instance;
  DigitalWalletService._internal();

  double _currentBalanceUsd = 480.50;
  double _monthlyBudgetUsd = 600.00;

  final List<WalletTransaction> _transactions = [
    WalletTransaction(
      id: 'tx_01',
      title: 'Chevron 93 Octane Premium',
      amountUsd: 22.40,
      category: ExpenseCategory.fuel,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      receiptRef: 'RCP-CHV-9812',
    ),
    WalletTransaction(
      id: 'tx_02',
      title: 'Golden Gate Express FASTag Toll',
      amountUsd: 7.50,
      category: ExpenseCategory.toll,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      receiptRef: 'RCP-TLL-4421',
    ),
    WalletTransaction(
      id: 'tx_03',
      title: 'Motul 300V Synthetic Oil Pack',
      amountUsd: 65.00,
      category: ExpenseCategory.serviceMaintenance,
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      receiptRef: 'RCP-SRV-1102',
    ),
  ];

  double get currentBalance => _currentBalanceUsd;
  double get monthlyBudget => _monthlyBudgetUsd;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  double get totalSpentThisMonth =>
      _transactions.fold(0.0, (acc, tx) => acc + tx.amountUsd);

  double get budgetUtilizationPct =>
      ((totalSpentThisMonth / _monthlyBudgetUsd) * 100.0).clamp(0.0, 100.0);

  void recordExpense({
    required String title,
    required double amount,
    required ExpenseCategory category,
  }) {
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amountUsd: amount,
      category: category,
      timestamp: DateTime.now(),
      receiptRef: 'RCP-AUT-${DateTime.now().millisecondsSinceEpoch}',
    );
    _transactions.insert(0, tx);
    _currentBalanceUsd -= amount;
  }
}
