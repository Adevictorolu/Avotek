import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/database/app_database.dart';
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
    final funding = AppDatabaseService.instance.getFundingAccount();
    final accountNumber = funding['accountNumber'] ?? '8167002789';
    final bankName = funding['bank'] ?? 'PalmPay';

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
                // Header with in-app refresh button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Wallet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Automated bank funding, VTU debit settlements, and live balance statement.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                          ),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Refresh Balance',
                      onPressed: () async {
                        if (auth.user?.id != null) {
                          await wallet.fetchWallet(auth.user!.id!);
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Sleek Wallet Balance Card with Plus Jakarta Sans bold weight
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [const Color(0xFF0070F3), const Color(0xFF0052A3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0070F3).withValues(alpha: 0.25),
                        blurRadius: 20,
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
                              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Available Balance',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  wallet.isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.white70,
                                  size: 18,
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF6EE7B7)),
                                const SizedBox(width: 4),
                                Text(
                                  'Dedicated NUBAN',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        wallet.isBalanceVisible ? '₦$formattedBalance' : '₦ • • • • • •',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dedicated Bank Account Strip
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Official Deposit Account ($bankName - Instant Credit)',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      accountNumber,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: accountNumber));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Account number copied to clipboard!')),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  bankName,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Instant Auto-Credit',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF6EE7B7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Pure VTU Quick Actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionsGrid(context, isDesktop, isDark),
                const SizedBox(height: 28),

                // 3. Transactions Statement Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Wallet Ledger & Statement',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/transactions'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: Text(
                        'Full History',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
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

  Widget _buildActionsGrid(BuildContext context, bool isDesktop, bool isDark) {
    final actions = [
      {
        'title': 'Fund Wallet',
        'sub': 'Bank Transfer / Gateway',
        'icon': Icons.add_circle_outline_rounded,
        'color': const Color(0xFF0070F3),
        'onTap': () => context.push('/wallet/fund'),
      },
      {
        'title': 'Buy Data',
        'sub': 'Instant SME & Gifting',
        'icon': Icons.wifi_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => context.push('/services/data'),
      },
      {
        'title': 'Buy Airtime',
        'sub': 'Up to 5% Discount',
        'icon': Icons.phone_android_rounded,
        'color': const Color(0xFF00A3FF),
        'onTap': () => context.push('/services/airtime'),
      },
      {
        'title': 'Electricity Bill',
        'sub': 'Instant Meter Tokens',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.push('/services/electricity'),
      },
    ];

    final columns = isDesktop ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isDesktop ? 2.0 : 1.5,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a['icon'] as IconData, color: col, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a['sub'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
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
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No transactions recorded yet.',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                ),
              ),
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
                final amountColor = isCredit ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A));
                final dateFormat = DateFormat('MMM d, h:mm a');

                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCredit
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : const Color(0xFF0070F3).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      size: 16,
                      color: isCredit ? const Color(0xFF10B981) : AppColors.primaryBlue,
                    ),
                  ),
                  title: Text(
                    tx.narration ?? 'VTU Transaction',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Ref: ${tx.reference} • ${dateFormat.format(tx.createdAt)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amountPrefix${NumberFormat("#,##0.00").format(tx.amount)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: amountColor,
                        ),
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
