import 'package:flutter/material.dart';
import '../core/services/paystack_payment_service.dart';
import '../core/supabase/supabase_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

class WalletProvider extends ChangeNotifier {
  WalletSummary? _walletSummary;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isProvisioningDedicatedAccount = false;
  bool _dedicatedAccountNeedsProfile = false;
  String? _dedicatedAccountMessage;
  double? _activeTransferAmountNaira;
  String? _activeTransferReference;
  bool _isBalanceVisible = true;
  String _selectedFilter = 'all';
  String? _errorMessage;

  WalletProvider();

  WalletSummary? get walletSummary => _walletSummary;
  double get balance => _walletSummary?.balance ?? 0.0;
  String get currency => _walletSummary?.currency ?? 'NGN';
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isProvisioningDedicatedAccount => _isProvisioningDedicatedAccount;
  bool get dedicatedAccountNeedsProfile => _dedicatedAccountNeedsProfile;
  String? get dedicatedAccountMessage => _dedicatedAccountMessage;
  double? get activeTransferAmountNaira => _activeTransferAmountNaira;
  String? get activeTransferReference => _activeTransferReference;
  bool get hasDedicatedAccount => _walletSummary?.hasDedicatedAccount ?? false;
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
      if (_walletSummary?.hasDedicatedAccount == true) {
        _dedicatedAccountNeedsProfile = false;
        _dedicatedAccountMessage = null;
      }
      await fetchTransactions(uid);
      _errorMessage = null;
    } catch (_) {
      _walletSummary = null;
      _transactions = [];
      _errorMessage =
          'Your wallet is temporarily unavailable. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PaystackDedicatedAccountResult?> ensureDedicatedAccount(
    dynamic userId, {
    String? fullName,
    String? phone,
    int? amountNaira,
    bool force = false,
  }) async {
    final uid = userId?.toString() ?? '';
    if (uid.isEmpty) return null;

    if (!force &&
        amountNaira == null &&
        _walletSummary?.hasDedicatedAccount == true) {
      return PaystackDedicatedAccountResult(
        status: 'assigned',
        accountNumber: _walletSummary!.virtualAccountNumber,
        bankName: _walletSummary!.virtualAccountBank,
        accountName: _walletSummary!.virtualAccountName,
      );
    }

    if (_isProvisioningDedicatedAccount) return null;

    _isProvisioningDedicatedAccount = true;
    _dedicatedAccountMessage = null;
    notifyListeners();

    try {
      final result = await PaystackPaymentService.instance
          .requestDedicatedAccount(
            fullName: fullName,
            phone: phone,
            amountNaira: amountNaira,
            forceNew: force && amountNaira != null,
          );
      if (result.isAssigned) {
        _dedicatedAccountNeedsProfile = false;
        _dedicatedAccountMessage = null;
        _activeTransferAmountNaira =
            result.transferAmountNaira ?? result.amountNaira;
        _activeTransferReference = result.reference;
        _walletSummary = WalletSummary(
          balance: _walletSummary?.balance ?? 0.0,
          currency: _walletSummary?.currency ?? 'NGN',
          virtualAccountNumber: result.accountNumber,
          virtualAccountBank: result.bankName,
          virtualAccountName: result.accountName,
          paystackDvaStatus: 'assigned',
          totalFunded: _walletSummary?.totalFunded ?? 0.0,
          totalSpent: _walletSummary?.totalSpent ?? 0.0,
        );
        await fetchWallet(uid);
      } else {
        _dedicatedAccountNeedsProfile = false;
        _dedicatedAccountMessage =
            result.message ??
            'Your transfer account is being prepared. Refresh this page shortly.';
      }
      return result;
    } on PaystackPaymentException catch (error) {
      _dedicatedAccountNeedsProfile = error.needsProfileDetails;
      _dedicatedAccountMessage = error.message;
      return null;
    } catch (_) {
      _dedicatedAccountMessage =
          'Could not prepare your personal bank transfer account right now. Please try again.';
      return null;
    } finally {
      _isProvisioningDedicatedAccount = false;
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
      _errorMessage =
          'Your transaction history is temporarily unavailable. Please try again.';
      debugPrint('Wallet transaction history fetch failed: $error');
      rethrow;
    }
  }
}
