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
  String? _errorMessage;

  WalletProvider();

  WalletSummary? get walletSummary => _walletSummary;
  double get balance => _walletSummary?.balance ?? 0.0;
  String get currency => _walletSummary?.currency ?? 'NGN';
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isBalanceVisible => _isBalanceVisible;
  String get selectedFilter => _selectedFilter;
  String? get errorMessage => _errorMessage;

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
      _errorMessage = null;
    } catch (_) {
      _walletSummary = null;
      _transactions = [];
      _errorMessage = 'Your wallet is temporarily unavailable. Please try again.';
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
    } catch (error) {
      _transactions = [];
      _errorMessage = 'Your transaction history is temporarily unavailable. Please try again.';
      debugPrint('Wallet transaction history fetch failed: $error');
      rethrow;
    }
  }

}
