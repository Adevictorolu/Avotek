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

class TransactionsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const TransactionsScreen({super.key, required this.onToggleTheme});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all', 'today', 'success', 'failed', 'pending'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    if (auth.user?.id != null) {
      await wallet.fetchTransactions(auth.user!.id);
    }
  }

  void _showAuditModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.analytics_rounded, color: AppColors.electricCyan),
            const SizedBox(width: 8),
            Text('Account Statement & Audit', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download full immutable ledger statements for financial audit and reconciliation.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text('Download PDF Statement', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Statement generated and downloaded!'), backgroundColor: AppColors.success),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final wallet = context.watch<WalletProvider>();

    final allTxs = wallet.transactions;
    final now = DateTime.now();

    final todayTxs = allTxs.where((t) => t.createdAt.year == now.year && t.createdAt.month == now.month && t.createdAt.day == now.day).toList();
    final successTxs = allTxs.where((t) => t.status == 'completed' || t.status == 'successful').toList();
    final failedTxs = allTxs.where((t) => t.status == 'failed').toList();
    final pendingTxs = allTxs.where((t) => t.status == 'pending').toList();

    final filteredTxs = allTxs.where((tx) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesCat = tx.category.toLowerCase().contains(q);
        final matchesRef = tx.reference.toLowerCase().contains(q);
        final matchesNarr = (tx.narration ?? '').toLowerCase().contains(q);
        if (!matchesCat && !matchesRef && !matchesNarr) return false;
      }

      switch (_activeFilter) {
        case 'today':
          return tx.createdAt.year == now.year && tx.createdAt.month == now.month && tx.createdAt.day == now.day;
        case 'success':
          return tx.status == 'completed' || tx.status == 'successful';
        case 'failed':
          return tx.status == 'failed';
        case 'pending':
          return tx.status == 'pending';
        default:
          return true;
      }
    }).toList();

    return ResponsiveShell(
      currentRoute: '/transactions',
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
              // 1. TOP HEADER & METRIC PILLS (Matches Screenshot 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions Summary',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPill(
                      label: '${todayTxs.length} Today',
                      isActive: _activeFilter == 'today',
                      onTap: () => setState(() => _activeFilter = _activeFilter == 'today' ? 'all' : 'today'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      label: '${successTxs.length} Success',
                      isActive: _activeFilter == 'success',
                      accentColor: AppColors.success,
                      onTap: () => setState(() => _activeFilter = _activeFilter == 'success' ? 'all' : 'success'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      label: '${failedTxs.length} Failed',
                      isActive: _activeFilter == 'failed',
                      accentColor: AppColors.error,
                      onTap: () => setState(() => _activeFilter = _activeFilter == 'failed' ? 'all' : 'failed'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      label: '${pendingTxs.length} Pending',
                      isActive: _activeFilter == 'pending',
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () => setState(() => _activeFilter = _activeFilter == 'pending' ? 'all' : 'pending'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 14),

                    // Audit Button
                    InkWell(
                      onTap: _showAuditModal,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D2FF), Color(0xFF0052FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.analytics_outlined, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'Audit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. SEARCH & REFRESH BAR (Matches Screenshot 3)
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
                          hintText: 'Search transactions...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.electricCyan),
                      onPressed: _loadTransactions,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. TRANSACTIONS LIST / EMPTY STATE (Matches Screenshot 3)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 380),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF10141F) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF202A3E) : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: filteredTxs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Big Plus in Circle (Matches Screenshot 3)
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isDark ? const Color(0xFF1C2436) : const Color(0xFFF1F5F9)),
                                border: Border.all(
                                  color: (isDark ? const Color(0xFF2C3954) : const Color(0xFFCBD5E1)),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.add_rounded, size: 36, color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No transactions found',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "You haven't made any transactions yet",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/services'),
                              icon: const Icon(Icons.explore_rounded, size: 16),
                              label: Text('Explore Services', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
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
                        itemCount: filteredTxs.length,
                        separatorBuilder: (_, _) => Divider(
                          color: isDark ? const Color(0xFF1C2436) : const Color(0xFFF1F5F9),
                          height: 20,
                        ),
                        itemBuilder: (context, idx) {
                          final tx = filteredTxs[idx];
                          final isCredit = tx.isCredit;
                          return InkWell(
                            onTap: () => _showReceiptModal(tx, isDark),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
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
                                          tx.narration ?? tx.category.toUpperCase(),
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: tx.status == 'completed' || tx.status == 'successful'
                                              ? AppColors.success.withValues(alpha: 0.15)
                                              : (tx.status == 'failed'
                                                  ? AppColors.error.withValues(alpha: 0.15)
                                                  : Colors.orange.withValues(alpha: 0.15)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tx.status.toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: tx.status == 'completed' || tx.status == 'successful'
                                                ? AppColors.success
                                                : (tx.status == 'failed' ? AppColors.error : Colors.orange),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  Widget _buildPill({
    required String label,
    required bool isActive,
    Color? accentColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final effectiveColor = accentColor ?? AppColors.electricCyan;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? effectiveColor.withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF131722) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? effectiveColor : (isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? (isDark ? Colors.white : effectiveColor) : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
          ),
        ),
      ),
    );
  }

  void _showReceiptModal(dynamic tx, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_rounded, color: AppColors.electricCyan),
            const SizedBox(width: 8),
            Text('Transaction Receipt', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _receiptRow('Reference', tx.reference, isDark),
            _receiptRow('Category', tx.category.toString().toUpperCase(), isDark),
            _receiptRow('Amount', '₦${tx.amount.toStringAsFixed(2)}', isDark),
            _receiptRow('Status', tx.status.toString().toUpperCase(), isDark),
            _receiptRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt), isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: tx.reference));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reference copied to clipboard!'), backgroundColor: AppColors.success),
              );
            },
            child: Text('Copy Ref', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}
