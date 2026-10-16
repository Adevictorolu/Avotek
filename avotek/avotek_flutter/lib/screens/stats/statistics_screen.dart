import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class StatisticsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const StatisticsScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    final transactions = wallet.transactions;
    final now = DateTime.now();
    final todaySpend = transactions
        .where(
          (transaction) =>
              transaction.isDebit &&
              transaction.createdAt.year == now.year &&
              transaction.createdAt.month == now.month &&
              transaction.createdAt.day == now.day,
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final completed = transactions
        .where((transaction) => _isSuccessful(transaction.status))
        .length;
    final failed = transactions
        .where((transaction) => transaction.status == 'failed')
        .length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ResponsiveShell(
      currentRoute: '/stats',
      onToggleTheme: onToggleTheme,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0D14)
            : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          onRefresh: () async {
            if (userId == null) return;
            try {
              await context.read<WalletProvider>().fetchTransactions(userId);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not refresh transaction statistics.'),
                  ),
                );
              }
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 36 : 16,
              vertical: 24,
            ),
            children: [
              Text(
                'Statistics',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A summary of your recently loaded wallet transactions.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              if (wallet.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  wallet.errorMessage!,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (wallet.isLoading && transactions.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (transactions.isEmpty)
                _EmptyStatistics(isDark: isDark)
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 850 ? 4 : 2;
                    final metrics = [
                      _Metric(
                        label: "TODAY'S SPEND",
                        value: '₦${todaySpend.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.primaryBlue,
                      ),
                      _Metric(
                        label: 'TRANSACTIONS',
                        value: '${transactions.length}',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.electricCyan,
                      ),
                      _Metric(
                        label: 'SUCCESSFUL',
                        value: '$completed',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      _Metric(
                        label: 'FAILED',
                        value: '$failed',
                        icon: Icons.cancel_rounded,
                        color: AppColors.error,
                      ),
                    ];
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: metrics.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 116,
                      ),
                      itemBuilder: (context, index) => _MetricCard(
                        metric: metrics[index],
                        isDark: isDark,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Statistics use the latest transactions loaded for your wallet.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/transactions'),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('View transaction history'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isSuccessful(String status) =>
      status == 'completed' || status == 'successful';
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  final bool isDark;

  const _MetricCard({required this.metric, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: metric.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStatistics extends StatelessWidget {
  final bool isDark;

  const _EmptyStatistics({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Text(
        'Your transaction statistics will appear here after activity is recorded.',
        style: GoogleFonts.plusJakartaSans(
          color: isDark ? Colors.white70 : const Color(0xFF475569),
        ),
      ),
    );
  }
}
