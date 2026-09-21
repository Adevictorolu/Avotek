import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/quick_service_grid.dart';
import '../../widgets/transaction_tile.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const DashboardScreen({super.key, required this.onToggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user?.id != null) {
        context.read<WalletProvider>().fetchWallet(auth.user!.id!);
      }
    });
  }

  void _onServiceSelected(String serviceId) {
    if (serviceId == 'cac') {
      context.push('/services/cac');
    } else {
      context.push('/services/$serviceId');
    }
  }

  void _openFundWalletModal() {
    context.push('/wallet/fund');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = auth.user?.name ?? 'User';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: AvotekBrandAsset(height: 32, isDark: isDark),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
          if (auth.isSuperAdmin)
            IconButton(
              tooltip: 'Admin Console',
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: AppColors.primaryCyan),
              onPressed: () => context.push('/admin'),
            ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () {
              auth.signOut();
              context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.user?.id != null) {
            await wallet.fetchWallet(auth.user!.id!);
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                          ),
                        ),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BalanceCard(
                  onFundPressed: _openFundWalletModal,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Services',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Auto-Reversal Protected',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.primaryCyan : AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                QuickServiceGrid(onServiceSelected: _onServiceSelected),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        _buildFilterPill('All', 'all', wallet.selectedFilter, wallet.setFilter, isDark),
                        const SizedBox(width: 6),
                        _buildFilterPill('Debit', 'debit', wallet.selectedFilter, wallet.setFilter, isDark),
                        const SizedBox(width: 6),
                        _buildFilterPill('Fund', 'fund', wallet.selectedFilter, wallet.setFilter, isDark),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (wallet.transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No transactions yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...wallet.transactions.map((tx) => TransactionTile(transaction: tx)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentTabIndex = idx);
          if (idx == 1) context.push('/services/airtime');
          if (idx == 2) context.push('/wallet/fund');
          if (idx == 3) context.push('/community');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Fund Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Community',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
    String label,
    String value,
    String currentValue,
    void Function(String) onSelect,
    bool isDark,
  ) {
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryCyan : AppColors.primaryBlue)
              : (isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? (isDark ? const Color(0xFF002B47) : Colors.white)
                : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
          ),
        ),
      ),
    );
  }
}
