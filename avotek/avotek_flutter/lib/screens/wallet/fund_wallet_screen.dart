import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class FundWalletScreen extends StatefulWidget {
  const FundWalletScreen({super.key});

  @override
  State<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends State<FundWalletScreen> {
  final _amountController = TextEditingController(text: '5000');
  bool _isFunding = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSimulateFund(double amount) async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();

    if (auth.user?.id == null) return;

    setState(() => _isFunding = true);
    final success = await wallet.simulateFunding(auth.user!.id!, amount);
    setState(() => _isFunding = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('₦${amount.toStringAsFixed(0)} credited to your wallet!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funding failed'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accountNumber = wallet.walletSummary?.virtualAccountNumber ?? '9031829481';
    final bankName = wallet.walletSummary?.virtualAccountBank ?? 'Wema Bank / Moniepoint';
    final accountName = wallet.walletSummary?.virtualAccountName ?? auth.user?.name ?? 'AVOTEK User';

    return Scaffold(
      appBar: AppBar(title: const Text('Fund Wallet')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Automated Bank Transfer',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Instant Credit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Bank Name', style: TextStyle(fontSize: 11, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
                    Text(bankName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Text('Account Number', style: TextStyle(fontSize: 11, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SelectableText(
                          accountNumber,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? AppColors.primaryCyan : AppColors.primaryBlue),
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: accountNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account number copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Account Name', style: TextStyle(fontSize: 11, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
                    Text(accountName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.primaryCyan : AppColors.primaryBlue).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: isDark ? AppColors.primaryCyan : AppColors.primaryBlue),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Transfer any amount to this dedicated virtual account from your bank app. Your AVOTEK wallet will credit instantly without delays.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Sandbox / Instant Test Funding',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [1000.0, 2000.0, 5000.0, 10000.0].map((amt) {
                  return ActionChip(
                    label: Text('+ ₦${amt.toInt()}'),
                    onPressed: _isFunding ? null : () => _handleSimulateFund(amt),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
