import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class AffiliateScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const AffiliateScreen({super.key, required this.onToggleTheme});

  @override
  State<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends State<AffiliateScreen> {
  int _activeTab = 0; // 0: Referral Hub, 1: RIFToken, 2: Leaderboard
  bool _copied = false;
  int _userRifPoints = 0;

  void _copyToClipboard(String link) {
    Clipboard.setData(ClipboardData(text: link));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Referral link copied to clipboard!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareOnPlatform(String platform, String link) async {
    final text = Uri.encodeComponent(
      'Join Avotek for instant cheap data, airtime, and utility bill payments! Register using my link: $link',
    );
    Uri? url;
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        url = Uri.parse('https://api.whatsapp.com/send?text=$text');
        break;
      case 'twitter':
        url = Uri.parse('https://twitter.com/intent/tweet?text=$text');
        break;
      case 'facebook':
        url = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}');
        break;
      case 'more':
        _copyToClipboard(link);
        return;
    }

    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _copyToClipboard(link);
    }
  }

  void _openRedeemPointsModal(WalletProvider wallet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.toll_rounded, color: AppColors.electricCyan),
              const SizedBox(width: 10),
              Text(
                'Redeem RIFToken Points',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Convert your earned points directly to cash in your Avotek wallet balance.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AVAILABLE POINTS:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      ),
                    ),
                    Text(
                      '$_userRifPoints pts (₦$_userRifPoints.00)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.electricCyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Minimum redemption threshold is 200 pts (Berekete level). At Jolly level, continue sharing your link to start unlocking cash conversions.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: _userRifPoints >= 200
                  ? () {
                      final cash = _userRifPoints.toDouble();
                      wallet.depositFunds(cash, narration: 'RIFToken Points Redeemed');
                      setState(() => _userRifPoints = 0);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('₦$cash credited to your wallet!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  : () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Accumulate at least 200 pts to redeem for cash.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Redeem Now',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();

    final avoId = (auth.user?.avoId != null && auth.user!.avoId.isNotEmpty)
        ? auth.user!.avoId
        : ((auth.user?.referralCode != null && auth.user!.referralCode.isNotEmpty)
            ? auth.user!.referralCode
            : 'AVO-10001');

    final username = (auth.user?.username != null && auth.user!.username!.isNotEmpty)
        ? auth.user!.username!
        : ((auth.user?.name.isNotEmpty == true)
            ? auth.user!.name.replaceAll(' ', '').toLowerCase()
            : ((auth.user?.email.isNotEmpty == true)
                ? auth.user!.email.split('@').first
                : avoId.toLowerCase()));
    final referralLink = 'https://avotek.ng/@$username';

    return ResponsiveShell(
      currentRoute: '/affiliate',
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
                  // --- TOP TABS: Referral Hub | RIFToken | Leaderboard (Matches Screenshots) ---
                  _buildTopTabs(isDark),
                  const SizedBox(height: 24),

                  if (_activeTab == 0) ...[
                    // --- SUBTITLE HEADER: REFERRAL HUB ---
                    _buildSectionHeader(
                      icon: Icons.people_alt_outlined,
                      title: 'REFERRAL HUB',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),

                    // --- HERO CARD: Refer & Earn (Screenshots 1 & 2) ---
                    _buildReferAndEarnCard(isDark, referralLink, avoId: avoId),
                    const SizedBox(height: 20),

                    // --- GROW YOUR NETWORK CARD ---
                    _buildGrowNetworkCard(isDark, referralLink),
                    const SizedBox(height: 20),

                    // --- HOW IT WORKS (1 -> 2 -> 3) ---
                    _buildHowItWorksCard(isDark),
                    const SizedBox(height: 20),

                    // --- 3 STAT CARDS: TOTAL EARNINGS, AVAILABLE BALANCE, TOTAL REFERRALS ---
                    _buildThreeStatCards(isDark, wallet),
                    const SizedBox(height: 20),

                    // --- YOUR REFERRALS LIST CARD ---
                    _buildYourReferralsCard(isDark),
                  ] else if (_activeTab == 1) ...[
                    // --- TAB 1: RIFTOKEN PROGRESS (Matches Screenshots 4 & 5) ---
                    _buildSectionHeader(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'RIFTOKEN PROGRESS',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),

                    // 1. How RIFToken Works Card
                    _buildHowRifTokenWorksCard(isDark),
                    const SizedBox(height: 20),

                    // 2. Stats & Redeem Card (Jolly -> Berekete)
                    _buildRifTokenStatsCard(isDark, wallet),
                    const SizedBox(height: 20),

                    // 3. Level Roadmap (Jolly, Berekete, Odogwu, Baller, Chairman)
                    _buildLevelRoadmapCard(isDark),
                  ] else ...[
                    // --- TAB 2: LEADERBOARD (Matches Screenshot 3) ---
                    _buildSectionHeader(
                      icon: Icons.emoji_events_outlined,
                      title: 'LEADERBOARD',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),

                    // Top Earners Card
                    _buildLeaderboardTab(isDark),
                  ],

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. TOP TABS: Referral Hub | RIFToken | Leaderboard
  Widget _buildTopTabs(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(0, 'Referral Hub', Icons.people_outline_rounded, isDark),
          _buildTabButton(1, 'RIFToken', Icons.bookmark_outline_rounded, isDark),
          _buildTabButton(2, 'Leaderboard', Icons.emoji_events_outlined, isDark),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. SUBTITLE HEADER WITH DYNAMIC ICON & TITLE
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 0: REFERRAL HUB COMPONENTS (Screenshots 1 & 2)
  // -------------------------------------------------------------

  Widget _buildReferAndEarnCard(bool isDark, String referralLink, {required String avoId}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkCardVariant, AppColors.darkCard],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232D48) : const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 14, color: AppColors.electricCyan),
                const SizedBox(width: 6),
                Text(
                  'Referral Program',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Title & Subtitle
          Text(
            'Refer & Earn',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Earn money for life on every referral transaction, plus extra commission on their first funding',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
          const SizedBox(height: 22),

          // YOUR UNIQUE AVOTEK ID BOX
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR AVOTEK ID (LOGIN & REFERRAL ID)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Unique ID',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0E18) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF222C42) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, size: 18, color: AppColors.primaryCyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    avoId,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(avoId),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy ID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E263C) : Colors.white,
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF2C3854) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // YOUR LINK INPUT BOX (Matches exact layout in Screenshot 2)
          Text(
            'YOUR LINK',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0E18) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF222C42) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    referralLink,
                    style: GoogleFonts.firaCode(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(referralLink),
                  icon: Icon(_copied ? Icons.check : Icons.copy_rounded, size: 15),
                  label: Text(_copied ? 'Copied' : 'Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // SHARE VIA PILLS
          Row(
            children: [
              Text(
                'Share via:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSharePill(
                      isDark,
                      label: 'WhatsApp',
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => _shareOnPlatform('whatsapp', referralLink),
                    ),
                    _buildSharePill(
                      isDark,
                      label: 'Twitter',
                      icon: Icons.tag_rounded,
                      onTap: () => _shareOnPlatform('twitter', referralLink),
                    ),
                    _buildSharePill(
                      isDark,
                      label: 'Facebook',
                      icon: Icons.public_rounded,
                      onTap: () => _shareOnPlatform('facebook', referralLink),
                    ),
                    _buildSharePill(
                      isDark,
                      label: 'More',
                      icon: Icons.share_outlined,
                      onTap: () => _shareOnPlatform('more', referralLink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSharePill(
    bool isDark, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E263C) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF2C3854) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isDark ? Colors.white70 : const Color(0xFF334155)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowNetworkCard(bool isDark, String referralLink) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222C42) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow your network',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Each referral earns you lifetime commission',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _copyToClipboard(referralLink),
            icon: const Icon(Icons.send_rounded, size: 14),
            label: const Text('Invite Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222C42) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;
              if (isNarrow) {
                return Column(
                  children: [
                    _buildStepItem(1, 'Share your link', 'Send your unique referral link to friends, family, or social media', isDark),
                    const SizedBox(height: 14),
                    _buildStepItem(2, 'Friend signs up', 'They register on Avotek.ng using your link', isDark),
                    const SizedBox(height: 14),
                    _buildStepItem(3, 'You earn', 'Earn lifetime commission plus RIFToken points from their purchases', isDark),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildStepItem(1, 'Share your link', 'Send your unique referral link to friends, family, or social media', isDark),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.black26),
                  ),
                  Expanded(
                    child: _buildStepItem(2, 'Friend signs up', 'They register on Avotek.ng using your link', isDark),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.black26),
                  ),
                  Expanded(
                    child: _buildStepItem(3, 'You earn', 'Earn lifetime commission plus RIFToken points from their purchases', isDark),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, String title, String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThreeStatCards(bool isDark, WalletProvider wallet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;
        final cards = [
          _buildStatCard(
            title: 'TOTAL EARNINGS',
            value: '₦0',
            icon: Icons.trending_up_rounded,
            iconBg: const Color(0xFF059669).withValues(alpha: 0.15),
            iconColor: const Color(0xFF10B981),
            isDark: isDark,
          ),
          _buildStatCard(
            title: 'AVAILABLE BALANCE',
            value: '₦0',
            icon: Icons.account_balance_wallet_rounded,
            iconBg: const Color(0xFF6366F1).withValues(alpha: 0.15),
            iconColor: const Color(0xFF818CF8),
            isDark: isDark,
          ),
          _buildStatCard(
            title: 'TOTAL REFERRALS',
            value: '0',
            icon: Icons.people_alt_rounded,
            iconBg: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
            iconColor: const Color(0xFF38BDF8),
            isDark: isDark,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222C42) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourReferralsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222C42) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Referrals',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF20293D) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D2130) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF3B2E1E) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'Referral points become '),
                        TextSpan(
                          text: 'withdrawable',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: ' once your referral completes KYC verification and spends a minimum of '),
                        TextSpan(
                          text: '₦1,000',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: ' on the platform.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 52,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                const SizedBox(height: 12),
                Text(
                  'No referrals yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share your referral link to start building your network!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: RIFTOKEN PROGRESS COMPONENTS (Screenshots 4 & 5)
  // -------------------------------------------------------------

  Widget _buildHowRifTokenWorksCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222C42) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.layers_rounded, color: AppColors.electricCyan, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How RIFToken Works',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your referrals earn you points when they make purchases on Avotek. Every data purchase by a referred user gives you 1 RIFToken point. Accumulate points to level up and unlock cash rewards of up to ₦6,000.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRifTokenStatsCard(bool isDark, WalletProvider wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222C42) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3 Column stats: CURRENT LEVEL, TOTAL POINTS, FROM REFERRALS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT LEVEL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF08A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFB45309)),
                          const SizedBox(width: 4),
                          Text(
                            'Jolly',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL POINTS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_userRifPoints pts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FROM REFERRALS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_userRifPoints pts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress Bar: Jolly -> Berekete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jolly → Berekete',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '0%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_userRifPoints / 201).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.electricCyan),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 pts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              Text(
                '201 pts to Berekete',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.electricCyan,
                ),
              ),
              Text(
                '100 pts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Big Button: Redeem Points for Cash
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openRedeemPointsModal(wallet),
              icon: const Icon(Icons.track_changes_rounded, size: 18),
              label: const Text('Redeem Points for Cash'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRoadmapCard(bool isDark) {
    final roadmapSteps = [
      {
        'title': 'Jolly',
        'isCurrent': true,
        'badge': 'You',
        'range': '0 – 200 pts',
        'bonus': null,
      },
      {
        'title': 'Berekete',
        'isCurrent': false,
        'badge': null,
        'range': '201 – 1,000 pts',
        'bonus': null,
      },
      {
        'title': 'Odogwu',
        'isCurrent': false,
        'badge': null,
        'range': '1,001 – 5,000 pts',
        'bonus': '+₦1,000 bonus',
      },
      {
        'title': 'Baller',
        'isCurrent': false,
        'badge': null,
        'range': '5,001 – 10,000 pts',
        'bonus': '+₦2,000 bonus',
      },
      {
        'title': 'Chairman',
        'isCurrent': false,
        'badge': null,
        'range': '10,001 – 20,000 pts',
        'bonus': '+₦3,000 bonus',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222C42) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Level Roadmap',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),

          // Stepper Timeline
          ...List.generate(roadmapSteps.length, (idx) {
            final step = roadmapSteps[idx];
            final isLast = idx == roadmapSteps.length - 1;
            final isCurrent = step['isCurrent'] == true;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dot and line column
                  Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFFFB800) : (isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0)),
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(color: const Color(0xFFFFD54F), width: 3)
                              : null,
                        ),
                        child: !isCurrent
                            ? Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: isDark ? Colors.white38 : Colors.black38,
                              )
                            : null,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Content column
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                step['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              if (step['badge'] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    step['badge'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            step['range'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                            ),
                          ),
                          if (step['bonus'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              step['bonus'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          // Footer note
          Text(
            'Level up to unlock 80% of your accumulated points as redeemable cash. At Chairman level, 100% unlocks.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: LEADERBOARD COMPONENTS (Screenshot 3)
  // -------------------------------------------------------------

  Widget _buildLeaderboardTab(bool isDark) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;

    // Only real users that actually exist on the system (mock names completely scrapped)
    final realEarners = <Map<String, dynamic>>[];
    if (currentUser != null && _userRifPoints > 0) {
      realEarners.add({
        'rank': 1,
        'name': currentUser.name.isNotEmpty ? currentUser.name : (currentUser.username ?? 'Avotek Member'),
        'initial': (currentUser.name.isNotEmpty ? currentUser.name[0] : 'A').toUpperCase(),
        'referrals': '${currentUser.referralCode} (${currentUser.avoId})',
        'badge': _userRifPoints >= 1000 ? 'Chairman' : (_userRifPoints >= 200 ? 'Berekete' : 'Jolly'),
        'badgeColor': _userRifPoints >= 1000 ? const Color(0xFF78350F) : Colors.white,
        'badgeBg': _userRifPoints >= 1000 ? const Color(0xFFFDE68A) : const Color(0xFF10B981),
        'points': '$_userRifPoints PTS',
        'isTopThree': true,
      });
    }

    final userReferralLink = 'https://avotek.ng/@${currentUser?.username ?? currentUser?.avoId ?? "user"}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222C42) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB800), size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Earners',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Real-time platform leaderboard for active Avotek affiliates",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (realEarners.isEmpty) ...[
            // Clean, genuine empty state when no referrals have earned points yet
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161C2C) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF252F47) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_outlined, color: Color(0xFFFFB800), size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Leaderboard Open for Champions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Text(
                      'No members have accumulated leaderboard points yet. Share your Avotek ID or referral link to earn points on every data recharge and take the #1 spot!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(userReferralLink),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Share My Referral Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // List of real earners
            ...realEarners.map((earner) {
              final isTopThree = earner['isTopThree'] as bool;
              final rank = earner['rank'] as int;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isTopThree
                      ? const Color(0xFFFEF08A)
                      : (isDark ? const Color(0xFF161C2C) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTopThree
                        ? const Color(0xFFFDE047)
                        : (isDark ? const Color(0xFF252F47) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: isTopThree
                          ? Icon(
                              rank == 1
                                  ? Icons.military_tech_rounded
                                  : (rank == 2 ? Icons.military_tech_outlined : Icons.emoji_events_outlined),
                              color: rank == 1
                                  ? const Color(0xFFB45309)
                                  : (rank == 2 ? const Color(0xFF475569) : const Color(0xFF92400E)),
                              size: 22,
                            )
                          : Text(
                              '$rank',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1E2438),
                      child: Text(
                        earner['initial'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            earner['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isTopThree
                                  ? const Color(0xFF0F172A)
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            earner['referrals'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isTopThree
                                  ? const Color(0xFF475569)
                                  : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: earner['badgeBg'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        earner['badge'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: earner['badgeColor'] as Color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      earner['points'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: isTopThree
                            ? const Color(0xFF0F172A)
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161C2C) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF252F47) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.rocket_launch_outlined, color: AppColors.electricCyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Keep earning points and climb the ranks on this leaderboard!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
