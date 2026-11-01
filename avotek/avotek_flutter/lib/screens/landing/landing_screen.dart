import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/service_brand_logo.dart';
import '../../widgets/top_notification.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const LandingScreen({super.key, this.onToggleTheme});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // GlobalKeys for smooth section navigation
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _testimonialsKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  late AnimationController _animController;
  late Animation<double> _floatingAnim;

  static const String _facebookUrl =
      'https://www.facebook.com/profile.php?id=61552094371264';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatingAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        TopNotification.showError(context, 'Could not open link: $url');
      }
    }
  }

  Future<void> _showDownloadApkModal() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String apkUrl =
        'https://github.com/adevictorolu/Avotek/releases/latest/download/avotek.apk';
    String version = 'v1.2.0';

    try {
      final fetchedUrl =
          await SupabaseService.instance.getAppSetting('apk_download_url');
      if (fetchedUrl != null && fetchedUrl.trim().isNotEmpty) {
        apkUrl = fetchedUrl.trim();
      }
      final fetchedVer =
          await SupabaseService.instance.getAppSetting('apk_version');
      if (fetchedVer != null && fetchedVer.trim().isNotEmpty) {
        version = fetchedVer.trim();
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
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
                Icons.android_rounded,
                color: Color(0xFF10B981),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download Avotek App',
                    style: GoogleFonts.figtree(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Official Android APK ($version)',
                    style: GoogleFonts.figtree(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get the official Avotek Android app directly for lightning-fast recharge, automated bill processing, and instant push receipts.',
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Direct APK build verified for Android 8.0+',
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: apkUrl));
              Navigator.pop(ctx);
              TopNotification.showSuccess(
                context,
                'APK download link copied to clipboard!',
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(
              'Copy Link',
              style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(apkUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(
              'Download APK',
              style: GoogleFonts.figtree(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07090E) : const Color(0xFFF8FAFC),
      endDrawer: !isDesktop ? _buildMobileDrawer(isDark) : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Sticky Glassmorphic Navbar
          _buildSliverNavbar(isDesktop, isDark),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Hero Section with Floating Smartphone Mockup
                _buildHeroSection(isDesktop, isDark),

                // Official Partners Marquee Strip
                _buildOfficialPartnersStrip(isDesktop, isDark),

                // Live Impact Metrics Strip
                _buildMetricsStrip(isDesktop, isDark),

                // Bento Services Grid
                Container(
                  key: _servicesKey,
                  child: _buildServicesSection(isDesktop, isDark),
                ),

                // Interactive App Feature Showcase (Overlapping Cards)
                Container(
                  key: _featuresKey,
                  child: _buildOverlappingFeaturesShowcase(isDesktop, isDark),
                ),

                // How It Works Steps
                Container(
                  key: _howItWorksKey,
                  child: _buildHowItWorksSection(isDesktop, isDark),
                ),

                // Testimonials ("Dominion University & Across Nigeria")
                Container(
                  key: _testimonialsKey,
                  child: _buildTestimonialsSection(isDesktop, isDark),
                ),

                // Direct APK Download Banner
                _buildDirectApkBanner(isDesktop, isDark),

                // Frequently Asked Questions
                Container(
                  key: _faqKey,
                  child: _buildFaqSection(isDesktop, isDark),
                ),

                // Clean Footer (Per Exact Specification)
                _buildFooter(isDesktop, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. NAVBAR
  // ==========================================
  Widget _buildSliverNavbar(bool isDesktop, bool isDark) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: (isDark ? const Color(0xFF07090E) : Colors.white)
          .withValues(alpha: 0.94),
      titleSpacing: isDesktop ? 48 : 20,
      title: Row(
        mainAxisAlignment:
            isDesktop ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(8),
            child: const AvotekLogo(size: 28, showText: true),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 48),
            _buildNavLink('Services', () => _scrollToKey(_servicesKey), isDark),
            _buildNavLink('Features', () => _scrollToKey(_featuresKey), isDark),
            _buildNavLink(
                'How It Works', () => _scrollToKey(_howItWorksKey), isDark),
            _buildNavLink(
                'Testimonials', () => _scrollToKey(_testimonialsKey), isDark),
            _buildNavLink('FAQs', () => _scrollToKey(_faqKey), isDark),
          ],
        ],
      ),
      actions: [
        if (isDesktop) ...[
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              size: 20,
            ),
            onPressed: () {
              if (widget.onToggleTheme != null) {
                widget.onToggleTheme!();
              } else {
                context.read<ThemeProvider>().toggleTheme();
              }
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sign In',
              style: GoogleFonts.figtree(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0038B8).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => context.go('/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Get Started Free',
                style: GoogleFonts.figtree(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ] else ...[
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildNavLink(String label, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F121C) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AvotekLogo(size: 26, showText: true),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _drawerItem('Services', Icons.grid_view_rounded, () {
                    Navigator.pop(context);
                    _scrollToKey(_servicesKey);
                  }, isDark),
                  _drawerItem('Features', Icons.auto_awesome_rounded, () {
                    Navigator.pop(context);
                    _scrollToKey(_featuresKey);
                  }, isDark),
                  _drawerItem('How It Works', Icons.touch_app_rounded, () {
                    Navigator.pop(context);
                    _scrollToKey(_howItWorksKey);
                  }, isDark),
                  _drawerItem('Testimonials', Icons.reviews_rounded, () {
                    Navigator.pop(context);
                    _scrollToKey(_testimonialsKey);
                  }, isDark),
                  _drawerItem('FAQs', Icons.help_outline_rounded, () {
                    Navigator.pop(context);
                    _scrollToKey(_faqKey);
                  }, isDark),
                  _drawerItem('Download APK', Icons.android_rounded, () {
                    Navigator.pop(context);
                    _showDownloadApkModal();
                  }, isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/login');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/register');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Create Free Account'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
      String label, IconData icon, VoidCallback onTap, bool isDark) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00D2FF), size: 20),
      title: Text(
        label,
        style: GoogleFonts.figtree(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      onTap: onTap,
    );
  }

  // ==========================================
  // 2. HERO SECTION WITH SMARTPHONE MOCKUP
  // ==========================================
  Widget _buildHeroSection(bool isDesktop, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: isDesktop ? 50 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 12,
                      child: _buildHeroCopy(isDesktop, isDark),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 11,
                      child: AnimatedBuilder(
                        animation: _floatingAnim,
                        builder: (ctx, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingAnim.value),
                            child: child,
                          );
                        },
                        child: _buildPhoneMockup(isDark),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildHeroCopy(isDesktop, isDark),
                    const SizedBox(height: 38),
                    _buildPhoneMockup(isDark),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroCopy(bool isDesktop, bool isDark) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Floating Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0052FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8), size: 16),
              const SizedBox(width: 6),
              Text(
                '100% Automated VTU & Instant Payment Gateway',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Main Title
        RichText(
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.figtree(
              fontSize: isDesktop ? 50 : 32,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -1.2,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            children: [
              const TextSpan(text: 'Seamless VTU, Cheap Data & '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF60A5FA), const Color(0xFF38BDF8)]
                        : [const Color(0xFF0038B8), const Color(0xFF0052FF)],
                  ).createShader(bounds),
                  child: Text(
                    'Instant Bills',
                    style: GoogleFonts.figtree(
                      fontSize: isDesktop ? 50 : 32,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const TextSpan(text: ' in Nigeria.'),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Subtitle
        Text(
          'Recharge airtime with instant 2% cashback, buy cheap SME data bundles from ₦49, '
          'generate WAEC/NECO result checker PINs, and settle electricity tokens in seconds with zero delay.',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: GoogleFonts.figtree(
            fontSize: isDesktop ? 16 : 14.5,
            height: 1.6,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 28),

        // Dual Action CTA
        Wrap(
          spacing: 14,
          runSpacing: 12,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0038B8).withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/register'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Get Started Free'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.figtree(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _showDownloadApkModal,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download Android APK'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.white : const Color(0xFF0F172A),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.figtree(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Social Trust Proof Badge
        Row(
          mainAxisAlignment:
              isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '4.9/5 • Trusted by 10,000+ students & agents across Nigeria',
                style: GoogleFonts.figtree(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // REALISTIC SMARTPHONE MOCKUP EMBEDDING AVOTEK APP
  // ==========================================
  Widget _buildPhoneMockup(bool isDark) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Ambient Glow Behind the Phone
          Container(
            width: 320,
            height: 480,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0052FF).withValues(alpha: 0.35),
                  const Color(0xFF00D2FF).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Physical Titanium Phone Body
          Container(
            width: 310,
            height: 620,
            decoration: BoxDecoration(
              color: const Color(0xFF090C12),
              borderRadius: BorderRadius.circular(46),
              border: Border.all(
                color: const Color(0xFF334155),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(42),
              child: Column(
                children: [
                  // Phone Status Bar & Dynamic Island
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: const Color(0xFF0F131D),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '9:41',
                          style: GoogleFonts.figtree(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                        // Dynamic Island Pill
                        Container(
                          width: 82,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.wifi_rounded,
                                size: 14, color: Colors.white70),
                            SizedBox(width: 4),
                            Icon(Icons.battery_full_rounded,
                                size: 16, color: Colors.white70),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Phone In-App Screen Content
                  Expanded(
                    child: Container(
                      color: const Color(0xFF0B0E17),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App Bar Header Inside Mockup
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back 👋',
                                    style: GoogleFonts.figtree(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Text(
                                    'Adewale Victor',
                                    style: GoogleFonts.figtree(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2638),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 16,
                                  color: Color(0xFF00D2FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Avotek Virtual Balance Hero Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0052FF), Color(0xFF0084FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0052FF)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Available Wallet Balance',
                                      style: GoogleFonts.figtree(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Tier 2 KYC 🛡️',
                                        style: GoogleFonts.figtree(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '₦48,500.00',
                                      style: GoogleFonts.figtree(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.visibility_rounded,
                                      color: Colors.white70,
                                      size: 15,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '+ Fund Wallet',
                                            style: GoogleFonts.figtree(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0052FF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Quick Services Grid Inside Mockup
                          Text(
                            'Quick Services',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildMockupServiceChip('Airtime', '2% Back',
                                  Icons.phone_android_rounded),
                              _buildMockupServiceChip(
                                  'Data', '₦49 SME', Icons.wifi_rounded),
                              _buildMockupServiceChip(
                                  'Cable TV', 'Replay', Icons.tv_rounded),
                              _buildMockupServiceChip(
                                  'Power', 'Token', Icons.flash_on_rounded),
                              _buildMockupServiceChip('Exam PIN', 'WAEC/NECO',
                                  Icons.school_rounded),
                              _buildMockupServiceChip('Pay For Me', 'Share link',
                                  Icons.share_rounded),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Recent Activity Card Inside Mockup
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141926),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF222B3F),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF10B981),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MTN 2.5GB SME Sent',
                                        style: GoogleFonts.figtree(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '0803***8912 • Instant Delivery',
                                        style: GoogleFonts.figtree(
                                          fontSize: 9.5,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₦570.00',
                                  style: GoogleFonts.figtree(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF00D2FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Home Indicator Bar
                  Container(
                    height: 20,
                    color: const Color(0xFF0B0E17),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlapping Floating Notification Chip 1 (Top Left)
          Positioned(
            top: 70,
            left: -28,
            child: _buildFloatingBadge(
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFF00D2FF),
              title: 'Instant Delivery',
              subtitle: 'Processed in < 3 seconds',
            ),
          ),

          // Overlapping Floating Notification Chip 2 (Bottom Right)
          Positioned(
            bottom: 60,
            right: -24,
            child: _buildFloatingBadge(
              icon: Icons.card_giftcard_rounded,
              iconColor: const Color(0xFF10B981),
              title: '2% Cashback Received',
              subtitle: 'Credited straight to wallet',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupServiceChip(String label, String badge, IconData icon) {
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF222B3F)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00D2FF), size: 16),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            badge,
            style: GoogleFonts.figtree(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBadge({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1422).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF26334D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.figtree(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.figtree(
                  fontSize: 9.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. OFFICIAL TELECOM & PROVIDER MARQUEE STRIP
  // ==========================================
  Widget _buildOfficialPartnersStrip(bool isDesktop, bool isDark) {
    final partners = [
      ('MTN', 'assets/images/brands/mtn.png'),
      ('AIRTEL', 'assets/images/brands/airtel.png'),
      ('GLO', 'assets/images/brands/glo.png'),
      ('9MOBILE', 'assets/images/brands/9mobile.png'),
      ('DSTV', 'assets/images/brands/dstv.png'),
      ('GOTV', 'assets/images/brands/gotv.png'),
      ('STARTIMES', 'assets/images/brands/startimes.png'),
      ('WAEC', 'assets/images/brands/waec.png'),
      ('NECO', 'assets/images/brands/neco.png'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      color: isDark ? const Color(0xFF090B12) : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          Text(
            'POWERING ALL MAJOR NIGERIAN TELECOM NETWORKS & UTILITY PROVIDERS',
            style: GoogleFonts.figtree(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 24),
                ...partners.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF131724)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF222B3D)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                p.$2,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    ServiceBrandLogo(provider: p.$1, size: 28),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              p.$1,
                              style: GoogleFonts.figtree(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(width: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. METRICS / IMPACT STRIP
  // ==========================================
  Widget _buildMetricsStrip(bool isDesktop, bool isDark) {
    final metrics = [
      ('99.98%', 'Automated Uptime', 'Direct API telecom switches'),
      ('< 3s', 'Average Delivery', 'Instant VTU & token activation'),
      ('10,000+', 'Active Nigerians', 'Students, agents & families'),
      ('₦0', 'Hidden Maintenance', 'Zero monthly or surprise deductions'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: metrics
                .map((m) => Container(
                      width: isDesktop ? 275 : double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF101420)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF222C42)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.$1,
                            style: GoogleFonts.figtree(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.$2,
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.$3,
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 5. BENTO SERVICES SECTION
  // ==========================================
  Widget _buildServicesSection(bool isDesktop, bool isDark) {
    final services = [
      (
        'Cheap Mobile Data',
        'MTN, Airtel, Glo & 9mobile SME, Corporate & Gifting bundles from ₦49.',
        Icons.wifi_rounded,
        'From ₦49',
        '/services/data',
      ),
      (
        'Airtime + 2% Cashback',
        'Instant recharge for all Nigerian networks with 2% credited back to balance.',
        Icons.phone_android_rounded,
        '2% Cashback',
        '/services/airtime',
      ),
      (
        'Cable TV Subscriptions',
        'DStv, GOtv & StarTimes renewals with immediate decoder auto-reconnection.',
        Icons.tv_rounded,
        'Zero Fee',
        '/services/tv',
      ),
      (
        'Electricity Meter Tokens',
        'Instant 20-digit prepaid & postpaid tokens generated for all 11 DisCos.',
        Icons.flash_on_rounded,
        'Instant Token',
        '/services/electricity',
      ),
      (
        'Result Checker PINs',
        'Direct WAEC, NECO & NABTEB result checker PINs delivered on-screen and via SMS.',
        Icons.school_rounded,
        'Instant PIN',
        '/services/exam-pins',
      ),
      (
        'Broadband & Fibre',
        'Fast high-speed data bundles for Smile, Spectranet & Swift broadband devices.',
        Icons.language_rounded,
        'Broadband',
        '/services/internet',
      ),
      (
        'Bulk SMS & Airtime PINs',
        'Generate recharge scratch card PINs and send corporate bulk SMS with custom sender IDs.',
        Icons.print_rounded,
        'High Delivery',
        '/services/bulk-sms',
      ),
      (
        'Pay For Me (Shareable Link)',
        'Generate a secure payment link on any service and share it with family or sponsors.',
        Icons.share_rounded,
        'Shareable Link',
        '/services',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              _buildSectionHeader(
                eyebrow: 'ALL-IN-ONE DIGITAL UTILITY SUITE',
                title: 'Built for Speed. Configured for Reliability.',
                subtitle:
                    'Only official, active services supported by direct telecom and DisCo switches.',
                isDark: isDark,
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: services
                    .map((s) => InkWell(
                          onTap: () => context.push(s.$5),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: isDesktop ? 285 : double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF101420)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF222C42)
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0052FF)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        s.$3,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
                                        size: 24,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        s.$4,
                                        style: GoogleFonts.figtree(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  s.$1,
                                  style: GoogleFonts.figtree(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.$2,
                                  style: GoogleFonts.figtree(
                                    fontSize: 12.5,
                                    height: 1.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 6. OVERLAPPING FEATURES SHOWCASE
  // ==========================================
  Widget _buildOverlappingFeaturesShowcase(bool isDesktop, bool isDark) {
    final features = [
      (
        '100% Automated Delivery Under 3 Seconds',
        'Direct fiber integration with MTN, Airtel, Glo, and 9mobile gateways guarantees that all purchases complete instantaneously with zero human delays.',
        Icons.timer_outlined,
      ),
      (
        'Secure wallet funding',
        'Open Fund Wallet to see available payment options. Your wallet balance updates after payment confirmation.',
        Icons.payment_rounded,
      ),
      (
        'Mutual Referral & Affiliate Earnings',
        'Earn ₦50 wallet balance + 100 AVO points for every friend you invite, while your friend receives a ₦25 welcome bonus. Enjoy lifetime commissions on all their top-ups.',
        Icons.group_add_outlined,
      ),
      (
        'Bank-Grade PIN & Biometric Security',
        'All purchases are protected by your personal 4-digit transaction authorization PIN and encrypted session authentication.',
        Icons.security_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 60,
      ),
      color: isDark ? const Color(0xFF090C14) : const Color(0xFFF1F5F9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              _buildSectionHeader(
                eyebrow: 'WHY CHOOSE AVOTEK',
                title: 'The Modern Standard for Digital Top-Ups',
                subtitle:
                    'Experience an ultra-fast, dependable platform designed for everyday Nigerians.',
                isDark: isDark,
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: features
                    .map((f) => Container(
                          width: isDesktop ? 570 : double.infinity,
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111624)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF24304A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0052FF)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  f.$3,
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.$1,
                                      style: GoogleFonts.figtree(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      f.$2,
                                      style: GoogleFonts.figtree(
                                        fontSize: 13,
                                        height: 1.55,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 7. HOW IT WORKS
  // ==========================================
  Widget _buildHowItWorksSection(bool isDesktop, bool isDark) {
    final steps = [
      (
        '01',
        'Create Free Account',
        'Register in 30 seconds with just your name, email, and phone number.',
      ),
      (
        '02',
        'Fund Wallet',
        'Open Fund Wallet and complete an available payment method. Your balance updates after the payment is confirmed.',
      ),
      (
        '03',
        'Transact Seamlessly',
        'Select data, airtime, or utility bills. Delivery completes automatically in under 3 seconds.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              _buildSectionHeader(
                eyebrow: 'SIMPLE 3-STEP PROCESS',
                title: 'Start Topping Up in Under a Minute',
                subtitle:
                    'Zero complicated configurations. Pure speed from day one.',
                isDark: isDark,
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: steps
                    .map((s) => Container(
                          width: isDesktop ? 370 : double.infinity,
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF101420)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF222C42)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.$1,
                                style: GoogleFonts.figtree(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s.$2,
                                style: GoogleFonts.figtree(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.$3,
                                style: GoogleFonts.figtree(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 8. TESTIMONIALS (DOMINION UNIVERSITY & NIGERIA)
  // ==========================================
  Widget _buildTestimonialsSection(bool isDesktop, bool isDark) {
    final reviews = [
      (
        'Oluwaseun Adeyemi',
        'Student, Dominion University',
        'Being at Dominion University, staying connected for lectures and research is essential. Avotek’s SME data is ridiculously cheap and delivers in 3 seconds!',
      ),
      (
        'Chidinma Okafor',
        'VTU Reseller & Campus Agent, Lagos',
        'I run a small data reselling hustle. The 2% airtime cashback and referral commissions allow me to make consistent profit every single week.',
      ),
      (
        'Engr. Babatunde Lawal',
        'Resident, Ibadan',
        'Getting prepaid electricity tokens used to be stressful with bank failures. On Avotek, our 20-digit token generates immediately right on screen.',
      ),
      (
        'Amina Bello',
        'Entrepreneur, Abuja',
        'The Pay For Me feature is a lifesaver! I generated a link for my cable subscription, sent it on WhatsApp to my brother, and it was settled in seconds.',
      ),
      (
        'Emmanuel Nwachukwu',
        'Undergraduate, University of Ibadan',
        'Bought my WAEC result checker PIN here without stress. The clean UI and instant verification makes Avotek way ahead of other sites.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 60,
      ),
      color: isDark ? const Color(0xFF090C14) : const Color(0xFFF1F5F9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              _buildSectionHeader(
                eyebrow: 'WHAT USERS ARE SAYING',
                title: 'Loved by Students, Agents & Businesses Across Nigeria',
                subtitle:
                    'Real reviews from real Nigerians who rely on Avotek every day.',
                isDark: isDark,
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: reviews
                    .map((r) => Container(
                          width: isDesktop ? 370 : double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111624)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF24304A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB800),
                                    size: 17,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '"${r.$3}"',
                                style: GoogleFonts.figtree(
                                  fontSize: 13,
                                  height: 1.6,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF0052FF),
                                    child: Text(
                                      r.$1.substring(0, 1),
                                      style: GoogleFonts.figtree(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.$1,
                                          style: GoogleFonts.figtree(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          r.$2,
                                          style: GoogleFonts.figtree(
                                            fontSize: 11,
                                            color: const Color(0xFF00D2FF),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 9. DIRECT APK DOWNLOAD BANNER
  // ==========================================
  Widget _buildDirectApkBanner(bool isDesktop, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isDesktop ? 44 : 26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF071B3E), Color(0xFF002F9E), Color(0xFF0047FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0038B8).withValues(alpha: 0.40),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isDesktop
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.android_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Get the Official Avotek Android App',
                              style: GoogleFonts.figtree(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Download the lightweight APK directly to your phone for instant recharge shortcuts, biometric sign-in, and push notifications.',
                              style: GoogleFonts.figtree(
                                fontSize: 13.5,
                                color: Colors.white.withValues(alpha: 0.90),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      ElevatedButton.icon(
                        onPressed: _showDownloadApkModal,
                        icon: const Icon(Icons.download_rounded,
                            color: Color(0xFF0052FF)),
                        label: const Text('Download APK Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0052FF),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: GoogleFonts.figtree(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.android_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Get the Official Avotek Android App',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.figtree(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download the lightweight APK directly to your phone for instant recharge shortcuts and push receipts.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.figtree(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showDownloadApkModal,
                          icon: const Icon(Icons.download_rounded,
                              color: Color(0xFF0052FF)),
                          label: const Text('Download APK Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0052FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: GoogleFonts.figtree(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
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

  // ==========================================
  // 10. FREQUENTLY ASKED QUESTIONS
  // ==========================================
  Widget _buildFaqSection(bool isDesktop, bool isDark) {
    final faqs = [
      (
        'How fast is airtime, data, and bill delivery?',
        'All purchases on Avotek are 100% automated with direct API telecom links. Transactions complete in under 3 seconds. Electricity tokens and exam PINs appear instantly on your screen and in your transaction history.',
      ),
      (
        'How does "Pay For Me" (Shareable Link) work?',
        'Select any service (Airtime, Data, Cable, or Electricity), tick the "Pay For Me" checkbox, and generate a secure shareable link. You can send this link via WhatsApp or SMS to a sponsor, parent, or friend to pay for you.',
      ),
      (
        'How do I fund my wallet?',
        'Open Fund Wallet and follow the payment options shown for your account. Your balance updates after the payment is confirmed.',
      ),
      (
        'How do referral rewards work?',
        'When someone registers with your referral code or Avotek ID, you receive ₦50 wallet balance + 100 AVO points, and your friend gets a ₦25 welcome bonus instantly! You also earn lifetime commissions on their recharges.',
      ),
      (
        'Are there any hidden monthly or transaction fees?',
        'None. What you see is what you pay. Airtime even comes with an instant 2% cashback discount credited directly to your balance.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            children: [
              _buildSectionHeader(
                eyebrow: 'GOT QUESTIONS?',
                title: 'Frequently Asked Questions',
                subtitle:
                    'Everything you need to know about using Avotek for everyday digital payments.',
                isDark: isDark,
              ),
              const SizedBox(height: 38),
              ...faqs.map((f) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101420) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF222C42)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      title: Text(
                        f.$1,
                        style: GoogleFonts.figtree(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            f.$2,
                            style: GoogleFonts.figtree(
                              fontSize: 13,
                              height: 1.55,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 11. FOOTER (PER USER INSTRUCTIONS)
  // ==========================================
  Widget _buildFooter(bool isDesktop, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 48,
      ),
      color: isDark ? const Color(0xFF05070B) : const Color(0xFFF1F5F9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Brand Column
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AvotekLogo(size: 30, showText: true),
                              const SizedBox(height: 12),
                              Text(
                                'Nigeria’s premier automated platform for discounted data, airtime cashback, utility bill settlements, and educational PINs.',
                                style: GoogleFonts.figtree(
                                  fontSize: 13,
                                  height: 1.55,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Facebook Social Link (Only Facebook per user request)
                              InkWell(
                                onTap: () => _openExternalUrl(_facebookUrl),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1877F2)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF1877F2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.facebook_rounded,
                                        color: Color(0xFF1877F2),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Follow Avotek on Facebook',
                                        style: GoogleFonts.figtree(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1877F2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),

                        // Middle Links Column
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SERVICES',
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _footerLink('Buy Cheap Data', '/services/data', isDark),
                              _footerLink('Buy Airtime (2% Cashback)', '/services/airtime', isDark),
                              _footerLink('Cable TV Subscriptions', '/services/tv', isDark),
                              _footerLink('Electricity Tokens', '/services/electricity', isDark),
                              _footerLink('Result Checker PINs', '/services/exam-pins', isDark),
                            ],
                          ),
                        ),

                        // Right Links Column
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QUICK LINKS',
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _footerActionLink('Services Overview', () => _scrollToKey(_servicesKey), isDark),
                              _footerActionLink('Customer Testimonials', () => _scrollToKey(_testimonialsKey), isDark),
                              _footerActionLink('Frequently Asked Questions', () => _scrollToKey(_faqKey), isDark),
                              _footerActionLink('Download Android APK', _showDownloadApkModal, isDark),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AvotekLogo(size: 28, showText: true),
                        const SizedBox(height: 10),
                        Text(
                          'Nigeria’s premier automated platform for discounted data, airtime cashback, and utility bill settlements.',
                          style: GoogleFonts.figtree(
                            fontSize: 12.5,
                            height: 1.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _openExternalUrl(_facebookUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF1877F2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.facebook_rounded,
                                    color: Color(0xFF1877F2), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Follow Avotek on Facebook',
                                  style: GoogleFonts.figtree(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1877F2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _footerActionLink('Services', () => _scrollToKey(_servicesKey), isDark),
                            _footerActionLink('Reviews', () => _scrollToKey(_testimonialsKey), isDark),
                            _footerActionLink('FAQs', () => _scrollToKey(_faqKey), isDark),
                            _footerActionLink('Download APK', _showDownloadApkModal, isDark),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 36),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Bottom Bar: Copyright 2022 to 2026 (Per User Instruction)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Avotek copyright 2022 to 2026. All rights reserved.',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _showDownloadApkModal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.android_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Get Android APK',
                          style: GoogleFonts.figtree(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerLink(String label, String route, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push(route),
        child: Text(
          label,
          style: GoogleFonts.figtree(
            fontSize: 13,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _footerActionLink(String label, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: GoogleFonts.figtree(
            fontSize: 13,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // Section Header Helper
  Widget _buildSectionHeader({
    required String eyebrow,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0052FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            eyebrow,
            style: GoogleFonts.figtree(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.figtree(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.figtree(
              fontSize: 14,
              height: 1.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
