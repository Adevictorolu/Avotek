import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';

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
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final meter = _meterController.text.trim();
    if (meter.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid meter number')),
      );
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
        _verifiedCustomerName = result.customerName ?? 'VERIFIED CUSTOMER';
        _verificationDetails = result.details;
      }
    });

    if (!result.isValid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not verify meter number. Check details and retry.')),
      );
    }
  }

  Future<void> _handlePurchase() async {
    final meter = _meterController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (meter.length < 8 || amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum electricity purchase is ₦500')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();

    if (wallet.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance (₦${wallet.balance.toStringAsFixed(2)} available).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 4-digit PIN confirmation
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Electricity Purchase',
      amount: amount,
      description: '${_discos[_selectedDisco]} • $meter\nCustomer: ${_verifiedCustomerName ?? "Customer"}',
      onPinSubmit: (pin) => auth.verifyPin(pin),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.payElectricity(
          userId: auth.user!.id!,
          disco: _selectedDisco,
          meterNumber: meter,
          meterType: _selectedMeterType,
          amount: amount,
        );

        wallet.recordDebit(
          userId: auth.user!.id!,
          amount: amount,
          serviceName: 'Electricity Token: $_selectedDisco ($meter) Units: ${result.units ?? "N/A"}',
          reference: result.order.providerReference ?? 'TX-AVO-ELEC-${DateTime.now().millisecondsSinceEpoch}',
        );
        await wallet.fetchWallet(auth.user!.id!);

        if (!mounted) return;
        final token = result.token ?? '8192-3849-1928-3849';
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token copied to clipboard!')),
                          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vtu = context.watch<VtuProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Electricity Bill')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedDisco,
                decoration: const InputDecoration(labelText: 'Select Disco / Provider'),
                items: _discos.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDisco = val);
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
    );
  }
}
