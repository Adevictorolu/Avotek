import 'package:avotek_client/avotek_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _phoneController = TextEditingController();
  String _selectedNetwork = 'MTN';
  ServiceCatalog? _selectedPlan;

  final List<String> _networks = ['MTN', 'AIRTEL', 'GLO', '9MOBILE'];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VtuProvider>().fetchCatalog(serviceType: 'data');
    });
  }

  void _onPhoneChanged() {
    final text = _phoneController.text.trim();
    if (text.length >= 4) {
      final detected = VtuProvider.detectNetwork(text);
      if (detected != _selectedNetwork) {
        setState(() {
          _selectedNetwork = detected;
          _selectedPlan = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a data bundle')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();

    final sellPrice = _selectedPlan!.costPrice + _selectedPlan!.defaultMarkup;

    if (wallet.balance < sellPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Please fund your wallet (₦${wallet.balance.toStringAsFixed(2)} available).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 4-digit PIN confirmation
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Data Purchase',
      amount: sellPrice,
      description: '${_selectedPlan!.name} to $phone ($_selectedNetwork)',
      onPinSubmit: (pin) => auth.verifyPin(pin),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.buyData(
          userId: auth.user!.id!,
          network: _selectedNetwork,
          phone: phone,
          variationCode: _selectedPlan!.variationCode,
          amount: _selectedPlan!.costPrice,
          sellPrice: sellPrice,
        );

        wallet.recordDebit(
          userId: auth.user!.id!,
          amount: sellPrice,
          serviceName: 'Data Top-Up: ${_selectedPlan!.name} to $phone ($_selectedNetwork)',
          reference: result.order.providerReference ?? 'TX-AVO-DATA-${DateTime.now().millisecondsSinceEpoch}',
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
                Text('Data Delivered!'),
              ],
            ),
            content: Text(
              '${_selectedPlan!.name} delivered to $phone.\nReference: ${result.order.providerReference ?? result.order.id}',
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

    final networkPlans = vtu.catalog.where((c) => c.provider.toUpperCase() == _selectedNetwork.toUpperCase()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Data Bundle'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
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
                          if (selected) {
                            setState(() {
                              _selectedNetwork = net;
                              _selectedPlan = null;
                            });
                          }
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
              const SizedBox(height: 20),
              Text(
                'Select Bundle Plan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              if (vtu.isLoading && networkPlans.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (networkPlans.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: const Text('No plans loaded for this network yet.', textAlign: TextAlign.center),
                )
              else
                ...networkPlans.map((plan) {
                  final isSelected = _selectedPlan?.id == plan.id;
                  final price = plan.costPrice + plan.defaultMarkup;
                  return InkWell(
                    onTap: () => setState(() => _selectedPlan = plan),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.primaryCyan : AppColors.primaryBlue).withValues(alpha: 0.1)
                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppColors.primaryCyan : AppColors.primaryBlue)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Validity: 30 Days',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₦${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.primaryCyan : AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: vtu.isLoading || _selectedPlan == null ? null : _handlePurchase,
                child: vtu.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_selectedPlan != null
                        ? 'Pay ₦${(_selectedPlan!.costPrice + _selectedPlan!.defaultMarkup).toStringAsFixed(0)}'
                        : 'Select a Bundle Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
