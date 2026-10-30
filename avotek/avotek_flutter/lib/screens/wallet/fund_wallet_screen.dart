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
    if (!mounted) return;
    if (!wallet.hasDedicatedAccount) {
      await wallet.ensureDedicatedAccount(
        user.id,
        fullName: user.name.isNotEmpty ? user.name : null,
        phone: user.phone.isNotEmpty ? user.phone : null,
      );
      if (mounted) {
        await auth.refreshWallet();
      }
    }
  }

  Future<void> _activateDedicatedAccount() async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.user;
    if (user == null) return;

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (wallet.dedicatedAccountNeedsProfile) {
      final parts = fullName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
      if (parts.length < 2) {
        TopNotification.showWarning(
          context,
          'Enter both your first name and last name.',
        );
        return;
      }
      if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
        TopNotification.showWarning(
          context,
          'Enter a valid Nigerian phone number (e.g. 08012345678).',
        );
        return;
      }
    }

    final result = await wallet.ensureDedicatedAccount(
      user.id,
      fullName: fullName.isNotEmpty ? fullName : null,
      phone: phone.isNotEmpty ? phone : null,
      force: true,
    );
    if (!mounted) return;

    if (fullName.isNotEmpty || phone.isNotEmpty) {
      await auth.updateProfile(
        name: fullName.isNotEmpty ? fullName : null,
        phone: phone.isNotEmpty ? phone : null,
      );
    }
    await auth.refreshWallet();
    if (!mounted) return;

    if (result != null && result.isAssigned) {
      TopNotification.showSuccess(
        context,
        'Your personal ${result.bankName} account (${result.accountNumber}) is active!',
        title: 'Dedicated account ready',
      );
    } else if (wallet.dedicatedAccountMessage != null) {
      TopNotification.showInfo(
        context,
        wallet.dedicatedAccountMessage!,
        title: 'Account status',
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₦${amountNaira.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
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
              style: GoogleFonts.plusJakartaSans(
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

  Future<void> _generateAmountTransferAccount() async {
    final amt = int.tryParse(_amountController.text.trim());
    if (amt == null || amt < 100 || amt > 1000000) {
      TopNotification.showWarning(
        context,
        'Enter an amount between ₦100 and ₦1,000,000.',
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.user;
    if (user == null) return;
    final res = await wallet.createTransferAccount(amt);
    if (!mounted) return;
    if (res == null || !res.isAssigned) {
      TopNotification.showError(
        context,
        wallet.dedicatedAccountMessage ??
            'Could not generate a transfer account right now.',
        title: 'Transfer account unavailable',
      );
    }
  }

  Future<void> _startPayment() async {
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
      );
      if (!mounted) return;
      setState(() {
        _callbackReference = session.reference;
        _authorizationUri = Uri.parse(session.authorizationUrl);
        _verificationMessage =
            'Checkout is ready. After paying, return here and check your payment status.';
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

  Widget _buildDedicatedAccountSection(
    BuildContext context,
    WalletProvider wallet,
    bool isDark,
  ) {
    final summary = wallet.walletSummary;
    final hasDedicated = wallet.hasDedicatedAccount && summary != null;
    final currentUser = context.watch<AuthProvider>().user;
    final needsSecurityKyc = wallet.dedicatedAccountNeedsProfile ||
        (currentUser != null &&
            (currentUser.phone.replaceAll(RegExp(r'\D'), '').length < 10 ||
                currentUser.name.trim().isEmpty ||
                currentUser.name.toLowerCase() == 'avotek user'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF131F38)]
              : [const Color(0xFFEFF6FF), const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.electricCyan.withValues(alpha: 0.35)
              : const Color(0xFFBFDBFE),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052FF).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF0052FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Bank Transfer Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fund directly from your bank app without leaving Avotek',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  hasDedicated ? 'ACTIVE' : (wallet.dedicatedAccountUnavailable ? 'ACTIVATING' : 'IN-APP'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (hasDedicated) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E17) : Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                    children: [
                      Text(
                        (summary.virtualAccountBank != null &&
                                (summary.virtualAccountBank!.toLowerCase().contains('titan') ||
                                    summary.virtualAccountBank!.toLowerCase().contains('paystack')))
                            ? 'TITAN TRUST BANK (PAYSTACK)'
                            : (summary.virtualAccountBank ?? 'DEDICATED BANK')
                                .toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF0052FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (summary.virtualAccountBank != null &&
                      (summary.virtualAccountBank!.toLowerCase().contains('titan') ||
                          summary.virtualAccountBank!.toLowerCase().contains('paystack'))) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Tip: Select "Titan Trust Bank" in your bank app transfer list',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: SelectableText(
                          summary.virtualAccountNumber!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: summary.virtualAccountNumber!),
                          );
                          TopNotification.showSuccess(
                            context,
                            'Account number ${summary.virtualAccountNumber} copied to clipboard!',
                            title: 'Copied',
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Number'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Account Name: ${summary.virtualAccountName ?? 'Avotek Customer'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Transfer to this personal Paystack account number from your banking app. Paystack deducts its 1.5% transfer fee and credits the net amount directly to your Avotek wallet (for example, ₦100 paid credits ₦98.50).',
              style: GoogleFonts.plusJakartaSans(
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRefreshingTransfer
                        ? null
                        : _refreshTransferBalance,
                    icon: _isRefreshingTransfer
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      _isRefreshingTransfer
                          ? 'Checking balance...'
                          : "I've sent the money • Refresh",
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.electricCyan
                          : const Color(0xFF0052FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: wallet.isProvisioningDedicatedAccount
                      ? null
                      : _activateDedicatedAccount,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Tooltip(
                    message: 'Rotate / refresh transfer account number',
                    child: Icon(Icons.autorenew_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ] else if (wallet.isProvisioningDedicatedAccount) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Assigning your personalized Paystack transfer account number...',
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (wallet.dedicatedAccountMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  wallet.dedicatedAccountMessage!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.5,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
            if (needsSecurityKyc) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF0052FF),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Provide your legal name and Nigerian phone number to generate your permanent Paystack transfer account.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name (First & Last Name)',
                  hintText: 'For example, Adewale Okafor',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nigerian Phone Number',
                  hintText: '08012345678',
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (!wallet.dedicatedAccountUnavailable)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _activateDedicatedAccount,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(
                  needsSecurityKyc
                      ? 'Save Details & Generate Personal Account'
                      : 'Get Personal Transfer Account Number',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Transfer to your dedicated Paystack virtual account without leaving this screen, or fund via Paystack checkout.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDedicatedAccountSection(context, wallet, isDark),
                const SizedBox(height: 20),
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
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFF0052FF),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Current balance',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₦${wallet.balance.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Or pay via Paystack Checkout (Card / USSD)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        decoration: InputDecoration(
                          labelText: 'Amount (NGN)',
                          hintText: 'For example, 1000',
                          prefixText: '₦ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Minimum ₦100; maximum ₦1,000,000',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: wallet.isCreatingTransfer
                              ? null
                              : _generateAmountTransferAccount,
                          icon: wallet.isCreatingTransfer
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
                            wallet.isCreatingTransfer
                                ? 'Generating transfer account...'
                                : 'Pay by Bank Transfer (shows account here)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (wallet.activeTransfer != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transfer exactly ₦${(wallet.activeTransfer!.transferAmountNaira ?? wallet.activeTransfer!.amountNaira ?? 0).toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                '${wallet.activeTransfer!.bankName}  •  ${wallet.activeTransfer!.accountNumber}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Account name: ${wallet.activeTransfer!.accountName}. Paystack deducts its 1.5% transfer fee and credits the net amount directly to your wallet; then tap "I\'ve sent the money".',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: wallet.activeTransfer!.accountNumber!,
                                        ),
                                      );
                                      TopNotification.showSuccess(
                                        context,
                                        'Account number copied.',
                                        title: 'Copied',
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                    label: const Text('Copy number'),
                                  ),
                                  const SizedBox(width: 10),
                                  TextButton.icon(
                                    onPressed: _isRefreshingTransfer
                                        ? null
                                        : _refreshTransferBalance,
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text("I've sent the money"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isStartingPayment ||
                                  _isCheckingPayment ||
                                  _authorizationUri != null
                              ? null
                              : _startPayment,
                          icon: _isStartingPayment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_rounded),
                          label: Text(
                            _isStartingPayment
                                ? 'Preparing secure checkout...'
                                : _authorizationUri != null
                                ? 'Checkout ready'
                                : 'Continue to Paystack',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_authorizationUri != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openCheckout,
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Open secure checkout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0052FF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_isCheckingPayment) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text('Verifying your payment securely...'),
                      ],
                      if (_callbackReference != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _verificationMessage ??
                              'Payment confirmation pending.',
                          style: GoogleFonts.plusJakartaSans(
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
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141720)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF26334D)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Never send your card details or payment credentials to Avotek support. Bank transfers to your dedicated account and checkout payments are credited only after Paystack verification by the server.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            height: 1.55,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
