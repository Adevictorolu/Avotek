import 'package:flutter/material.dart';
import '../core/supabase/supabase_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

class WalletProvider extends ChangeNotifier {
  WalletSummary? _walletSummary;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isBalanceVisible = true;
  String _selectedFilter = 'all';

  WalletProvider();

  WalletSummary? get walletSummary => _walletSummary;
  double get balance => _walletSummary?.balance ?? 0.0;
  String get currency => _walletSummary?.currency ?? 'NGN';
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isBalanceVisible => _isBalanceVisible;
  String get selectedFilter => _selectedFilter;

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> fetchWallet(dynamic userId) async {
    final uid = userId?.toString() ?? '';
    if (uid.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final wallet = await SupabaseService.instance.getWallet(uid);
      _walletSummary = WalletSummary.fromWallet(wallet);
      await fetchTransactions(uid);
    } catch (_) {
      _walletSummary ??= const WalletSummary(
        balance: 0.0,
        currency: 'NGN',
        virtualAccountNumber: '8167002789',
        virtualAccountBank: 'Wema Bank / PalmPay',
        virtualAccountName: 'AVOTEK Customer',
        totalFunded: 0.0,
        totalSpent: 0.0,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransactions(dynamic userId) async {
    final uid = userId?.toString() ?? '';
    if (uid.isEmpty) return;

    try {
      _transactions = await SupabaseService.instance.getTransactions(
        uid,
        limit: 50,
        filterType: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      notifyListeners();
    } catch (_) {}
  }

  /// Deduct balance locally and record in immutable ledger
  void recordDebit({
    required dynamic userId,
    required double amount,
    required String serviceName,
    required String reference,
  }) {
    final currentBal = balance;
    final newBal = (currentBal - amount) > 0 ? (currentBal - amount) : 0.0;

    _walletSummary = WalletSummary(
      balance: newBal,
      currency: currency,
      virtualAccountNumber: _walletSummary?.virtualAccountNumber,
      virtualAccountBank: _walletSummary?.virtualAccountBank,
      virtualAccountName: _walletSummary?.virtualAccountName,
      totalFunded: _walletSummary?.totalFunded ?? 0.0,
      totalSpent: (_walletSummary?.totalSpent ?? 0.0) + amount,
    );

    final tx = TransactionModel(
      id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId.toString(),
      type: 'debit',
      amount: amount,
      balanceBefore: currentBal,
      balanceAfter: newBal,
      reference: reference,
      narration: '$serviceName Top-up',
      status: 'completed',
      idempotencyKey: 'IDEM-$reference',
      createdAt: DateTime.now(),
    );

    _transactions.insert(0, tx);
    notifyListeners();
  }

  /// Credit balance locally and record in immutable ledger
  void recordCredit({
    required dynamic userId,
    required double amount,
    required String reference,
    String? narration,
  }) {
    final currentBal = balance;
    final newBal = currentBal + amount;

    _walletSummary = WalletSummary(
      balance: newBal,
      currency: currency,
      virtualAccountNumber: _walletSummary?.virtualAccountNumber,
      virtualAccountBank: _walletSummary?.virtualAccountBank,
      virtualAccountName: _walletSummary?.virtualAccountName,
      totalFunded: (_walletSummary?.totalFunded ?? 0.0) + amount,
      totalSpent: _walletSummary?.totalSpent ?? 0.0,
    );

    final tx = TransactionModel(
      id: 'CR-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId.toString(),
      type: 'credit',
      amount: amount,
      balanceBefore: currentBal,
      balanceAfter: newBal,
      reference: reference,
      narration: narration ?? 'Automated Bank Transfer Deposit',
      status: 'completed',
      idempotencyKey: 'IDEM-$reference',
      createdAt: DateTime.now(),
    );

    _transactions.insert(0, tx);
    notifyListeners();
  }

  /// Convenience method for crediting funds (e.g. from coupons or funding)
  void depositFunds(double amount, {String? reference, String? narration}) {
    recordCredit(
      userId: 'user_1',
      amount: amount,
      reference: reference ?? 'DEP-${DateTime.now().millisecondsSinceEpoch}',
      narration: narration ?? 'Wallet Deposit',
    );
  }

  /// Convenience method for debiting funds (e.g. from gifts or service purchases)
  void debit(double amount, String narration, {String? reference}) {
    recordDebit(
      userId: 'user_1',
      amount: amount,
      serviceName: narration,
      reference: reference ?? 'DEB-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
