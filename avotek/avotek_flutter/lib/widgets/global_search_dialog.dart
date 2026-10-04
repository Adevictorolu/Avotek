import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => const GlobalSearchDialog(),
    );
  }

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  static const List<Map<String, dynamic>> _vtuServices = [
    {
      'title': 'Buy Data Bundle',
      'category': 'Telecom',
      'desc': 'MTN, Airtel, Glo, 9mobile SME, Corporate & Gifting data',
      'route': '/services/data',
      'icon': Icons.wifi_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Buy Airtime',
      'category': 'Telecom',
      'desc': 'Instant VTU airtime recharge with up to 5% discount',
      'route': '/services/airtime',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF00A3FF),
    },
    {
      'title': 'Electricity Bill Payment',
      'category': 'Utility',
      'desc': 'Prepaid meter token & postpaid bill across all DISCOs (IKEDC, EKEDC, etc.)',
      'route': '/services/electricity',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Cable TV Subscription',
      'category': 'Entertainment',
      'desc': 'Instant renewal for DStv, GOtv, and StarTimes packages',
      'route': '/services/tv',
      'icon': Icons.tv_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'Betting Wallet Top-up',
      'category': 'Gaming',
      'desc': 'Fund SportyBet, Bet9ja, 1xBet, BangBet instantly',
      'route': '/services/betting',
      'icon': Icons.sports_soccer_rounded,
      'color': Color(0xFF06B6D4),
    },
    {
      'title': 'Fund Wallet',
      'category': 'Finance',
      'desc': 'Automated dedicated virtual bank account & instant card funding',
      'route': '/wallet/fund',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF0070F3),
    },
    {
      'title': 'Transaction History & Receipts',
      'category': 'History',
      'desc': 'View payment logs, download invoices, track real-time delivery',
      'route': '/transactions',
      'icon': Icons.receipt_long_rounded,
      'color': Color(0xFF64748B),
    },
    {
      'title': 'Check Live Rates & Pricing',
      'category': 'Pricing',
      'desc': 'Compare telecom SME data rates, discounts, and network availability',
      'route': '/rates',
      'icon': Icons.price_check_rounded,
      'color': Color(0xFF14B8A6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredServices = _vtuServices.where((s) {
      if (_query.isEmpty) return true;
      final title = (s['title'] as String).toLowerCase();
      final desc = (s['desc'] as String).toLowerCase();
      final cat = (s['category'] as String).toLowerCase();
      return title.contains(_query) || desc.contains(_query) || cat.contains(_query);
    }).toList();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0B132B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 540),
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search data, airtime, electricity, cable, betting...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1C2541) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),

            // Search Results List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Text(
                      _query.isEmpty ? 'QUICK SERVICES' : 'MATCHING SERVICES',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (filteredServices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No services found matching "$_query"',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredServices.map((s) {
                      final col = s['color'] as Color;
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: col.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s['icon'] as IconData, color: col, size: 20),
                        ),
                        title: Text(
                          s['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          s['desc'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context);
                          context.push(s['route'] as String);
                        },
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
