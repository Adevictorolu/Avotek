import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';

class CableScreen extends StatefulWidget {
  const CableScreen({super.key});

  @override
  State<CableScreen> createState() => _CableScreenState();
}

class _CableScreenState extends State<CableScreen> {
  final _smartcardController = TextEditingController();
  String _selectedProvider = 'DSTV';
  String? _selectedPackage;
  double _packageAmount = 0.0;

  bool _isVerifying = false;
  String? _verifiedCustomerName;

  final Map<String, List<Map<String, dynamic>>> _packages = {
    'DSTV': [
      {'code': 'dstv-padi', 'name': 'DStv Padi', 'price': 3600.0},
      {'code': 'dstv-yanga', 'name': 'DStv Yanga', 'price': 5100.0},
      {'code': 'dstv-confam', 'name': 'DStv Confam', 'price': 9300.0},
      {'code': 'dstv-compact', 'name': 'DStv Compact', 'price': 15700.0},
    ],
    'GOTV': [
      {'code': 'gotv-smallie', 'name': 'GOtv Smallie', 'price': 1575.0},
      {'code': 'gotv-jinja', 'name': 'GOtv Jinja', 'price': 3300.0},
      {'code': 'gotv-jolli', 'name': 'GOtv Jolli', 'price': 4850.0},
      {'code': 'gotv-max', 'name': 'GOtv Max', 'price': 7200.0},
    ],
    'STARTIMES': [
      {'code': 'nova', 'name': 'Startimes Nova', 'price': 1700.0},
      {'code': 'basic', 'name': 'Startimes Basic', 'price': 3300.0},
      {'code': 'classic', 'name': 'Startimes Classic', 'price': 5000.0},
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedPackage = _packages[_selectedProvider]!.first['code'];
    _packageAmount = _packages[_selectedProvider]!.first['price'];
  }

  @override
  void dispose() {
    _smartcardController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final card = _smartcardController.text.trim();
    if (card.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid smartcard/IUC number')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final vtu = context.read<VtuProvider>();
    final result = await vtu.verifySmartcard(
      provider: _selectedProvider,
      smartcardNumber: card,
    );

    setState(() {
      _isVerifying = false;
      if (result.isValid) {
        _verifiedCustomerName = result.customerName ?? 'VERIFIED SUBSCRIBER';
      }
    });

    if (!result.isValid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not verify smartcard number. Please check.')),
      );
    }
  }

  Future<void> _handlePurchase() async {
    final card = _smartcardController.text.trim();
    if (card.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter smartcard number')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();

    if (wallet.balance < _packageAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance (₦${wallet.balance.toStringAsFixed(2)} available).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Cable TV Subscription',
      amount: _packageAmount,
      description: '$_selectedProvider • $card\nSubscriber: ${_verifiedCustomerName ?? "Customer"}',
      onPinSubmit: (pin) => auth.verifyPin(pin),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.payCableTV(
          userId: auth.user!.id!,
          provider: _selectedProvider,
          smartcardNumber: card,
          variationCode: _selectedPackage!,
          amount: _packageAmount,
        );

        wallet.recordDebit(
          userId: auth.user!.id!,
          amount: _packageAmount,
          serviceName: 'Cable TV: $_selectedProvider ($_selectedPackage) to $card',
          reference: result.order.providerReference ?? 'TX-AVO-CAB-${DateTime.now().millisecondsSinceEpoch}',
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
                Text('Subscribed!'),
              ],
            ),
            content: Text(
              '$_selectedProvider package activated for smartcard $card.\nRef: ${result.order.providerReference ?? result.order.id}',
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
          SnackBar(content: Text('Subscription failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vtu = context.watch<VtuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentPackages = _packages[_selectedProvider] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Cable TV Subscription')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Row(
                children: ['DSTV', 'GOTV', 'STARTIMES'].map((p) {
                  final isSelected = p == _selectedProvider;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Center(child: Text(p)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedProvider = p;
                              _selectedPackage = _packages[p]?.first['code'];
                              _packageAmount = _packages[p]?.first['price'] ?? 0.0;
                            });
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _smartcardController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Smartcard / IUC Number',
                  hintText: 'e.g. 1029384756',
                  prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                  suffixIcon: TextButton(
                    onPressed: _isVerifying ? null : _handleVerify,
                    child: _isVerifying
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Verify'),
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
                        child: Text(
                          'Subscriber: $_verifiedCustomerName',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Select Bouquet / Package',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              const SizedBox(height: 10),
              ...currentPackages.map((pkg) {
                final isSelected = pkg['code'] == _selectedPackage;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPackage = pkg['code'];
                      _packageAmount = pkg['price'];
                    });
                  },
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
                        Text(
                          pkg['name'],
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        Text(
                          '₦${pkg['price'].toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? AppColors.primaryCyan : AppColors.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: vtu.isLoading ? null : _handlePurchase,
                child: vtu.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Pay ₦${_packageAmount.toStringAsFixed(0)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
