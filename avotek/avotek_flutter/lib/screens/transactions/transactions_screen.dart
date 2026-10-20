import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../core/utils/text_file_download.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/vtu_api_service.dart';
import '../../models/transaction_model.dart';
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
  String _activeFilter =
      'all'; // 'all', 'today', 'success', 'failed', 'pending'
  final Set<String> _requeryingReferences = {};

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

  Future<void> _requeryTransaction(TransactionModel transaction) async {
    if (_requeryingReferences.contains(transaction.reference)) return;
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    setState(() => _requeryingReferences.add(transaction.reference));
    try {
      final response = await VtuApiService.instance.requeryTransaction(
        transaction.reference,
      );
      if (!mounted) return;
      await wallet.fetchTransactions(userId);
      await wallet.fetchWallet(userId);
      await auth.refreshWallet();
      final status = (response['status'] ?? '').toString().toLowerCase();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'completed' || status == 'successful'
                ? 'Provider confirmed the transaction.'
                : status == 'failed'
                ? 'Provider confirmed the transaction failed; the wallet refund was processed.'
                : 'The provider is still processing this transaction.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not recheck transaction: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _requeryingReferences.remove(transaction.reference));
      }
    }
  }

  void _showAuditModal(List<TransactionModel> transactions) {
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
            Text(
              'Account Statement & Audit',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export the transactions currently loaded in your account history '
              'as a CSV file for reconciliation.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  'Download CSV Statement',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final csv = _statementCsv(transactions);
                  Navigator.pop(ctx);
                  final downloaded = await downloadTextFile(
                    'avotek-statement-${DateTime.now().millisecondsSinceEpoch}.csv',
                    csv,
                  );
                  if (!downloaded) {
                    await Clipboard.setData(ClipboardData(text: csv));
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        downloaded
                            ? 'Statement downloaded.'
                            : 'Statement copied to clipboard; paste it into a file to save.',
                      ),
                      backgroundColor: downloaded
                          ? AppColors.success
                          : AppColors.primaryBlue,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _statementCsv(List<TransactionModel> transactions) {
    String escape(String value) => '"${value.replaceAll('"', '""')}"';

    final rows = <List<String>>[
      [
        'Date',
        'Reference',
        'Type',
        'Category',
        'Amount (NGN)',
        'Status',
        'Narration',
      ],
      ...transactions.map(
        (tx) => [
          tx.createdAt.toIso8601String(),
          tx.reference,
          tx.type,
          tx.category,
          tx.amount.toStringAsFixed(2),
          tx.status,
          tx.narration ?? '',
        ],
      ),
    ];
    return rows.map((row) => row.map(escape).join(',')).join('\r\n');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final wallet = context.watch<WalletProvider>();

    final allTxs = wallet.transactions;
    final now = DateTime.now();

    final todayTxs = allTxs
        .where(
          (t) =>
              t.createdAt.year == now.year &&
              t.createdAt.month == now.month &&
              t.createdAt.day == now.day,
        )
        .toList();
    final successTxs = allTxs
        .where((t) => t.status == 'completed' || t.status == 'successful')
        .toList();
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
          return tx.createdAt.year == now.year &&
              tx.createdAt.month == now.month &&
              tx.createdAt.day == now.day;
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
        backgroundColor: isDark
            ? const Color(0xFF0A0D14)
            : const Color(0xFFF8FAFC),
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
                      onTap: () => setState(
                        () => _activeFilter = _activeFilter == 'today'
                            ? 'all'
                            : 'today',
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      label: '${successTxs.length} Success',
                      isActive: _activeFilter == 'success',
                      accentColor: AppColors.success,
                      onTap: () => setState(
                        () => _activeFilter = _activeFilter == 'success'
                            ? 'all'
                            : 'success',
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      label: '${failedTxs.length} Failed',
                      isActive: _activeFilter == 'failed',
                      accentColor: AppColors.error,
                      onTap: () => setState(
                        () => _activeFilter = _activeFilter == 'failed'
                            ? 'all'
                            : 'failed',
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      label: '${pendingTxs.length} Pending',
                      isActive: _activeFilter == 'pending',
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () => setState(
                        () => _activeFilter = _activeFilter == 'pending'
                            ? 'all'
                            : 'pending',
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 14),

                    // Audit Button
                    InkWell(
                      onTap: () => _showAuditModal(allTxs),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D2FF), Color(0xFF0052FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.analytics_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
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
                    color: isDark
                        ? const Color(0xFF23304B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.electricCyan,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: isDark
                                ? AppColors.metallicLight
                                : AppColors.slateGrey,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppColors.electricCyan,
                      ),
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
                    color: isDark
                        ? const Color(0xFF202A3E)
                        : const Color(0xFFE2E8F0),
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
                                color: (isDark
                                    ? const Color(0xFF1C2436)
                                    : const Color(0xFFF1F5F9)),
                                border: Border.all(
                                  color: (isDark
                                      ? const Color(0xFF2C3954)
                                      : const Color(0xFFCBD5E1)),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 36,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No transactions found',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "You haven't made any transactions yet",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.metallicLight
                                    : AppColors.slateGrey,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/services'),
                              icon: const Icon(Icons.explore_rounded, size: 16),
                              label: Text(
                                'Explore Services',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                          color: isDark
                              ? const Color(0xFF1C2436)
                              : const Color(0xFFF1F5F9),
                          height: 20,
                        ),
                        itemBuilder: (context, idx) {
                          final tx = filteredTxs[idx];
                          final isCredit = tx.isCredit;
                          return InkWell(
                            onTap: () => _showReceiptModal(tx, isDark),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          (isCredit
                                                  ? AppColors.success
                                                  : AppColors.primaryBlue)
                                              .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            (isCredit
                                                    ? AppColors.success
                                                    : AppColors.electricCyan)
                                                .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Icon(
                                      isCredit
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: isCredit
                                          ? AppColors.success
                                          : AppColors.electricCyan,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.narration ??
                                              tx.category.toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${DateFormat('dd MMM yyyy • hh:mm a').format(tx.createdAt)} • Ref: ${tx.reference}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            color: isDark
                                                ? AppColors.metallicLight
                                                : AppColors.slateGrey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (tx.status == 'pending' &&
                                      tx.isDebit &&
                                      tx.category != 'wallet_fund')
                                    IconButton(
                                      tooltip: 'Recheck provider status',
                                      onPressed: _requeryingReferences
                                              .contains(tx.reference)
                                          ? null
                                          : () => _requeryTransaction(tx),
                                      icon: _requeryingReferences
                                              .contains(tx.reference)
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.refresh_rounded,
                                              size: 19,
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
                                          color: isCredit
                                              ? AppColors.success
                                              : (isDark
                                                    ? Colors.white
                                                    : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              tx.status == 'completed' ||
                                                  tx.status == 'successful'
                                              ? AppColors.success.withValues(
                                                  alpha: 0.15,
                                                )
                                              : (tx.status == 'failed'
                                                    ? AppColors.error
                                                          .withValues(
                                                            alpha: 0.15,
                                                          )
                                                    : Colors.orange.withValues(
                                                        alpha: 0.15,
                                                      )),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          tx.status.toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                tx.status == 'completed' ||
                                                    tx.status == 'successful'
                                                ? AppColors.success
                                                : (tx.status == 'failed'
                                                      ? AppColors.error
                                                      : Colors.orange),
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
            color: isActive
                ? effectiveColor
                : (isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive
                ? (isDark ? Colors.white : effectiveColor)
                : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
          ),
        ),
      ),
    );
  }

  void _showReceiptModal(TransactionModel tx, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_rounded, color: AppColors.electricCyan),
            const SizedBox(width: 8),
            Text(
              'Transaction Receipt',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _receiptRow('Reference', tx.reference, isDark),
            _receiptRow(
              'Category',
              tx.category.toString().toUpperCase(),
              isDark,
            ),
            _receiptRow('Amount', '₦${tx.amount.toStringAsFixed(2)}', isDark),
            _receiptRow('Status', tx.status.toString().toUpperCase(), isDark),
            _receiptRow(
              'Date',
              DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt),
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: tx.reference));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reference copied to clipboard!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(
              'Copy Ref',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveReceiptPdf(tx);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: Text(
              'Save PDF',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Done',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReceiptPdf(TransactionModel tx) async {
    try {
      final logoData = await rootBundle.load(
        'assets/images/logo_large_light.png',
      );
      final logo = pw.MemoryImage(logoData.buffer.asUint8List());
      final document = pw.Document();
      final blue = PdfColor.fromInt(0xFF0052FF);
      final slate = PdfColor.fromInt(0xFF64748B);

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(42),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(
                    logo,
                    width: 132,
                    height: 48,
                    fit: pw.BoxFit.contain,
                  ),
                  pw.Spacer(),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFEAF0FF),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'TRANSACTION RECEIPT',
                      style: pw.TextStyle(
                        color: blue,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF5F8FF),
                  borderRadius: pw.BorderRadius.circular(14),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFDCE6FF)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NGN ${tx.amount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: blue,
                        fontSize: 25,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Status: ${tx.status.toUpperCase()}',
                      style: pw.TextStyle(
                        color: slate,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 26),
              _pdfReceiptRow('Reference', tx.reference, blue, slate),
              _pdfReceiptRow(
                'Transaction type',
                tx.type.toUpperCase(),
                blue,
                slate,
              ),
              _pdfReceiptRow('Service', tx.category.toUpperCase(), blue, slate),
              _pdfReceiptRow(
                'Date',
                DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt),
                blue,
                slate,
              ),
              if (tx.narration?.isNotEmpty ?? false)
                _pdfReceiptRow('Details', tx.narration!, blue, slate),
              pw.Spacer(),
              pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0)),
              pw.SizedBox(height: 8),
              pw.Text(
                'Avotek transaction receipt. Keep this document for your records. '
                'A successful payment is confirmed by Avotek after server-side verification.',
                style: pw.TextStyle(color: slate, fontSize: 9),
              ),
            ],
          ),
        ),
      );

      final safeReference = tx.reference.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'avotek-receipt-$safeReference.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF receipt is ready to save or share.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create the PDF receipt: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  pw.Widget _pdfReceiptRow(
    String label,
    String value,
    PdfColor blue,
    PdfColor slate,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(color: slate, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: blue,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
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
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
