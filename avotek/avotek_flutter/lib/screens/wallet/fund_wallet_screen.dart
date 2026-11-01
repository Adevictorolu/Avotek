import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/paystack_payment_service.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/top_notification.dart';

class FundWalletScreen extends StatefulWidget {
  const FundWalletScreen({super.key});

  @override
  State<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends State<FundWalletScreen> {
  final _amountController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isStartingPayment = false;
  bool _isCheckingPayment = false;
  bool _isRefreshingTransfer = false;
  String? _lastVerifiedReference;
  String? _callbackReference;
  String? _verificationMessage;
  Uri? _authorizationUri;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFundingScreen();
      _checkCallbackReference();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initializeFundingScreen() async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.user;
    if (user == null) return;

    if (_fullNameController.text.isEmpty &&
        user.name.isNotEmpty &&
        user.name.toLowerCase() != 'avotek user') {
      _fullNameController.text = user.name;
    }
    if (_phoneController.text.isEmpty && user.phone.isNotEmpty) {
      _phoneController.text = user.phone;
    }

    await wallet.fetchWallet(user.id);
  }

  Future<void> _activateDedicatedAccount() async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.user;
    if (user == null) return;

    final fullName = _fullNameController.text.trim().isNotEmpty
        ? _fullNameController.text.trim()
        : user.name;
    final phone = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : user.phone;

    final result = await wallet.ensureDedicatedAccount(
      user.id,
      fullName: fullName.isNotEmpty ? fullName : null,
      phone: phone.isNotEmpty ? phone : null,
    );
    if (!mounted) return;

    if (result != null && result.isAssigned) {
      TopNotification.showSuccess(
        context,
        'Your dedicated ${result.bankName} account (${result.accountNumber}) is ready!',
        title: 'Dedicated Account Activated',
      );
    } else {
      TopNotification.showInfo(
        context,
        wallet.dedicatedAccountMessage ??
            'Your personal bank account is not available yet. Check Fund Wallet for available options.',
        title: 'Dedicated Account Status',
      );
    }
  }

  Future<void> _refreshTransferBalance() async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final userId = auth.user?.id;
    if (userId == null || _isRefreshingTransfer) return;

    final previousBalance = wallet.balance;
    setState(() => _isRefreshingTransfer = true);
    try {
      try {
        await PaystackPaymentService.instance.verifyLatest();
      } catch (_) {}
      await Future.wait([
        auth.refreshWallet(),
        wallet.fetchWallet(userId),
      ]);
      if (!mounted) return;
      final newBalance = wallet.balance;
      if (newBalance > previousBalance) {
        final credited = newBalance - previousBalance;
        TopNotification.showSuccess(
          context,
          '₦${credited.toStringAsFixed(2)} transfer received! New balance: ₦${newBalance.toStringAsFixed(2)}.',
          title: 'Wallet credited',
        );
      } else {
        TopNotification.showInfo(
          context,
          'Wallet refreshed. Once Paystack confirms your bank transfer, your balance updates automatically.',
          title: 'Balance up to date',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingTransfer = false);
      }
    }
  }

  Future<void> _checkCallbackReference() async {
    final reference = GoRouterState.of(
      context,
    ).uri.queryParameters['reference'];
    if (reference == null ||
        !RegExp(r'^AVOFUND_[A-Fa-f0-9]{32}$').hasMatch(reference) ||
        reference == _lastVerifiedReference) {
      return;
    }
    _lastVerifiedReference = reference;
    setState(() {
      _callbackReference = reference;
      _isCheckingPayment = true;
    });
    await _verifyPayment(reference);
  }

  Future<void> _showPaymentSuccessDialog({
    required double amountNaira,
    required String reference,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF10B981),
          size: 52,
        ),
        title: Text(
          'Payment successful',
          textAlign: TextAlign.center,
          style: GoogleFonts.figtree(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₦${amountNaira.toStringAsFixed(2)}',
              style: GoogleFonts.figtree(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0052FF),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Your wallet has been credited.'),
            const SizedBox(height: 12),
            SelectableText(
              'Transaction reference\n$reference',
              textAlign: TextAlign.center,
              style: GoogleFonts.figtree(
                fontSize: 12,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPayment(String reference) async {
    setState(() {
      _isCheckingPayment = true;
      _verificationMessage = null;
    });
    try {
      final verification = await PaystackPaymentService.instance.verify(
        reference: reference,
      );
      if (!mounted) return;
      if (verification.status == 'completed') {
        final userId = context.read<AuthProvider>().user?.id;
        if (userId != null) {
          await context.read<WalletProvider>().fetchWallet(userId);
        }
        if (!mounted) return;
        setState(() {
          _callbackReference = null;
          _verificationMessage = null;
          _authorizationUri = null;
        });
        await _showPaymentSuccessDialog(
          amountNaira: verification.amountNaira!,
          reference: verification.reference,
        );
      } else if (verification.status == 'failed') {
        setState(() {
          _callbackReference = null;
          _verificationMessage = null;
          _authorizationUri = null;
        });
        TopNotification.showError(
          context,
          'Paystack did not complete this payment. Your wallet was not credited.',
          title: 'Payment failed',
        );
      } else {
        setState(() {
          _callbackReference = reference;
          _verificationMessage =
              'Payment is not confirmed yet. Your wallet has not been credited. You can check this reference again shortly.';
        });
        TopNotification.showInfo(
          context,
          _verificationMessage!,
          title: 'Payment pending',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _callbackReference = reference;
          _verificationMessage =
              'Payment confirmation is delayed. Your wallet has not been credited. Check again using reference $reference.';
        });
        TopNotification.showError(
          context,
          _verificationMessage!,
          title: 'Verification pending',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingPayment = false);
      }
    }
  }

  Future<void> _startPayment({List<String>? channels}) async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount < 100 || amount > 1000000) {
      TopNotification.showWarning(
        context,
        'Enter an amount between ₦100 and ₦1,000,000.',
      );
      return;
    }

    setState(() => _isStartingPayment = true);
    try {
      final session = await PaystackPaymentService.instance.initialize(
        amountNaira: amount,
        channels: channels,
      );
      if (!mounted) return;
      final isBankTransfer = channels != null &&
          channels.length == 1 &&
          channels.first == 'bank_transfer';
      setState(() {
        _callbackReference = session.reference;
        _authorizationUri = Uri.parse(session.authorizationUrl);
        _verificationMessage = isBankTransfer
            ? 'Paystack Bank Transfer window is open. Transfer into the account displayed by Paystack, then return here and verify.'
            : 'Checkout is ready. After paying, return here and check your payment status.';
      });
      await _openCheckout();
    } catch (error) {
      if (mounted) {
        if (error is PaystackPaymentException && error.reference != null) {
          setState(() {
            _callbackReference = error.reference;
            _verificationMessage =
                'Payment initialization could not be confirmed. Check the status before starting another payment.';
          });
        }
        TopNotification.showError(
          context,
          error.toString(),
          title: 'Could not start payment',
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingPayment = false);
    }
  }

  Future<void> _openCheckout() async {
    final authorizationUri = _authorizationUri;
    if (authorizationUri == null) return;

    try {
      final opened = await launchUrl(
        authorizationUri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      if (!opened && mounted) {
        TopNotification.showError(
          context,
          'Could not open Paystack checkout. Use the Open secure checkout button to try again.',
          title: 'Checkout unavailable',
        );
      }
    } catch (error) {
      if (mounted) {
        TopNotification.showError(
          context,
          'Could not open Paystack checkout: $error',
          title: 'Checkout unavailable',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final wallet = context.watch<WalletProvider>();

    return ResponsiveShell(
      currentRoute: '/wallet/fund',
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 36 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fund your wallet',
                  style: GoogleFonts.figtree(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Instant credit via Bank Transfer or Card.',
                  style: GoogleFonts.figtree(
                    fontSize: 13.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                // 1. Paystack Direct Hero Section (Primary)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141720) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF26334D)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0052FF).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF0052FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Current Balance',
                                style: GoogleFonts.figtree(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₦${wallet.balance.toStringAsFixed(2)}',
                            style: GoogleFonts.figtree(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        height: 1,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D2FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFF00D2FF),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Instant Wallet Funding',
                                  style: GoogleFonts.figtree(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Bank Transfer, Card, or USSD',
                                  style: GoogleFonts.figtree(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '⚡ 100% INSTANT',
                              style: GoogleFonts.figtree(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select or enter amount to fund:',
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [500, 1000, 2000, 5000, 10000, 20000].map((preset) {
                          final isSelected = _amountController.text == preset.toString();
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _amountController.text = preset.toString();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0052FF)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00D2FF)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Text(
                                '₦${preset.toString()}',
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_isStartingPayment &&
                              !_isCheckingPayment &&
                              _authorizationUri == null) {
                            _startPayment();
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(7),
                        ],
                        style: GoogleFonts.figtree(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount (NGN)',
                          labelStyle: GoogleFonts.figtree(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          hintText: 'Enter custom amount e.g. 1000',
                          hintStyle: GoogleFonts.figtree(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          prefixText: '₦ ',
                          prefixStyle: GoogleFonts.figtree(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.electricCyan : const Color(0xFF0038B8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Minimum ₦100; maximum ₦1,000,000 • 100% Instant Credit',
                          helperStyle: GoogleFonts.figtree(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Primary Button: Transfer via Bank Account (Paystack)
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0052FF), Color(0xFF0038B8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0052FF).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isStartingPayment ||
                                  _isCheckingPayment ||
                                  _authorizationUri != null
                              ? null
                              : () => _startPayment(channels: ['bank_transfer']),
                          icon: _isStartingPayment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.account_balance_rounded),
                          label: Text(
                            _isStartingPayment
                                ? 'Connecting Paystack Bank Transfer...'
                                : _authorizationUri != null
                                ? 'Paystack Checkout Ready'
                                : 'Transfer via Bank Account',
                            style: GoogleFonts.figtree(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Secondary Button: Pay with Card / USSD
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isStartingPayment ||
                                  _isCheckingPayment ||
                                  _authorizationUri != null
                              ? null
                              : () => _startPayment(channels: ['card', 'ussd', 'bank']),
                          icon: const Icon(Icons.credit_card_rounded, size: 18),
                          label: Text(
                            'Pay with Debit Card or USSD',
                            style: GoogleFonts.figtree(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0052FF),
                            side: const BorderSide(color: Color(0xFF0052FF), width: 1.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_authorizationUri != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0052FF).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0052FF).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paystack Checkout Session Active',
                                style: GoogleFonts.figtree(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A checkout page has been created. Click the button below to complete payment via Bank Transfer, Card or USSD. Once done, return here and tap "Verify Payment".',
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _openCheckout,
                                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                      label: const Text('Open Checkout Window'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0052FF),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: _isCheckingPayment
                                        ? null
                                        : () => _verifyPayment(_callbackReference!),
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Verify Payment'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_isCheckingPayment) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text('Verifying your payment securely with Paystack...'),
                      ],
                      if (_callbackReference != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _verificationMessage ??
                              'Payment confirmation pending.',
                          style: GoogleFonts.figtree(
                            fontSize: 12.5,
                            height: 1.5,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText('Reference: $_callbackReference'),
                        TextButton.icon(
                          onPressed: _isCheckingPayment
                              ? null
                              : () => _verifyPayment(_callbackReference!),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Check payment status'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 2. Dedicated Virtual Account Card
                _buildDedicatedAccountSection(context, wallet, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDedicatedAccountSection(
    BuildContext context,
    WalletProvider wallet,
    bool isDark,
  ) {
    final summary = wallet.walletSummary;
    final hasDedicated = wallet.hasDedicatedAccount &&
        summary != null &&
        summary.virtualAccountNumber != null &&
        summary.virtualAccountNumber!.isNotEmpty &&
        summary.virtualAccountBank != null &&
        summary.virtualAccountBank!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141720) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: Color(0xFF0052FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dedicated Virtual Account',
                      style: GoogleFonts.figtree(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      hasDedicated
                          ? 'Automated 24/7 instant funding account'
                          : 'Permanent dedicated Nigerian bank account',
                      style: GoogleFonts.figtree(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDedicated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '● ACTIVE',
                    style: GoogleFonts.figtree(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasDedicated) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0052FF).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  _buildAccountDetailRow(
                    'Bank Name',
                    summary.virtualAccountBank ?? 'Paystack Partner Bank',
                    isDark,
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Number',
                            style: GoogleFonts.figtree(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            summary.virtualAccountNumber!,
                            style: GoogleFonts.figtree(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: const Color(0xFF0052FF),
                            ),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: summary.virtualAccountNumber!),
                          );
                          TopNotification.showSuccess(
                            context,
                            'Account number copied to clipboard!',
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy account number',
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildAccountDetailRow(
                    'Account Name',
                    summary.virtualAccountName ?? 'Avotek User',
                    isDark,
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'A dedicated virtual account provides a personal Nigerian bank account number permanently assigned to your Avotek wallet. Any money sent to this account from any banking app credits your wallet automatically.',
              style: GoogleFonts.figtree(
                fontSize: 12.5,
                height: 1.5,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: wallet.isProvisioningDedicatedAccount
                      ? null
                      : _activateDedicatedAccount,
                  icon: wallet.isProvisioningDedicatedAccount
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_outlined, size: 18),
                  label: Text(
                    wallet.isProvisioningDedicatedAccount
                        ? 'Checking Paystack...'
                        : 'Check / Request Dedicated Account',
                    style: GoogleFonts.figtree(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            if (wallet.dedicatedAccountMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                wallet.dedicatedAccountMessage!,
                style: GoogleFonts.figtree(
                  fontSize: 11.5,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAccountDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.figtree(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.figtree(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
