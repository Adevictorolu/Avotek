import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const WalletScreen({super.key, required this.onToggleTheme});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedTab = 0; // 0 = Transaction Summary, 1 = Funding History
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    if (auth.user?.id != null) {
      await auth.refreshWallet();
      await wallet.fetchWallet(auth.user!.id);
      await wallet.fetchTransactions(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final wallet = context.watch<WalletProvider>();

    final allTxs = wallet.transactions;
    final fundingTxs = allTxs.where((t) => t.isCredit).toList();

    final currentList = (_selectedTab == 0 ? allTxs : fundingTxs).where((tx) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final cat = tx.category.toLowerCase();
      final ref = tx.reference.toLowerCase();
      final narr = (tx.narration ?? '').toLowerCase();
      return cat.contains(q) || ref.contains(q) || narr.contains(q);
    }).toList();

    return ResponsiveShell(
      currentRoute: '/wallet',
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Title & Refresh Button (Matches Screenshot 2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wallet Summary',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                    label: Text(
                      'Refresh Wallet',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tabs Row: Transaction Summary | Funding History
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131722) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF23304B) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabButton(
                          title: 'Transaction Summary',
                          icon: Icons.swap_vert_rounded,
                          isSelected: _selectedTab == 0,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        const SizedBox(width: 4),
                        _buildTabButton(
                          title: 'Funding History',
                          icon: Icons.account_balance_wallet_rounded,
                          isSelected: _selectedTab == 1,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Fund Wallet CTA
                  ElevatedButton.icon(
                    onPressed: () => context.push('/wallet/fund'),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      'Fund Wallet',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricCyan,
                      foregroundColor: const Color(0xFF0A0D14),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar: "Search by description, reference, or amount"
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131722) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Icon(Icons.search_rounded, color: AppColors.electricCyan, size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by description, reference, or amount',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content Area: Empty State or Transactions List (Matches Screenshot 2)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 400),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF10141F) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF202A3E) : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: currentList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Large Plus in Circle (Matches Screenshot 2)
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF1C2436) : const Color(0xFFF1F5F9),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2C3954) : const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.add_rounded, size: 36, color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No wallet transactions yet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Fund your wallet to see transactions here',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/wallet/fund'),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                              label: Text(
                                'Fund Wallet Now',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentList.length,
                        separatorBuilder: (_, _) => Divider(
                          color: isDark ? const Color(0xFF1C2436) : const Color(0xFFF1F5F9),
                          height: 20,
                        ),
                        itemBuilder: (context, idx) {
                          final tx = currentList[idx];
                          final isCredit = tx.isCredit;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: (isCredit ? AppColors.success : AppColors.primaryBlue).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (isCredit ? AppColors.success : AppColors.electricCyan).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: isCredit ? AppColors.success : AppColors.electricCyan,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.narration ?? (isCredit ? 'Wallet Funding' : tx.category.toUpperCase()),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${DateFormat('dd MMM yyyy • hh:mm a').format(tx.createdAt)} • Ref: ${tx.reference}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isCredit ? '+' : '-'}₦${tx.amount.toStringAsFixed(2)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: isCredit ? AppColors.success : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Bal: ₦${tx.balanceAfter.toStringAsFixed(2)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E283D) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.electricCyan
                  : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.primaryBlue)
                    : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
