import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/transaction_model.dart';

class TransactionAuditDialog extends StatefulWidget {
  final List<TransactionModel> transactions;

  const TransactionAuditDialog({super.key, required this.transactions});

  static Future<void> show(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TransactionAuditDialog(transactions: transactions),
    );
  }

  @override
  State<TransactionAuditDialog> createState() => _TransactionAuditDialogState();
}

class _TransactionAuditDialogState extends State<TransactionAuditDialog> {
  // Filter options: 'Today', 'Week', 'Month', 'Year', 'All Time'
  String _selectedFilter = 'Week';

  List<TransactionModel> get _filteredTransactions {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        final startOfToday = DateTime(now.year, now.month, now.day);
        return widget.transactions
            .where((tx) => tx.createdAt.isAfter(startOfToday))
            .toList();
      case 'Week':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return widget.transactions
            .where((tx) => tx.createdAt.isAfter(sevenDaysAgo))
            .toList();
      case 'Month':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return widget.transactions
            .where((tx) => tx.createdAt.isAfter(thirtyDaysAgo))
            .toList();
      case 'Year':
        final yearAgo = now.subtract(const Duration(days: 365));
        return widget.transactions
            .where((tx) => tx.createdAt.isAfter(yearAgo))
            .toList();
      case 'All Time':
      default:
        return widget.transactions;
    }
  }

  String get _dateRangeText {
    final now = DateTime.now();
    final fmt = DateFormat('MMM d, yyyy');
    switch (_selectedFilter) {
      case 'Today':
        return fmt.format(now);
      case 'Week':
        final start = now.subtract(const Duration(days: 7));
        return '${fmt.format(start)} - ${fmt.format(now)}';
      case 'Month':
        final start = now.subtract(const Duration(days: 30));
        return '${fmt.format(start)} - ${fmt.format(now)}';
      case 'Year':
        final start = now.subtract(const Duration(days: 365));
        return '${fmt.format(start)} - ${fmt.format(now)}';
      case 'All Time':
      default:
        if (widget.transactions.isEmpty) return 'All Recorded History';
        final sorted = [...widget.transactions]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return '${fmt.format(sorted.first.createdAt)} - ${fmt.format(now)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txs = _filteredTransactions;

    final totalCount = txs.length;
    final successfulCount = txs.where((t) => t.isCompleted).length;
    final failedCount = txs.where((t) => t.isFailed).length;
    final pendingCount = txs.where((t) => t.isPending).length;

    final successRate = totalCount == 0
        ? 100.0
        : (successfulCount / totalCount * 100);

    // Financial summary: total debits completed
    final completedDebits =
        txs.where((t) => t.isDebit && t.isCompleted).toList();
    final totalSpent = completedDebits.fold<double>(
      0.0,
      (acc, t) => acc + t.amount,
    );
    final averageTx = completedDebits.isEmpty
        ? 0.0
        : totalSpent / completedDebits.length;

    // Most used service calculation
    final serviceCounts = <String, int>{};
    final serviceAmounts = <String, double>{};
    for (final t in txs) {
      final name = t.category.isNotEmpty
          ? t.category.replaceAll('_', ' ').toUpperCase()
          : 'GENERAL';
      serviceCounts[name] = (serviceCounts[name] ?? 0) + 1;
      serviceAmounts[name] = (serviceAmounts[name] ?? 0.0) + t.amount;
    }
    String topService = 'VTU & Bill Payments';
    int topServiceCount = 0;
    double topServiceAmount = 0.0;
    if (serviceCounts.isNotEmpty) {
      final sortedKeys = serviceCounts.keys.toList()
        ..sort((a, b) => serviceCounts[b]!.compareTo(serviceCounts[a]!));
      topService = sortedKeys.first;
      topServiceCount = serviceCounts[topService] ?? 0;
      topServiceAmount = serviceAmounts[topService] ?? 0.0;
    }
    final topServicePercent =
        totalCount == 0 ? 1.0 : (topServiceCount / totalCount);

    // Recent activity: generate last 7 days for the selected timeframe
    final recentDays = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayTxs = txs.where((t) {
        return t.createdAt.year == date.year &&
            t.createdAt.month == date.month &&
            t.createdAt.day == date.day;
      }).toList();
      final daySpent = dayTxs
          .where((t) => t.isDebit && t.isCompleted)
          .fold<double>(0.0, (acc, t) => acc + t.amount);
      return (
        date: date,
        dayName: DateFormat('EEEE').format(date),
        dateStr: DateFormat('MMM d, yyyy').format(date),
        count: dayTxs.length,
        spent: daySpent,
      );
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F131D) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF26324D)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.6 : 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- 1. MODAL HEADER ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 16, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0052FF)
                                    .withOpacity(0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.bar_chart_rounded,
                                color: Color(0xFF0052FF),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Transaction Audit',
                              style: GoogleFonts.figtree(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF1E2638)
                                : const Color(0xFFF1F5F9),
                            foregroundColor: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: isDark
                        ? const Color(0xFF1E2638)
                        : const Color(0xFFF1F5F9),
                    height: 1,
                  ),

                  // --- 2. SCROLLABLE AUDIT CONTENT ---
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- FILTER TABS (Today, Week, Month, Year, All Time) ---
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF141926)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF222C42)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                'Today',
                                'Week',
                                'Month',
                                'Year',
                                'All Time'
                              ].map((f) {
                                final isSelected = _selectedFilter == f;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedFilter = f),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF0047FF),
                                                  Color(0xFF0038B8)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF0038B8)
                                                      .withOpacity(0.35),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          f,
                                          style: GoogleFonts.figtree(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF64748B)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // --- DATE RANGE PILL ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF141926)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF222C42)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 15,
                                  color: isDark
                                      ? AppColors.electricCyan
                                      : const Color(0xFF0052FF),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _dateRangeText,
                                  style: GoogleFonts.figtree(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // --- 3. OVERVIEW SECTION ---
                          Text(
                            'Overview',
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildMetricTile(
                                label: 'TOTAL\nTRANSACTIONS',
                                value: totalCount.toString(),
                                valueColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _buildMetricTile(
                                label: 'SUCCESS\nRATE',
                                value:
                                    '${successRate.toStringAsFixed(1)}%',
                                valueColor: const Color(0xFF10B981),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _buildMetricTile(
                                label: 'SUCCESSFUL',
                                value: successfulCount.toString(),
                                valueColor: const Color(0xFF10B981),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _buildMetricTile(
                                label: 'FAILED',
                                value: failedCount.toString(),
                                valueColor: const Color(0xFFEF4444),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _buildMetricTile(
                                label: 'PENDING',
                                value: pendingCount.toString(),
                                valueColor: const Color(0xFFF59E0B),
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // --- 4. FINANCIAL SUMMARY (Avotek Blue Gradient - NO ORANGE) ---
                          Text(
                            'Financial Summary',
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0047FF),
                                        Color(0xFF0038B8)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0038B8)
                                            .withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Spent',
                                        style: GoogleFonts.figtree(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₦${NumberFormat('#,##0.00').format(totalSpent)}',
                                        style: GoogleFonts.figtree(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0052FF),
                                        Color(0xFF002B9E)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF002B9E)
                                            .withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Average Transaction',
                                        style: GoogleFonts.figtree(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₦${NumberFormat('#,##0.00').format(averageTx)}',
                                        style: GoogleFonts.figtree(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // --- 5. MOST USED SERVICE ---
                          Text(
                            'Most Used Service',
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF141926)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF222C42)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      topService,
                                      style: GoogleFonts.figtree(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      '$topServiceCount txns • ₦${NumberFormat('#,##0.00').format(topServiceAmount)}',
                                      style: GoogleFonts.figtree(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.electricCyan
                                            : const Color(0xFF0052FF),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: topServicePercent.clamp(0.05, 1.0),
                                    minHeight: 7,
                                    backgroundColor: isDark
                                        ? const Color(0xFF222C42)
                                        : const Color(0xFFE2E8F0),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0052FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // --- 6. RECENT ACTIVITY ---
                          Text(
                            'Recent Activity',
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: recentDays.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF141926)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF222C42)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.dayName,
                                          style: GoogleFonts.figtree(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.dateStr,
                                          style: GoogleFonts.figtree(
                                            fontSize: 11,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${item.count} transactions',
                                          style: GoogleFonts.figtree(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₦${NumberFormat('#,##0.00').format(item.spent)}',
                                          style: GoogleFonts.figtree(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: item.spent > 0
                                                ? const Color(0xFF10B981)
                                                : (isDark
                                                    ? const Color(0xFF64748B)
                                                    : const Color(0xFF94A3B8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141926) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF222C42) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.figtree(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.figtree(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
