import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_card.dart';
import '../../widgets/status_badge.dart';

class StudentWalletScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const StudentWalletScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final formattedBalance = currencyFormat.format(wallet.balance);
    final accountNumber = wallet.walletSummary?.virtualAccountNumber ?? '2205178431';
    final bankName = wallet.walletSummary?.virtualAccountBank ?? 'Providus Bank';

    return ResponsiveShell(
      currentRoute: '/wallet',
      onToggleTheme: onToggleTheme,
      child: RefreshIndicator(
        onRefresh: () async {
          if (auth.user?.id != null) {
            await wallet.fetchWallet(auth.user!.id!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AdaptiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                const Text(
                  'My Student Wallet',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Central balance for examination tokens, study data bundles, airtime recharge, and automated refunds.',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                ),
                const SizedBox(height: 24),

                // 1. Dedicated Wallet Card (Adapted from Meridian)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [const Color(0xFF0A66C2), const Color(0xFF0052A3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A66C2).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  wallet.isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                onPressed: wallet.toggleBalanceVisibility,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Verified NUBAN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        wallet.isBalanceVisible ? '₦$formattedBalance' : '₦ • • • • • •',
                        style: GoogleFonts.montserrat(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dedicated Bank Transfer Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dedicated Account Number', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      accountNumber,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: accountNumber));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Account number copied to clipboard!')),
                                        );
                                      },
                                      child: const Icon(Icons.copy, color: Colors.white70, size: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(bankName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                const Text('Instant Topup Reflection', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Direct Actions (Prompt specifies: Fund Wallet, Buy Exam PIN, Buy Airtime, Buy Data, View Transactions)
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildActionsGrid(context, isDesktop),
                const SizedBox(height: 32),

                // 3. Transactions List & Filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Wallet Ledger & Statement',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.push('/transactions'),
                      child: const Row(
                        children: [
                          Text('Full History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildLedgerList(wallet, isDark),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context, bool isDesktop) {
    final actions = [
      {
        'title': 'Fund Wallet',
        'sub': 'Bank Transfer or Card',
        'icon': Icons.add_circle_outline,
        'color': const Color(0xFF0070F3),
        'onTap': () => context.push('/wallet/fund'),
      },
      {
        'title': 'Buy Exam PIN',
        'sub': 'WAEC, JAMB, NECO tokens',
        'icon': Icons.school_outlined,
        'color': const Color(0xFF059669),
        'onTap': () => context.push('/exams'),
      },
      {
        'title': 'Buy Study Data',
        'sub': 'SME & Gifting Bundles',
        'icon': Icons.wifi,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => context.push('/services/data'),
      },
      {
        'title': 'Buy Airtime',
        'sub': 'Discount on all networks',
        'icon': Icons.phone_android,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.push('/services/airtime'),
      },
    ];

    final columns = isDesktop ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: isDesktop ? 1.9 : 1.4,
      ),
      itemCount: actions.length,
      itemBuilder: (ctx, i) {
        final a = actions[i];
        final col = a['color'] as Color;

        return AvotekCard(
          padding: const EdgeInsets.all(16),
          onTap: a['onTap'] as VoidCallback,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(a['icon'] as IconData, color: col, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(a['sub'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerList(WalletProvider wallet, bool isDark) {
    final txs = wallet.transactions;

    return AvotekCard(
      padding: EdgeInsets.zero,
      child: txs.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No transactions recorded yet.')),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.length.clamp(0, 6),
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (c, i) {
                final tx = txs[i];
                final isCredit = tx.type == 'topup' || tx.type == 'credit';
                final amountPrefix = isCredit ? '+₦' : '-₦';
                final amountColor = isCredit ? const Color(0xFF059669) : (isDark ? Colors.white : Colors.black87);
                final dateFormat = DateFormat('MMM d, h:mm a');

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCredit
                        ? const Color(0xFFE7F6EC)
                        : const Color(0xFFEFF6FF),
                    child: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 16,
                      color: isCredit ? const Color(0xFF059669) : AppColors.primaryBlue,
                    ),
                  ),
                  title: Text(tx.narration ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(
                    'Ref: ${tx.reference} • ${dateFormat.format(tx.createdAt)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amountPrefix${NumberFormat("#,##0.00").format(tx.amount)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: amountColor),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge.success(tx.status),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
