import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/avotek_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? AppColors.metallicLight : AppColors.slateGrey;

    return ResponsiveShell(
      currentRoute: '/about',
      child: Container(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        child: SingleChildScrollView(
          padding: ResponsiveLayout.pagePadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'About Avotek',
                    style: GoogleFonts.figtree(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Technology that helps people move forward.',
                    style: GoogleFonts.figtree(fontSize: 14, color: muted),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0753D7), Color(0xFF08A9D6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AvotekLogo(
                          size: 38,
                          showText: true,
                          hasFrame: true,
                          borderRadius: 14,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Our mission',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Avotek is on a mission to leverage technology across Africa—helping Nigerian students and business owners build, scale, and process information at their core.',
                          style: GoogleFonts.figtree(
                            fontSize: 19,
                            height: 1.45,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What you can do with Avotek',
                          style: GoogleFonts.figtree(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _AboutFeature(
                          icon: Icons.phone_android_rounded,
                          title: 'Stay connected',
                          description:
                              'Buy airtime and data for yourself or someone else.',
                          color: const Color(0xFF0284C7),
                        ),
                        _AboutFeature(
                          icon: Icons.school_rounded,
                          title: 'Support your education',
                          description:
                              'Purchase exam e-PINs or share a sponsor link when you need help paying.',
                          color: const Color(0xFF7C3AED),
                        ),
                        _AboutFeature(
                          icon: Icons.receipt_long_rounded,
                          title: 'Manage everyday services',
                          description:
                              'Pay supported utility bills and keep your transactions together in one place.',
                          color: const Color(0xFF059669),
                        ),
                        _AboutFeature(
                          icon: Icons.people_alt_rounded,
                          title: 'Grow through referrals',
                          description:
                              'Invite others to Avotek and follow your referral activity.',
                          color: const Color(0xFFEA580C),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We aim to make useful digital services clear, accessible, and dependable for the people and businesses that rely on them.',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            height: 1.55,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.push('/services/exam-pins'),
                        icon: const Icon(Icons.school_rounded, size: 18),
                        label: const Text('Explore exam PINs'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/affiliate'),
                        icon: const Icon(Icons.people_alt_rounded, size: 18),
                        label: const Text('Referral programme'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.figtree(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark
                        ? AppColors.metallicLight
                        : AppColors.slateGrey,
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
