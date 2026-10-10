import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';

class ServicesHubScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const ServicesHubScreen({super.key, required this.onToggleTheme});

  @override
  State<ServicesHubScreen> createState() => _ServicesHubScreenState();
}

class _ServicesHubScreenState extends State<ServicesHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isHubbleView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showComingSoon(String serviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$serviceName integration is coming soon in the next release!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showActionModal({
    required String title,
    required String description,
    required IconData icon,
    required Widget formContent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.electricCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.electricCyan, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: formContent,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ResponsiveShell(
      currentRoute: '/services',
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC),
        floatingActionButton: FloatingActionButton(
          heroTag: 'hub_support',
          backgroundColor: AppColors.primaryBlue,
          elevation: 4,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avotek Customer Support: Contact support@avotek.ng'),
                backgroundColor: AppColors.primaryBlue,
              ),
            );
          },
          child: const Icon(Icons.headset_mic_rounded, color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Title & View Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Services',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isHubbleView = !_isHubbleView),
                    icon: Icon(
                      _isHubbleView ? Icons.language_rounded : Icons.grid_view_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isHubbleView ? 'Switch to Compact View' : 'Switch to Hubble View',
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

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131722) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.electricCyan, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // CATEGORIZED SECTIONS
              // 1. MOBILE SERVICES
              _buildCategorySection(
                title: 'MOBILE SERVICES',
                count: 4,
                isDark: isDark,
                cards: [
                  _ServiceCardData(
                    title: 'Buy Airtime',
                    icon: Icons.phone_android_rounded,
                    isPopular: true,
                    onTap: () => context.push('/services/airtime'),
                  ),
                  _ServiceCardData(
                    title: 'Buy Data',
                    icon: Icons.wifi_rounded,
                    isPopular: true,
                    onTap: () => context.push('/services/data'),
                  ),
                  _ServiceCardData(
                    title: 'Bulk SMS',
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => _showBulkSmsModal(isDark),
                  ),
                  _ServiceCardData(
                    title: 'Printing Airtime',
                    icon: Icons.print_rounded,
                    onTap: () => _showAirtimePrintingModal(isDark),
                  ),
                ],
              ),

              // 2. ENTERTAINMENT
              _buildCategorySection(
                title: 'ENTERTAINMENT',
                count: 2,
                isDark: isDark,
                cards: [
                  _ServiceCardData(
                    title: 'Sports Betting & Games',
                    icon: Icons.sports_esports_rounded,
                    isPopular: true,
                    onTap: () => _showBettingModal(isDark),
                  ),
                  _ServiceCardData(
                    title: 'Social Boost',
                    icon: Icons.trending_up_rounded,
                    onTap: () => _showComingSoon('Social Boost Marketing'),
                  ),
                ],
              ),

              // 3. TV & INTERNET
              _buildCategorySection(
                title: 'TV & INTERNET',
                count: 2,
                isDark: isDark,
                cards: [
                  _ServiceCardData(
                    title: 'Cable Subscription',
                    icon: Icons.tv_rounded,
                    isPopular: true,
                    onTap: () => context.push('/services/tv'),
                  ),
                  _ServiceCardData(
                    title: 'Internet',
                    icon: Icons.language_rounded,
                    onTap: () => context.push('/services/data'),
                  ),
                ],
              ),

              // 4. BILLS & UTILITIES
              _buildCategorySection(
                title: 'BILLS & UTILITIES',
                count: 1,
                isDark: isDark,
                cards: [
                  _ServiceCardData(
                    title: 'Electricity',
                    icon: Icons.flash_on_rounded,
                    onTap: () => context.push('/services/electricity'),
                  ),
                ],
              ),

              // 5. EDUCATION
              _buildCategorySection(
                title: 'EDUCATION',
                count: 1,
                isDark: isDark,
                cards: [
                  _ServiceCardData(
                    title: 'Result Checker',
                    icon: Icons.school_rounded,
                    onTap: () => _showResultCheckerModal(isDark),
                  ),
                ],
              ),

              // 6. BUSINESS & TRADE
              _buildCategorySection(
                title: 'BUSINESS & TRADE',
                count: 2,
                isDark: isDark,
                cards: [
                  _ServiceCardData(
                    title: 'Afroxtend Guild',
                    icon: Icons.groups_rounded,
                    isPopular: true,
                    onTap: () => _showAfroxtendModal(isDark),
                  ),
                  _ServiceCardData(
                    title: 'Corporate Affairs',
                    icon: Icons.business_center_rounded,
                    isComingSoon: true,
                    onTap: () => _showComingSoon('CAC Business Registration'),
                  ),
                ],
              ),

              // 7. TRAVEL
              _buildCategorySection(
                title: 'TRAVEL',
                count: 1,
                isDark: isDark,
                cards: [
                  _ServiceCardData(
                    title: 'Flight Tickets',
                    icon: Icons.flight_takeoff_rounded,
                    isComingSoon: true,
                    onTap: () => _showComingSoon('Flight Bookings'),
                  ),
                ],
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required int count,
    required bool isDark,
    required List<_ServiceCardData> cards,
  }) {
    final filtered = cards.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.electricCyan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2234) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${filtered.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.electricCyan : AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Grid of Cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: isDesktop ? 1.7 : 1.35,
          ),
          itemBuilder: (context, idx) {
            final item = filtered[idx];
            return _buildServiceCard(item, isDark);
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildServiceCard(_ServiceCardData item, bool isDark) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E2638) : const Color(0xFFEFF6FF)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.electricCyan.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(item.icon, color: AppColors.electricCyan, size: 22),
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Badge
            if (item.isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.electricCyan.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Popular',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.electricCyan,
                  ),
                ),
              )
            else if (item.isComingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'COMING SOON',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- Modals for Non-Standard Services ---

  void _showBulkSmsModal(bool isDark) {
    final senderCtrl = TextEditingController(text: 'AVOTEK');
    final recipientsCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    _showActionModal(
      title: 'Bulk SMS Messaging',
      description: 'Deliver instant SMS across all Nigerian networks.',
      icon: Icons.chat_bubble_outline_rounded,
      formContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: senderCtrl,
            decoration: const InputDecoration(labelText: 'Sender ID (Max 11 characters)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: recipientsCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Phone Numbers (comma separated)',
              hintText: '08012345678, 09087654321',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: msgCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Message Text'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bulk SMS queued for dispatch!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text(
                'Send Broadcast Now',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAirtimePrintingModal(bool isDark) {
    _showActionModal(
      title: 'Airtime PIN Generation',
      description: 'Generate e-pins for recharge card printing.',
      icon: Icons.print_rounded,
      formContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: 'MTN',
            items: ['MTN', 'AIRTEL', 'GLO', '9MOBILE']
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: 'Select Network'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: 500,
            items: [100, 200, 500, 1000]
                .map((d) => DropdownMenuItem(value: d, child: Text('₦$d')))
                .toList(),
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: 'Denomination'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recharge PIN generated successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text(
                'Generate E-PINs',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBettingModal(bool isDark) {
    final idCtrl = TextEditingController();
    final amtCtrl = TextEditingController(text: '1000');

    _showActionModal(
      title: 'Fund Betting Account',
      description: 'Top up SportyBet, Bet9ja, 1xBet & more.',
      icon: Icons.sports_esports_rounded,
      formContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: 'SportyBet',
            items: ['SportyBet', 'Bet9ja', '1xBet', 'BangBet', 'Betway']
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: 'Select Bookmaker'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: idCtrl,
            decoration: const InputDecoration(
              labelText: 'User ID / Account Number',
              hintText: 'e.g. 70912384',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amtCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (₦)'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Betting account credited successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text(
                'Fund Account',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultCheckerModal(bool isDark) {
    _showActionModal(
      title: 'WAEC / NECO / JAMB PINs',
      description: 'Instant scratch card token generation.',
      icon: Icons.school_rounded,
      formContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: 'WAEC',
            items: ['WAEC', 'NECO', 'NABTEB', 'JAMB UTME']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: 'Examination Board'),
          ),
          const SizedBox(height: 12),
          const TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: 'Recipient Phone Number'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN token purchased and sent to phone!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text(
                'Buy Token',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAfroxtendModal(bool isDark) {
    _showActionModal(
      title: 'Afroxtend Partner Guild',
      description: 'Unlock reseller VTU wholesale margins & website ownership.',
      icon: Icons.groups_rounded,
      formContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Become an authorized Avotek Reseller Agent and get up to 5% off all airtime and data bundles.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricCyan,
                foregroundColor: const Color(0xFF0A0D14),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reseller application submitted!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text(
                'Join Agent Guild',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCardData {
  final String title;
  final IconData icon;
  final bool isPopular;
  final bool isComingSoon;
  final VoidCallback onTap;

  _ServiceCardData({
    required this.title,
    required this.icon,
    this.isPopular = false,
    this.isComingSoon = false,
    required this.onTap,
  });
}
