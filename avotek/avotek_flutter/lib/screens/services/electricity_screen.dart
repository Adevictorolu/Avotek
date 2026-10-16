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

    setState(() {
      _isVerifying = false;
      if (result.isValid) {
        _verifiedCustomerName = result.customerName;
        _verificationDetails = result.details;
      }
    });

    if (!result.isValid && mounted) {
      TopNotification.showError(context, 'Could not verify meter number. Check details and retry.');
    }
  }

  Future<void> _handlePurchase() async {
    final meter = _meterController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (meter.length < 8 || amount < 500) {
      TopNotification.showWarning(context, 'Minimum electricity purchase is ₦500');
      return;
    }
    if (_verifiedCustomerName == null) {
      TopNotification.showWarning(context, 'Verify this meter before purchasing.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();

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
      description: '${_discos[_selectedDisco] ?? _selectedDisco} • $meter\nCustomer: ${_verifiedCustomerName ?? "Customer"}',
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
          phone: (auth.user?.phone != null && auth.user!.phone.isNotEmpty) ? auth.user!.phone : '08000000000',
          userPin: transactionPin,
        );

        await auth.refreshWallet();
        await wallet.fetchWallet(auth.user!.id);

        if (!mounted) return;
        if (!result.success || result.order.status == 'failed') {
          TopNotification.showError(context, result.message, title: 'Payment Failed');
          return;
        }
        if (result.order.status == 'pending') {
          TopNotification.showWarning(context, result.message, title: 'Payment Pending');
          return;
        }
        final token = result.token;
        if (token == null || token.isEmpty) {
          TopNotification.showWarning(context, result.message, title: 'Payment Completed');
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
                const Text('Your prepaid electricity token is ready:', style: TextStyle(fontSize: 13)),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: token));
                          TopNotification.showSuccess(context, 'Token copied to clipboard!');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text('Units: ${result.units ?? "Available Units"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Meter: $meter (${_discos[_selectedDisco]})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
              Text(
                'Electricity Bill',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Verify your meter and purchase electricity from your wallet.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedDisco,
                decoration: const InputDecoration(labelText: 'Select Disco / Provider'),
                items: _discos.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedDisco = val;
                      _verifiedCustomerName = null;
                      _verificationDetails = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'prepaid', label: Text('Prepaid')),
                        ButtonSegment(value: 'postpaid', label: Text('Postpaid')),
                      ],
                      selected: {_selectedMeterType},
                      onSelectionChanged: (set) {
                        setState(() {
                          _selectedMeterType = set.first;
                          _verifiedCustomerName = null;
                          _verificationDetails = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _meterController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {
                  _verifiedCustomerName = null;
                  _verificationDetails = null;
                }),
                decoration: InputDecoration(
                  labelText: 'Meter Number',
                  hintText: 'e.g. 01423456789',
                  suffixIcon: IconButton(
                    icon: _isVerifying
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline),
                    tooltip: 'Verify Meter',
                    onPressed: _isVerifying ? null : _handleVerify,
                  ),
                ),
              ),
              if (_verifiedCustomerName != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer: $_verifiedCustomerName',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                            if (_verificationDetails != null && _verificationDetails!.isNotEmpty)
                              Text(
                                _verificationDetails!,
                                style: const TextStyle(fontSize: 11, color: AppColors.success),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₦)',
                  hintText: 'e.g. 5000',
                  prefixText: '₦ ',
                  prefixIcon: Icon(Icons.payments_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: vtu.isLoading ? null : _handlePurchase,
                child: vtu.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Pay Electricity Bill'),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
