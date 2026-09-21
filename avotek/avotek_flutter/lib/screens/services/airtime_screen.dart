import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedNetwork = 'MTN';
  bool _saveBeneficiary = false;
  final _beneficiaryNameController = TextEditingController();

  final List<String> _networks = ['MTN', 'AIRTEL', 'GLO', '9MOBILE'];
  final List<double> _presetAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user?.id != null) {
        context.read<VtuProvider>().fetchBeneficiaries(auth.user!.id!, serviceType: 'airtime');
      }
    });
  }

  void _onPhoneChanged() {
    final text = _phoneController.text.trim();
    if (text.length >= 4) {
      final detected = VtuProvider.detectNetwork(text);
      if (detected != _selectedNetwork) {
        setState(() => _selectedNetwork = detected);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _beneficiaryNameController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    final phone = _phoneController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    if (amount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum airtime amount is ₦50')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();

    if (wallet.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Please fund your wallet (₦${wallet.balance.toStringAsFixed(2)} available).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show 4-digit PIN confirmation
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Airtime Purchase',
      amount: amount,
      description: 'Airtime to $phone ($_selectedNetwork)',
      onPinSubmit: (pin) => auth.verifyPin(pin),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.buyAirtime(
          userId: auth.user!.id!,
          network: _selectedNetwork,
          phone: phone,
          amount: amount,
        );

        if (_saveBeneficiary && _beneficiaryNameController.text.isNotEmpty) {
          await vtu.saveBeneficiary(
            userId: auth.user!.id!,
            serviceType: 'airtime',
            networkProvider: _selectedNetwork,
            recipientIdentifier: phone,
            name: _beneficiaryNameController.text.trim(),
          );
        }

        wallet.recordDebit(
          userId: auth.user!.id!,
          amount: amount,
          serviceName: 'Airtime Recharge: ₦${amount.toStringAsFixed(2)} to $phone ($_selectedNetwork)',
          reference: result.order.providerReference ?? 'TX-AVO-AIR-${DateTime.now().millisecondsSinceEpoch}',
        );
        await wallet.fetchWallet(auth.user!.id!);

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text('Purchase Successful!'),
              ],
            ),
            content: Text(
              '₦$amount airtime sent to $phone ($_selectedNetwork).\nReference: ${result.order.providerReference ?? result.order.id}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vtu = context.watch<VtuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Airtime'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Network selection chips
              Text(
                'Select Network Provider',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _networks.map((net) {
                  final isSelected = net == _selectedNetwork;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(net),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedNetwork = net);
                        },
                        selectedColor: isDark ? AppColors.primaryCyan : AppColors.primaryBlue,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? (isDark ? const Color(0xFF002B47) : Colors.white)
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Phone number input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '0803 123 4567',
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.primaryCyan : AppColors.primaryBlue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedNetwork,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.primaryCyan : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ),
              // Beneficiary shortcuts
              if (vtu.beneficiaries.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: vtu.beneficiaries.length,
                    itemBuilder: (ctx, i) {
                      final b = vtu.beneficiaries[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.history_rounded, size: 14),
                          label: Text('${b.name} (${b.recipientIdentifier})'),
                          onPressed: () {
                            _phoneController.text = b.recipientIdentifier;
                            setState(() => _selectedNetwork = b.networkProvider);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 18),
              // Amount input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₦)',
                  hintText: 'e.g. 1000',
                  prefixText: '₦ ',
                  prefixIcon: Icon(Icons.payments_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              // Preset amounts chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetAmounts.map((amt) {
                  return ActionChip(
                    label: Text('₦${amt.toInt()}'),
                    onPressed: () {
                      _amountController.text = amt.toInt().toString();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              CheckboxListTile(
                value: _saveBeneficiary,
                onChanged: (val) => setState(() => _saveBeneficiary = val ?? false),
                title: const Text('Save as beneficiary', style: TextStyle(fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (_saveBeneficiary) ...[
                TextField(
                  controller: _beneficiaryNameController,
                  decoration: const InputDecoration(
                    labelText: 'Beneficiary Name',
                    hintText: 'e.g. Mom, Bro, Work',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: vtu.isLoading ? null : _handlePurchase,
                child: vtu.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Purchase Airtime'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
