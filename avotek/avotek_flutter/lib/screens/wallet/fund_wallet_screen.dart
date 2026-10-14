import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/paystack_payment_service.dart';
import '../../core/shell/responsive_shell.dart';
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
  bool _isStartingPayment = false;
  bool _isCheckingPayment = false;
  String? _lastVerifiedReference;
  String? _callbackReference;
  String? _verificationMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCallbackReference();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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

  Future<void> _verifyPayment(String reference) async {
    setState(() {
      _isCheckingPayment = true;
      _verificationMessage = null;
    });
    try {
      final status = await PaystackPaymentService.instance.verify(
        reference: reference,
      );
      if (!mounted) return;
      if (status == 'completed') {
        final userId = context.read<AuthProvider>().user?.id;
        if (userId != null) {
          await context.read<WalletProvider>().fetchWallet(userId);
        }
        if (!mounted) return;
        setState(() {
          _callbackReference = null;
          _verificationMessage = null;
        });
        TopNotification.showSuccess(
          context,
          'Your payment is confirmed and your wallet has been updated.',
          title: 'Wallet funded',
        );
      } else if (status == 'failed') {
        setState(() {
          _callbackReference = null;
          _verificationMessage = null;
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
        _verificationMessage =
            'Checkout is ready. After paying, return here and check your payment status.';
      });
      final opened = await launchUrl(
        Uri.parse(session.authorizationUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        TopNotification.showError(
          context,
          'Could not open Paystack checkout. Your wallet has not been charged. Reference: ${session.reference}',
          title: 'Checkout unavailable',
        );
        return;
      }
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
                  'Pay securely with Paystack. Wallet funds are added only after server-side payment verification.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
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
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
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
                          onPressed: _isStartingPayment || _isCheckingPayment
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
                          'Never send your card details or payment credentials to Avotek support. Returning from checkout does not itself confirm payment; the wallet changes only after Paystack is verified by the server. If confirmation is delayed, check Transactions before attempting another payment.',
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
