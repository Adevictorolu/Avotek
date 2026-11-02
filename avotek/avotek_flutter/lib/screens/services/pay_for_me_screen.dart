import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/vtu_api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';

class PayForMeScreen extends StatefulWidget {
  final String? reference;
  final String? serviceName;
  final String? examCode;
  final int quantity;
  final double amount;
  final String? recipient;
  final String? note;
  final String? status;
  final VoidCallback? onToggleTheme;

  const PayForMeScreen({
    super.key,
    this.reference,
    this.serviceName,
    this.examCode,
    this.quantity = 1,
    this.amount = 0.0,
    this.recipient,
    this.note,
    this.status,
    this.onToggleTheme,
  });

  @override
  State<PayForMeScreen> createState() => _PayForMeScreenState();
}

class _PayForMeScreenState extends State<PayForMeScreen> {
  final _emailController = TextEditingController();
  bool _isInitializing = false;
  bool _isVerifying = false;
  bool _isPurchasingWithWallet = false;
  bool _paymentCompleted = false;

  String? _generatedPin;
  String? _generatedSerial;
  String? _completionMessage;
  Timer? _pollingTimer;

  String get _ref =>
      widget.reference?.trim().isNotEmpty == true
          ? widget.reference!.trim()
          : 'PFM${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

  String get _service =>
      widget.serviceName?.trim().isNotEmpty == true
          ? widget.serviceName!.trim()
          : 'WAEC Result Checker PIN';

  String get _exam =>
      widget.examCode?.trim().isNotEmpty == true
          ? widget.examCode!.trim().toLowerCase()
          : 'waec';

  int get _qty => widget.quantity > 0 ? widget.quantity : 1;

  double get _amt => widget.amount > 0 ? widget.amount : 5250.0;

  String get _phone =>
      widget.recipient?.trim().isNotEmpty == true
          ? widget.recipient!.trim()
          : 'Candidate';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null && user.email.isNotEmpty) {
      _emailController.text = user.email;
    }

    if (widget.status == 'success' && widget.reference != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verifyPayment());
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initializePaystack() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      TopNotification.showError(context, 'Please enter a valid email address for receipt delivery.');
      return;
    }

    setState(() => _isInitializing = true);
    try {
      final origin = kIsWeb ? '${Uri.base.origin}${Uri.base.path}' : 'https://adevictorolu.github.io/Avotek/';
      final res = await VtuApiService.instance.initializeSponsorPayment(
        email: email,
        amount: _amt,
        reference: _ref,
        service: _service,
        recipient: _phone,
        exam: _exam,
        quantity: _qty,
        origin: origin,
      );

      final authUrl = res['authorization_url']?.toString();
      if (authUrl == null || !authUrl.startsWith('https://')) {
        throw StateError(res['message']?.toString() ?? 'Could not initialize payment gateway.');
      }

      final uri = Uri.parse(authUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        TopNotification.showError(context, 'Could not open checkout page. Please disable pop-up blocker.');
      }

      // Start automatic polling every 5 seconds to catch completed payment
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!mounted || _paymentCompleted) {
          timer.cancel();
          return;
        }
        _verifyPayment(silent: true);
      });

      if (mounted) {
        TopNotification.showSuccess(
          context,
          'Checkout opened. Complete your payment and click "I Have Paid" below.',
        );
      }
    } catch (e) {
      if (mounted) {
        TopNotification.showError(
          context,
          e is StateError ? e.message : 'Payment initialization failed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _verifyPayment({bool silent = false}) async {
    if (_isVerifying || _paymentCompleted) return;
    if (!silent) setState(() => _isVerifying = true);

    try {
      final res = await VtuApiService.instance.verifySponsorPayment(
        reference: _ref,
        exam: _exam,
        quantity: _qty,
        phone: _phone,
      );

      final success = res['success'] == true || res['status'] == 'completed';
      if (success && mounted) {
        _pollingTimer?.cancel();

        setState(() {
          _paymentCompleted = true;
          _generatedPin = res['pin']?.toString();
          _generatedSerial = res['serial']?.toString();
          _completionMessage = res['message']?.toString() ?? 'Exam PIN successfully generated!';
        });

        TopNotification.showSuccess(context, 'Payment verified! Exam PIN generated.');
      } else if (!silent && mounted) {
        TopNotification.showError(
          context,
          res['message']?.toString() ?? 'Payment is not yet confirmed by the bank.',
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        TopNotification.showError(
          context,
          'Verification check pending. If you just completed payment, wait a few seconds and try again.',
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _isVerifying = false);
    }
  }

  Future<void> _payWithWallet() async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();
    final user = auth.user;

    if (user == null) {
      TopNotification.showError(context, 'Please log in to pay with your Avotek wallet.');
      return;
    }

    if (wallet.balance < _amt) {
      TopNotification.showError(
        context,
        'Insufficient balance (₦${wallet.balance.toStringAsFixed(2)} available, ₦${_amt.toStringAsFixed(2)} needed).',
      );
      return;
    }

    final confirmed = await PinModal.show(
      context,
      title: 'Pay for Exam PIN (Sponsor)',
      amount: _amt,
      description: 'Sponsor checkout for $_service\nBeneficiary: $_phone',
      onPinSubmit: (pin) async => auth.verifyPin(pin),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPurchasingWithWallet = true);
    try {
      final result = await vtu.buyExamPins(
        userId: user.id,
        examCode: _exam.toUpperCase(),
        examName: _service,
        quantity: _qty,
        unitPrice: _amt / _qty,
        phone: _phone,
      );

      await auth.refreshWallet();
      await wallet.fetchWallet(user.id);

      if (mounted) {
        setState(() {
          _paymentCompleted = true;
          _generatedPin = result.token ??
              (result.issuedPins.isNotEmpty
                  ? result.issuedPins.first
                  : (result.order.providerReference ?? result.order.id.toString()));
          _completionMessage = 'Exam PIN purchase successful! Deducted from wallet.';
        });
        TopNotification.showSuccess(context, 'PIN issued successfully!');
      }
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Wallet purchase failed. Please check balance and try again.');
      }
    } finally {
      if (mounted) setState(() => _isPurchasingWithWallet = false);
    }
  }

  void _sharePinToCandidate() {
    final pin = _generatedPin ?? 'N/A';
    final serial = _generatedSerial != null ? ' (Serial: $_generatedSerial)' : '';
    final text =
        'Hello! Here is your $_service paid via Avotek:\n\n'
        'PIN: $pin$serial\n'
        'Candidate: $_phone\n\n'
        'Check your result on the official portal:\n'
        '${_portalUrlForExam(_exam)}';

    final url = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String _portalUrlForExam(String code) {
    final c = code.toLowerCase();
    if (c.contains('waec')) return 'https://www.waecdirect.org';
    if (c.contains('neco')) return 'https://result.neco.gov.ng';
    if (c.contains('nabteb')) return 'https://eworld.nabteb.gov.ng';
    if (c.contains('jamb')) return 'https://efacility.jamb.gov.ng';
    return 'https://www.waecdirect.org';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF0F172A);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final isLoggedIn = auth.user != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E17) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111726) : Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0052FF), Color(0xFF00D2FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AVOTEK',
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Sponsor Checkout',
              style: GoogleFonts.figtree(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: foreground,
              ),
              onPressed: widget.onToggleTheme,
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: _paymentCompleted
                ? _buildSuccessView(isDark, foreground)
                : _buildPaymentView(isDark, foreground, isLoggedIn, wallet),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentView(
    bool isDark,
    Color foreground,
    bool isLoggedIn,
    WalletProvider wallet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0047FF), Color(0xFF002E99)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0047FF).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pay For Me Request',
                      style: GoogleFonts.figtree(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00D2FF)),
                    ),
                    child: Text(
                      'SECURE CHECKOUT',
                      style: GoogleFonts.figtree(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFF00D2FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'A candidate has requested you to sponsor their examination result checker PIN on Avotek.',
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Order Summary Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131826) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF222B42) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ORDER DETAILS',
                style: GoogleFonts.figtree(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Requested Item', _service, foreground, isBold: true),
              const SizedBox(height: 10),
              _buildSummaryRow('Candidate / Phone', _phone, foreground),
              const SizedBox(height: 10),
              _buildSummaryRow('Quantity', '$_qty PIN${_qty > 1 ? 's' : ''}', foreground),
              const SizedBox(height: 10),
              _buildSummaryRow('Reference', _ref, isDark ? Colors.white60 : const Color(0xFF64748B)),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Due',
                    style: GoogleFonts.figtree(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                  Text(
                    '₦${_amt.toStringAsFixed(2)}',
                    style: GoogleFonts.figtree(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00D2FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Payment Option 1: Paystack Online Checkout
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131826) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF222B42) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card_rounded, color: Color(0xFF00D2FF), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Pay with Card, Bank Transfer or USSD',
                    style: GoogleFonts.figtree(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Instant confirmation powered by Paystack. No Avotek account required.',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.figtree(color: foreground),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  labelText: 'Your Email Address (for receipt)',
                  hintText: 'e.g. sponsor@gmail.com',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF2B3652) : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isInitializing ? null : _initializePaystack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isInitializing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Pay ₦${_amt.toStringAsFixed(0)} via Paystack',
                          style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isVerifying ? null : () => _verifyPayment(),
                icon: _isVerifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'I Have Completed Payment (Check Status)',
                  style: GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Payment Option 2: Pay with Avotek Wallet (if logged in)
        if (isLoggedIn)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131826) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF222B42) : const Color(0xFFE2E8F0),
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
                        const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF00D2FF), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Pay with Avotek Wallet',
                          style: GoogleFonts.figtree(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Bal: ₦${wallet.balance.toStringAsFixed(2)}',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00D2FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isPurchasingWithWallet ? null : _payWithWallet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D2FF),
                      foregroundColor: const Color(0xFF0A0E17),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isPurchasingWithWallet
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            'Pay ₦${_amt.toStringAsFixed(0)} from Wallet Balance',
                            style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessView(bool isDark, Color foreground) {
    final pin = _generatedPin ?? 'Generated Successfully';
    final serial = _generatedSerial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131826) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF22C55E).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Successful!',
                style: GoogleFonts.figtree(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _completionMessage ?? 'Your examination PIN has been issued and is ready for use.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 24),

              // PIN Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2236) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E3956) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_service PIN',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: const Color(0xFF00D2FF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      pin,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: foreground,
                      ),
                    ),
                    if (serial != null && serial.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Serial: $serial',
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        final textToCopy = serial != null ? 'PIN: $pin\nSerial: $serial' : pin;
                        Clipboard.setData(ClipboardData(text: textToCopy));
                        TopNotification.showSuccess(context, 'PIN copied to clipboard!');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(
                        'Copy PIN',
                        style: GoogleFonts.figtree(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _sharePinToCandidate,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Share PIN to Candidate via WhatsApp',
                    style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Portal Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161C2C) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW TO CHECK RESULT:',
                      style: GoogleFonts.figtree(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFF00D2FF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Open the portal: ${_portalUrlForExam(_exam)}\n'
                      '2. Enter Candidate Examination Number and Exam Year.\n'
                      '3. Enter the PIN and Serial Number above.\n'
                      '4. Submit to display the official statement of results.',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.figtree(
            fontSize: 13,
            color: color.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.figtree(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
