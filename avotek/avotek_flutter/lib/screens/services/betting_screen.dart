import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';

class BettingScreen extends StatefulWidget {
  const BettingScreen({super.key});

  @override
  State<BettingScreen> createState() => _BettingScreenState();
}

class _BettingScreenState extends State<BettingScreen> {
  final _customerIdController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedProvider = 'SportyBet';

  final List<String> _providers = ['SportyBet', 'Bet9ja', '1xBet', 'Betway'];

  @override
  void dispose() {
    _customerIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleFund() async {
    final customerId = _customerIdController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (customerId.isEmpty || amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum funding amount is ₦100')),
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

    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Betting Wallet Top-Up',
      amount: amount,
      description: '$_selectedProvider Account: $customerId',
      onPinSubmit: (pin) => auth.verifyPin(pin),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.fundBetting(
          userId: auth.user!.id!,
          provider: _selectedProvider,
          customerId: customerId,
          amount: amount,
        );

        wallet.recordDebit(
          userId: auth.user!.id!,
          amount: amount,
          serviceName: 'Betting Wallet: $_selectedProvider ($customerId)',
          reference: result.order.providerReference ?? 'TX-AVO-BET-${DateTime.now().millisecondsSinceEpoch}',
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
                Text('Wallet Funded!'),
              ],
            ),
            content: Text('₦$amount successfully credited to $_selectedProvider ($customerId).\nRef: ${result.order.providerReference ?? result.order.id}'),
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
          SnackBar(content: Text('Fund failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vtu = context.watch<VtuProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Betting Wallet Top-Up')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedProvider,
                decoration: const InputDecoration(labelText: 'Select Betting Platform'),
                items: _providers.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProvider = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customerIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User ID / Customer ID',
                  hintText: 'e.g. 10293847',
                  prefixIcon: Icon(Icons.person_pin_circle_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₦)',
                  hintText: 'e.g. 2000',
                  prefixText: '₦ ',
                  prefixIcon: Icon(Icons.payments_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: vtu.isLoading ? null : _handleFund,
                child: vtu.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Fund Betting Wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
