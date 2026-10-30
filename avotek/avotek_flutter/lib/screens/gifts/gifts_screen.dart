import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';

class GiftVoucher {
  final String id;
  final String code;
  final double amount;
  final String recipient;
  final String status; // 'Active', 'Redeemed', 'Expired', 'Cancelled'
  final DateTime createdAt;

  GiftVoucher({
    required this.id,
    required this.code,
    required this.amount,
    required this.recipient,
    required this.status,
    required this.createdAt,
  });
}

class GiftsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const GiftsScreen({super.key, required this.onToggleTheme});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  String _activeFilter = 'All'; // 'All', 'Active', 'Redeemed', 'Expired'
  List<GiftVoucher> _gifts = [];
  bool _isLoadingGifts = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGifts();
      final auth = context.read<AuthProvider>();
      if (auth.user?.id != null) {
        context.read<WalletProvider>().fetchWallet(auth.user!.id);
        auth.refreshWallet();
      }
    });
  }

  Future<void> _fetchGifts() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    setState(() => _isLoadingGifts = true);
    try {
      final rows = await SupabaseService.instance.listUserGiftVouchers(userId);
      if (!mounted) return;
      setState(() {
        _gifts = rows.map((r) {
          final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
          final status = (r['status'] ?? 'active').toString();
          return GiftVoucher(
            id: r['id'].toString(),
            code: r['code'].toString(),
            amount: amt,
            recipient: (r['recipient'] ?? 'Friend').toString(),
            status: status[0].toUpperCase() + status.substring(1),
            createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ??
                DateTime.now(),
          );
        }).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingGifts = false);
    }
  }

  void _openCreateGiftModal() {
    final amountCtrl = TextEditingController(text: '1000');
    final recipientCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final authState = context.watch<AuthProvider>();
            final walletState = context.watch<WalletProvider>();
            final availableBal = walletState.balance > 0
                ? walletState.balance
                : (authState.wallet?.balance ?? 0.0);

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF141928) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create Gift Voucher',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gift voucher codes are funded directly from your Avotek wallet and can be redeemed instantly by any user.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          height: 1.45,
                          color: isDark
                              ? AppColors.metallicLight
                              : AppColors.slateGrey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Available Balance Badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Color(0xFF10B981),
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Available Wallet Balance: ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                            Text(
                              '₦${availableBal.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Amount Input
                      Text(
                        'Amount (₦)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          prefixText: '₦ ',
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1B2236)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF26334D)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Amount Pills
                      Wrap(
                        spacing: 8,
                        children: [500, 1000, 2000, 5000].map((amt) {
                          return ActionChip(
                            label: Text(
                              '₦$amt',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            backgroundColor: isDark
                                ? const Color(0xFF222C42)
                                : const Color(0xFFE2E8F0),
                            onPressed: () {
                              setDialogState(() {
                                amountCtrl.text = amt.toString();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Recipient
                      Text(
                        'Recipient Name or Phone (Optional)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: recipientCtrl,
                        style: GoogleFonts.plusJakartaSans(),
                        decoration: InputDecoration(
                          hintText: 'e.g. 08123456789 or Adewale',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1B2236)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF26334D)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Note
                      Text(
                        'Gift Note / Greeting (Optional)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteCtrl,
                        maxLines: 2,
                        style: GoogleFonts.plusJakartaSans(),
                        decoration: InputDecoration(
                          hintText: 'Happy Birthday! Enjoy your recharge.',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkCardVariant
                              : AppColors.lightCardVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (amt < 50) {
                      TopNotification.showError(
                        context,
                        'Minimum voucher amount is ₦50.',
                      );
                      return;
                    }

                    final curWallet = context.read<WalletProvider>();
                    final curAuth = context.read<AuthProvider>();
                    final curBalance = curWallet.balance > 0
                        ? curWallet.balance
                        : (curAuth.wallet?.balance ?? 0.0);

                    if (curBalance < amt) {
                      TopNotification.showError(
                        context,
                        'Insufficient wallet balance. Available: ₦${curBalance.toStringAsFixed(2)}.',
                      );
                      return;
                    }

                    Navigator.pop(ctx);

                    // Prompt PIN using Keypad
                    final auth = context.read<AuthProvider>();
                    final confirmed = await PinModal.show(
                      context,
                      title: 'Confirm Gift Creation',
                      amount: amt,
                      description: 'Debit ₦${amt.toStringAsFixed(2)} to generate voucher',
                      onPinSubmit: (pin) async => auth.verifyPin(pin),
                    );

                    if (!mounted || confirmed != true) return;

                    try {
                      final res = await SupabaseService.instance.createGiftVoucher(
                        amount: amt,
                        recipient: recipientCtrl.text.trim(),
                        note: noteCtrl.text.trim(),
                      );
                      if (!mounted) return;
                      await auth.refreshWallet();
                      if (auth.user != null) {
                        await curWallet.fetchWallet(auth.user!.id);
                      }
                      _fetchGifts();
                      final code = (res['code'] ?? 'AVOGIFT').toString();
                      _showVoucherReadyDialog(
                        code: code,
                        amount: amt,
                        recipient: recipientCtrl.text.trim(),
                        note: noteCtrl.text.trim(),
                      );
                    } catch (e) {
                      if (mounted) {
                        TopNotification.showError(
                          context,
                          'Could not create gift voucher: $e',
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create Voucher',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showVoucherReadyDialog({
    required String code,
    required double amount,
    required String recipient,
    required String note,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final claimUrl = 'https://adevictorolu.github.io/Avotek/#/coupons?code=$code';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFF10B981),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Gift Voucher Ready! 🎁',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your ₦${amount.toStringAsFixed(2)} voucher code has been issued.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // Monospace Code Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'VOUCHER CODE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        code,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Voucher Code'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          TopNotification.showSuccess(context, 'Voucher code copied!');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Share Claim Link
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131F38) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          claimUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: claimUrl));
                          TopNotification.showSuccess(context, 'Claim link copied!');
                        },
                        child: const Text('Copy Link'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(
                      'Done',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredGifts = _gifts.where((g) {
      if (_activeFilter == 'All') return true;
      return g.status.toLowerCase() == _activeFilter.toLowerCase();
    }).toList();

    return ResponsiveShell(
      currentRoute: '/gifts',
      onToggleTheme: widget.onToggleTheme,
      child: Container(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        child: SingleChildScrollView(
          padding: ResponsiveLayout.pagePadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // TOP BANNER
                  _buildTopBanner(isDark),
                  const SizedBox(height: 24),

                  // FILTER PILLS
                  _buildFilterPills(isDark),
                  const SizedBox(height: 36),

                  // GIFTS LIST OR EMPTY STATE
                  if (_isLoadingGifts)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filteredGifts.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    _buildGiftsList(isDark, filteredGifts),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. TOP BANNER
  Widget _buildTopBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052FF), Color(0xFF00A3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Back to Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gift Cards & Vouchers',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Send digital gift vouchers directly from your Avotek wallet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openCreateGiftModal,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Gift'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0052FF),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. FILTER PILLS
  Widget _buildFilterPills(bool isDark) {
    final filters = ['All', 'Active', 'Redeemed', 'Expired'];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final isSelected = _activeFilter == filter;
        return InkWell(
          onTap: () => setState(() => _activeFilter = filter),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Text(
              filter,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 3. EMPTY STATE
  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.card_giftcard_rounded,
              size: 56,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 18),
            Text(
              'No Gifts Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You haven't created any gifts yet",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _openCreateGiftModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Your First Gift',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. GIFTS LIST
  Widget _buildGiftsList(bool isDark, List<GiftVoucher> gifts) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gifts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final isActive = gift.status.toLowerCase() == 'active';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.success : Colors.grey)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: isActive ? AppColors.success : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          gift.code,
                          style: GoogleFonts.firaCode(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: gift.code));
                            TopNotification.showSuccess(context, 'Voucher code copied!');
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recipient: ${gift.recipient} • Created ${DateFormat('MMM dd, yyyy').format(gift.createdAt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.metallicLight
                            : AppColors.slateGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(gift.amount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isActive ? const Color(0xFF10B981) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (isActive ? const Color(0xFF10B981) : Colors.grey)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gift.status,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isActive ? const Color(0xFF10B981) : Colors.grey,
                      ),
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
}
