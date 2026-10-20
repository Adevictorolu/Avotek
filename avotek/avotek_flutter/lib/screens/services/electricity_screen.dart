import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final _meterController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedDisco = 'ikeja-electric';
  String _selectedMeterType = 'prepaid';

  bool _isVerifying = false;
  String? _verifiedCustomerName;
  String? _verificationDetails;

  final Map<String, String> _discos = {
    'ikeja-electric': 'Ikeja Electric (IKEDC)',
    'eko-electric': 'Eko Electric (EKEDC)',
    'abuja-electric': 'Abuja Electric (AEDC)',
    'ibadan-electric': 'Ibadan Electric (IBEDC)',
    'kano-electric': 'Kano Electric (KEDCO)',
    'enugu-electric': 'Enugu Electric (EEDC)',
    'portharcourt-electric': 'Port Harcourt (PHED)',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VtuProvider>().fetchElectricityProviders();
    });
  }

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_isVerifying) return;
    final meter = _meterController.text.trim();
    if (meter.length < 8) {
      TopNotification.showWarning(context, 'Please enter a valid meter number');
      return;
    }

    setState(() {
      _isVerifying = true;
      _verifiedCustomerName = null;
    });

    final vtu = context.read<VtuProvider>();
    final result = await vtu.verifyMeter(
      disco: _selectedDisco,
      meterNumber: meter,
      meterType: _selectedMeterType,
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      if (result.isValid) {
        _verifiedCustomerName = result.customerName;
        _verificationDetails = result.details;
      }
    });

    if (!result.isValid && mounted) {
      TopNotification.showError(
        context,
        'Could not verify meter number. Check details and retry.',
      );
    }
  }

  Future<void> _handlePurchase() async {
    final meter = _meterController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (meter.length < 8) {
      TopNotification.showWarning(
        context,
        'Please enter a valid meter number.',
      );
      return;
    }
    if (amount < 500 || amount != amount.roundToDouble()) {
      TopNotification.showWarning(
        context,
        'Enter a whole-naira amount of at least ₦500.',
      );
      return;
    }
    if (_verifiedCustomerName == null) {
      TopNotification.showWarning(
        context,
        'Verify this meter before purchasing.',
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();
    final phone = auth.user?.phone.trim() ?? '';
    if (phone.isEmpty) {
      TopNotification.showWarning(
        context,
        'Add a phone number to your account before paying this bill.',
      );
      return;
    }

    if (wallet.balance < amount) {
      TopNotification.showError(
        context,
        'Insufficient balance (₦${wallet.balance.toStringAsFixed(2)} available).',
      );
      return;
    }

    // 4-digit PIN confirmation
    String? transactionPin;
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Electricity Purchase',
      amount: amount,
      description:
          '${_discos[_selectedDisco] ?? _selectedDisco} • $meter\nCustomer: ${_verifiedCustomerName ?? "Customer"}',
      onPinSubmit: (pin) async {
        transactionPin = pin;
        return auth.verifyPin(pin);
      },
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.payElectricity(
          userId: auth.user!.id,
          disco: _selectedDisco,
          meterNumber: meter,
          meterType: _selectedMeterType,
          amount: amount,
          customerName: _verifiedCustomerName,
          phone: phone,
          userPin: transactionPin,
        );

        await auth.refreshWallet();
        await wallet.fetchWallet(auth.user!.id);

        if (!mounted) return;
        if (!result.success || result.order.status == 'failed') {
          TopNotification.showError(
            context,
            result.message,
            title: 'Payment Failed',
          );
          return;
        }
        if (result.order.status == 'pending') {
          TopNotification.showWarning(
            context,
            result.message,
            title: 'Payment Pending',
          );
          return;
        }
        final token = result.token;
        if (token == null || token.isEmpty) {
          TopNotification.showWarning(
            context,
            result.message,
            title: 'Payment Completed',
          );
          return;
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text('Token Generated!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your prepaid electricity token is ready:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryCyan),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        token,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: token));
                          TopNotification.showSuccess(
                            context,
                            'Token copied to clipboard!',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Units: ${result.units ?? "Available Units"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Meter: $meter (${_discos[_selectedDisco]})',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        TopNotification.showError(context, 'Payment failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vtu = context.watch<VtuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final canPurchase =
        !vtu.isLoading && _verifiedCustomerName != null && amount >= 500;

    return ResponsiveShell(
      currentRoute: '/services/electricity',
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0D14)
            : const Color(0xFFF8FAFC),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 24,
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.primaryCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Electricity bill',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Confirm your meter details and pay securely from your wallet.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meter details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDisco,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Electricity provider',
                          prefixIcon: Icon(Icons.power_rounded),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                        ),
                        items: _discos.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedDisco = value;
                            _verifiedCustomerName = null;
                            _verificationDetails = null;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'prepaid',
                            label: Text('Prepaid'),
                            icon: Icon(Icons.flash_on_rounded),
                          ),
                          ButtonSegment(
                            value: 'postpaid',
                            label: Text('Postpaid'),
                            icon: Icon(Icons.receipt_long_rounded),
                          ),
                        ],
                        selected: {_selectedMeterType},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _selectedMeterType = selection.first;
                            _verifiedCustomerName = null;
                            _verificationDetails = null;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _meterController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          if (!_isVerifying) _handleVerify();
                        },
                        onChanged: (_) => setState(() {
                          _verifiedCustomerName = null;
                          _verificationDetails = null;
                        }),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Meter number',
                          hintText: 'Enter your meter number',
                          prefixIcon: const Icon(Icons.speed_rounded),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 20,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: TextButton(
                              onPressed: _isVerifying ? null : _handleVerify,
                              child: _isVerifying
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Verify'),
                            ),
                          ),
                        ),
                      ),
                      if (_verifiedCustomerName != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer: $_verifiedCustomerName',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    if (_verificationDetails != null &&
                                        _verificationDetails!.isNotEmpty)
                                      Text(
                                        _verificationDetails!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.success,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Payment amount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_isVerifying) _handlePurchase();
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          hintText: '500 or more',
                          prefixText: '₦ ',
                          prefixIcon: Icon(Icons.payments_outlined),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Minimum purchase: ₦500',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.metallicLight
                              : AppColors.slateGrey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: canPurchase
                                  ? const [
                                      AppColors.primaryBlue,
                                      AppColors.primaryCyan,
                                    ]
                                  : const [
                                      Color(0xFF64748B),
                                      Color(0xFF475569),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: canPurchase ? _handlePurchase : null,
                              child: Center(
                                child: vtu.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        amount >= 500
                                            ? 'Pay ₦${amount.toStringAsFixed(0)}'
                                            : 'Enter amount and verify meter',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
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
