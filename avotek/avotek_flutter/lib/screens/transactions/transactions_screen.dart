import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/avotek_logo.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'all'; // 'all', 'delivered', 'processing', 'refunded', 'failed'

  final List<Map<String, dynamic>> _demoTransactions = [
    {
      'id': 'AV-8841207',
      'service': 'MTN 10GB SME',
      'type': 'data',
      'recipient': '0803 411 9920',
      'amount': 3400.0,
      'isCredit': false,
      'status': 'delivered',
      'time': '12:41',
      'date': 'Today',
      'network': 'MTN',
    },
    {
      'id': 'AV-8841198',
      'service': 'Ikeja Electric Prepaid',
      'type': 'electricity',
      'recipient': 'Token: 4819-2049-1829-4019',
      'amount': 5000.0,
      'isCredit': false,
      'status': 'delivered',
      'time': '12:18',
      'date': 'Today',
      'network': 'IKEDC',
    },
    {
      'id': 'AV-8841150',
      'service': 'Dedicated NUBAN Funding',
      'type': 'wallet',
      'recipient': 'Wema Bank Transfer',
      'amount': 100000.0,
      'isCredit': true,
      'status': 'delivered',
      'time': '11:52',
      'date': 'Today',
      'network': 'Wema Bank',
    },
    {
      'id': 'AV-8841102',
      'service': 'DStv Compact Renewal',
      'type': 'cable',
      'recipient': 'Smartcard: 7024118836',
      'amount': 19000.0,
      'isCredit': false,
      'status': 'processing',
      'time': '11:30',
      'date': 'Today',
      'network': 'DStv',
    },
    {
      'id': 'AV-8841044',
      'service': 'Airtel Airtime Recharge',
      'type': 'airtime',
      'recipient': '0908 877 6655',
      'amount': 2000.0,
      'isCredit': false,
      'status': 'delivered',
      'time': '10:57',
      'date': 'Today',
      'network': 'Airtel',
    },
    {
      'id': 'AV-8840987',
      'service': 'WAEC Result Checker PIN (x2)',
      'type': 'exam_pin',
      'recipient': 'Quantity: 2 PINs',
      'amount': 7000.0,
      'isCredit': false,
      'status': 'refunded',
      'time': '10:12',
      'date': 'Today',
      'network': 'WAEC',
    },
    {
      'id': 'AV-8840810',
      'service': 'Glo 5GB Corporate Data',
      'type': 'data',
      'recipient': '0805 123 4567',
      'amount': 1400.0,
      'isCredit': false,
      'status': 'delivered',
      'time': '09:20',
      'date': 'Yesterday',
      'network': 'Glo',
    },
    {
      'id': 'AV-8840742',
      'service': '9mobile 2GB Data',
      'type': 'data',
      'recipient': '0809 999 1122',
      'amount': 600.0,
      'isCredit': false,
      'status': 'failed',
      'time': '08:45',
      'date': 'Yesterday',
      'network': '9mobile',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    final filteredList = _demoTransactions.where((tx) {
      final matchesSearch = tx['service'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx['recipient'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == 'all' || tx['status'] == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        titleSpacing: isDesktop ? 48 : 16,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        title: const AvotekLogo(size: 32, showText: true),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/dashboard'),
            icon: const Icon(Icons.dashboard_rounded, size: 16),
            label: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Fund Wallet',
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
            onPressed: () => context.push('/wallet/fund'),
          ),
          SizedBox(width: isDesktop ? 48 : 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb & Page Header
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.push('/dashboard'),
                        child: Text('Dashboard', style: TextStyle(fontSize: 12, color: AppColors.primaryCyan)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('Transactions', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Transaction history',
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Every order you have placed, with its reference and status kept permanently.',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                  ),
                  const SizedBox(height: 24),

                  // 3-Metric Summary Strip
                  _buildMetricsStrip(isDesktop, isDark),
                  const SizedBox(height: 28),

                  // Transaction Card Table
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Head
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('All transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Transactions exported to CSV successfully!')),
                                  );
                                },
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text('Export CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        // Search & Filter Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search by service, reference or recipient number...',
                                  prefixIcon: const Icon(Icons.search, size: 18),
                                  filled: true,
                                  fillColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onChanged: (val) => setState(() => _searchQuery = val),
                              ),
                              const SizedBox(height: 14),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _statusChip('all', 'All', isDark),
                                    _statusChip('delivered', 'Delivered', isDark),
                                    _statusChip('processing', 'Processing', isDark),
                                    _statusChip('refunded', 'Refunded', isDark),
                                    _statusChip('failed', 'Failed', isDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),

                        // Table Headers
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
                          child: const Row(
                            children: [
                              Expanded(flex: 5, child: Text('SERVICE & RECIPIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                              Expanded(flex: 3, child: Text('REFERENCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                              Expanded(flex: 3, child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                              Expanded(flex: 3, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                              Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('WHEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))),
                            ],
                          ),
                        ),

                        // Table Rows
                        if (filteredList.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(48),
                            alignment: Alignment.center,
                            child: const Text('No transactions match your search or filter.', style: TextStyle(color: Colors.grey)),
                          )
                        else
                          ...filteredList.map((tx) => _buildTransactionRow(tx, isDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsStrip(bool isDesktop, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final items = [
          _metricCard('Spent this month', '₦486,200.00', Icons.credit_card_rounded, AppColors.primaryCyan, isDark),
          _metricCard('Orders placed', '1,204', Icons.receipt_long_rounded, AppColors.success, isDark),
          _metricCard('Refunded back to you', '₦12,400.00', Icons.sync_rounded, AppColors.warning, isDark),
        ];

        return isNarrow
            ? Column(children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)).toList())
            : Row(children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: w))).toList());
      },
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, String label, bool isDark) {
    final isSel = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSel ? Colors.black : (isDark ? Colors.white : Colors.black))),
        selected: isSel,
        selectedColor: AppColors.primaryCyan,
        backgroundColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
        onSelected: (_) => setState(() => _selectedStatus = status),
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> tx, bool isDark) {
    Color iconColor;
    IconData icon;
    switch (tx['type']) {
      case 'data':
        iconColor = AppColors.success;
        icon = Icons.wifi;
        break;
      case 'airtime':
        iconColor = AppColors.primaryCyan;
        icon = Icons.phone_android;
        break;
      case 'electricity':
        iconColor = AppColors.warning;
        icon = Icons.bolt;
        break;
      case 'cable':
        iconColor = Colors.pink;
        icon = Icons.tv;
        break;
      case 'exam_pin':
        iconColor = Colors.cyan;
        icon = Icons.school;
        break;
      default:
        iconColor = Colors.teal;
        icon = Icons.account_balance_wallet;
    }

    final isCredit = tx['isCredit'] as bool;
    final amountFormatted = '${isCredit ? '+' : '-'}₦${NumberFormat('#,##0.00').format(tx['amount'])}';

    return InkWell(
      onTap: () => _showReceiptModal(tx, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Row(
          children: [
            // Service & Recipient
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: iconColor.withValues(alpha: 0.15),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx['service'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(tx['recipient'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Reference
            Expanded(
              flex: 3,
              child: Text(tx['id'] as String, style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey, fontFamily: 'monospace')),
            ),
            // Amount
            Expanded(
              flex: 3,
              child: Text(
                amountFormatted,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? AppColors.success : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            // Status Pill
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _statusBadge(tx['status'] as String),
              ),
            ),
            // When
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(tx['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case 'delivered':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
        label = 'Delivered';
        break;
      case 'processing':
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        icon = Icons.access_time_filled_rounded;
        label = 'Processing';
        break;
      case 'refunded':
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        icon = Icons.replay_rounded;
        label = 'Refunded';
        break;
      default:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        icon = Icons.cancel_rounded;
        label = 'Failed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  void _showReceiptModal(Map<String, dynamic> tx, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Transaction Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                '₦${NumberFormat('#,##0.00').format(tx['amount'])}',
                style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              Text(tx['service'] as String, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              const Divider(),
              _receiptRow('Reference', tx['id'] as String, isCopyable: true),
              _receiptRow('Service', tx['service'] as String),
              _receiptRow('Recipient', tx['recipient'] as String),
              _receiptRow('Status', (tx['status'] as String).toUpperCase()),
              _receiptRow('Date & Time', '${tx['date']}, ${tx['time']}'),
              _receiptRow('Protection', 'Auto-Refund Protected'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Reference: ${tx['id']} | Amount: ₦${tx['amount']} | Service: ${tx['service']}'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt copied to clipboard!')));
            },
            child: const Text('Copy Details'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              if (isCopyable) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reference copied!')));
                  },
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primaryCyan),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
