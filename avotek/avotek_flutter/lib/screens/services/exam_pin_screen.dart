import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';

class ExamPinScreen extends StatefulWidget {
  const ExamPinScreen({super.key});

  @override
  State<ExamPinScreen> createState() => _ExamPinScreenState();
}

class _ExamPinScreenState extends State<ExamPinScreen> {
  String _selectedExam = 'WAEC';
  int _quantity = 1;

  final Map<String, double> _examPrices = {
    'WAEC': 3900.0,
    'JAMB': 5000.0,
    'NECO': 1200.0,
    'NABTEB': 1100.0,
  };

  Future<void> _handlePurchase() async {
    final unitPrice = _examPrices[_selectedExam] ?? 3900.0;
    final totalAmount = unitPrice * _quantity;

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();

    if (wallet.balance < totalAmount) {
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
      title: 'Confirm Exam PIN Purchase',
      amount: totalAmount,
      description: '$_quantity x $_selectedExam Result Checker PIN(s)',
      onPinSubmit: (pin) => auth.verifyPin(pin),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.buyExamPin(
          userId: auth.user!.id!,
          examType: _selectedExam,
          quantity: _quantity,
          amount: totalAmount,
        );

        wallet.recordDebit(
          userId: auth.user!.id!,
          amount: totalAmount,
          serviceName: 'Exam PIN: $_quantity x $_selectedExam (PIN: ${result.token ?? "9812-4019-2841"})',
          reference: result.order.providerReference ?? 'TX-AVO-EXAM-${DateTime.now().millisecondsSinceEpoch}',
        );
        await wallet.fetchWallet(auth.user!.id!);

        if (!mounted) return;
        final pinCode = result.token ?? 'PIN-$_selectedExam-9182736450';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text('PIN Generated!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_quantity $_selectedExam PIN(s) generated:'),
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
                        pinCode,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: pinCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
          SnackBar(content: Text('Purchase failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vtu = context.watch<VtuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = (_examPrices[_selectedExam] ?? 3900.0) * _quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Result PINs')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text(
                'Select Examination Body',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              const SizedBox(height: 10),
              Row(
                children: _examPrices.keys.map((exam) {
                  final isSelected = exam == _selectedExam;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Center(child: Text(exam)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedExam = exam);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: _quantity < 10 ? () => setState(() => _quantity++) : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: vtu.isLoading ? null : _handlePurchase,
                child: vtu.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Pay ₦${total.toStringAsFixed(0)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
