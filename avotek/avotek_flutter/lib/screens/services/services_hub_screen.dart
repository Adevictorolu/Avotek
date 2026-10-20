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
          '$serviceName is not enabled yet.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAwaitingProviderContract(String serviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$serviceName is disabled until Bigisub request and response details '
          'are verified.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAwaitingProviderActivation(String serviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$serviceName will be available after Bigisub settlement is verified '
          'and the provider integration is deployed.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
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
                    onPressed: () =>
                        setState(() => _isHubbleView = !_isHubbleView),
                    icon: Icon(
                      _isHubbleView
                          ? Icons.grid_view_rounded
                          : Icons.view_list_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isHubbleView ? 'List view' : 'Grid view',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    color: isDark
                        ? const Color(0xFF23304B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: isDark
                          ? AppColors.metallicLight
                          : AppColors.slateGrey,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.electricCyan,
                      size: 20,
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
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
                    isComingSoon: true,
                    onTap: () =>
                        _showAwaitingProviderActivation('Bulk SMS'),
                  ),
                  _ServiceCardData(
                    title: 'Airtime PIN Generation',
                    icon: Icons.print_rounded,
                    isComingSoon: true,
                    onTap: () => _showAwaitingProviderContract(
                      'Airtime PIN generation',
                    ),
                  ),
                ],
              ),

              // 2. ENTERTAINMENT
              _buildCategorySection(
                title: 'ENTERTAINMENT',
                count: 1,
                isDark: isDark,
                cards: [
                  _ServiceCardData(
                    title: 'Social Boost',
                    icon: Icons.trending_up_rounded,
                    isComingSoon: true,
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
                    isComingSoon: true,
                    onTap: () => _showComingSoon('Internet subscriptions'),
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
                    title: 'Result Checker PINs',
                    icon: Icons.school_rounded,
                    isComingSoon: true,
                    onTap: () => _showAwaitingProviderActivation(
                      'Result Checker PINs',
                    ),
                  ),
                ],
              ),

              // 6. BUSINESS & TRADE
              _buildCategorySection(
                title: 'BUSINESS & TRADE',
                count: 1,
                isDark: isDark,
                cards: [
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
                color: isDark
                    ? const Color(0xFF1A2234)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${filtered.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.electricCyan
                      : AppColors.primaryBlue,
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
            childAspectRatio: !_isHubbleView
                ? (isDesktop ? 5.5 : 3.2)
                : (isDesktop ? 1.7 : 1.35),
          ),
          itemBuilder: (context, idx) {
            final item = filtered[idx];
            return _buildServiceCard(
              item,
              isDark,
              compact: !_isHubbleView,
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildServiceCard(
    _ServiceCardData item,
    bool isDark, {
    required bool compact,
  }) {
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
        child: compact
            ? Row(
                children: [
                  _serviceIcon(item, isDark),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.isComingSoon) _comingSoonBadge(isDark),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _serviceIcon(item, isDark),
                  const SizedBox(height: 10),
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
                  if (item.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
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
                    _comingSoonBadge(isDark)
                  else
                    const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }

  Widget _serviceIcon(_ServiceCardData item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.electricCyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(item.icon, color: AppColors.electricCyan, size: 22),
    );
  }

  Widget _comingSoonBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
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
