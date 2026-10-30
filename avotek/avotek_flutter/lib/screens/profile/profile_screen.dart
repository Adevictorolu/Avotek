import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/logout_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const ProfileScreen({super.key, required this.onToggleTheme});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openEditProfileModal(BuildContext context, String currentName, String currentPhone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(
      text: currentPhone == 'Not configured' ? '' : currentPhone,
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep your name and Nigerian phone number up to date for fast service delivery and verification.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Victor Ademola',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 08167002799',
                    prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            if (name.isEmpty) {
                              TopNotification.showWarning(context, 'Please enter your full name.');
                              return;
                            }
                            setDialogState(() => isSaving = true);
                            try {
                              final auth = context.read<AuthProvider>();
                              await auth.updateProfile(
                                name: name,
                                phone: phone.isNotEmpty ? phone : null,
                              );
                              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                              if (context.mounted) {
                                TopNotification.showSuccess(context, 'Profile updated successfully!');
                              }
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (context.mounted) {
                                TopNotification.showError(context, 'Could not update profile: $e');
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
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

  void _openViewProfileModal(
    BuildContext context,
    String fullName,
    String email,
    String phone,
    bool isKycVerified,
    bool hasPhone,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'AV';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header: Title + Subtitle + Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your verified account information',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: isDark ? Colors.white70 : Colors.black54,
                      onPressed: () => Navigator.pop(ctx),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Center Avatar
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Centered Name
                Text(
                  fullName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Field 1: First Name
                _buildModalField(
                  icon: Icons.person_outline_rounded,
                  label: 'First Name',
                  isVerified: firstName.isNotEmpty,
                  value: firstName,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Field 2: Last Name
                _buildModalField(
                  icon: Icons.person_outline_rounded,
                  label: 'Last Name',
                  isVerified: lastName.isNotEmpty,
                  value: lastName.isNotEmpty ? lastName : '—',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Field 3: Phone Number
                _buildModalField(
                  icon: Icons.phone_android_rounded,
                  label: 'Phone Number',
                  isVerified: hasPhone && isKycVerified,
                  value: phone,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Field 4: Email Address
                _buildModalField(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email Address',
                  isVerified: true,
                  value: email,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Field 5: Account Tier & KYC
                _buildModalField(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Account Tier',
                  isVerified: isKycVerified,
                  value: isKycVerified ? 'Tier 2 (KYC Verified)' : 'Tier 1 (Standard User)',
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openEditProfileModal(context, fullName, phone);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Name & Phone Number'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildModalField({
    required IconData icon,
    required String label,
    required bool isVerified,
    required String value,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              const SizedBox(width: 8),
              if (isVerified) ...[
                const Icon(Icons.check_rounded, size: 13, color: AppColors.success),
                const SizedBox(width: 2),
                Text(
                  'Verified',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ] else ...[
                const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.warning),
                const SizedBox(width: 2),
                Text(
                  'Unverified',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDownloadApkModal() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String apkUrl = 'https://github.com/adevictorolu/Avotek/releases/latest/download/avotek.apk';
    String version = 'v1.2.0';

    try {
      final fetchedUrl = await SupabaseService.instance.getAppSetting('apk_download_url');
      if (fetchedUrl != null && fetchedUrl.trim().isNotEmpty) {
        apkUrl = fetchedUrl.trim();
      }
      final fetchedVer = await SupabaseService.instance.getAppSetting('apk_version');
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
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download Mobile App',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Official Android APK ($version)',
                    style: GoogleFonts.plusJakartaSans(
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
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Download the official Avotek mobile application directly to your Android device for lightning-fast recharge, biometric login, and push receipts.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
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
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
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
                        style: GoogleFonts.plusJakartaSans(
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
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: apkUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('APK download link copied to clipboard!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(
              'Copy Link',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _openNinVerificationModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ninCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
                  Icons.shield_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tier 2 KYC (NIN)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your 11-digit National Identity Number (NIN). This upgrades your account to Tier 2 with unlimited daily limits.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: ninCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                  decoration: InputDecoration(
                    labelText: 'National Identity Number (NIN)',
                    hintText: '11 digits (e.g. 12345678901)',
                    prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final clean = ninCtrl.text.replaceAll(RegExp(r'\D'), '');
                      if (clean.length != 11) {
                        TopNotification.showWarning(
                          context,
                          'National Identity Number must be exactly 11 digits.',
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        final auth = context.read<AuthProvider>();
                        await auth.submitNinKyc(clean);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          TopNotification.showSuccess(
                            context,
                            'Congratulations! Your account is now Tier 2 KYC Verified (NIN Active 🛡️).',
                            title: 'Tier 2 Verified',
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          TopNotification.showError(
                            context,
                            'Could not verify NIN: $e',
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Verify NIN',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    final user = auth.user;
    final fullName = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : (user?.email.split('@').first ?? 'Avotek Member');
    final email = (user?.email != null && user!.email.isNotEmpty)
        ? user.email
        : 'user@avotek.com';
    final rawPhone = user?.phone.trim() ?? '';
    final hasPhone = rawPhone.isNotEmpty && rawPhone != 'Not configured';
    final phone = hasPhone ? rawPhone : 'Not configured';
    final isKycVerified = (user?.kycStatus ?? '').toLowerCase() == 'verified' && hasPhone;
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'AV';

    return ResponsiveShell(
      currentRoute: '/profile',
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

                  // Header: Profile - Manage your personal information and account settings
                  Text(
                    'Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your personal information and account settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- CARD 1: USER PROFILE HEADER ---
                  _buildUserHeaderCard(isDark, fullName, email, phone, initials, isKycVerified, hasPhone),
                  const SizedBox(height: 20),

                  // --- CARD 2: DOWNLOAD OFFICIAL MOBILE APP (APK) ---
                  _buildDownloadApkCard(isDark),
                  const SizedBox(height: 20),

                  // --- CARD 3: VERIFICATION / KYC STATUS CARD ---
                  _buildKycStatusCard(isDark, fullName, email, phone, user, hasPhone),
                  const SizedBox(height: 24),

                  // --- CARD 4: SIGN OUT ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.error.withOpacity(0.35)),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign Out of Avotek',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Securely terminate your active session and return to sign-in.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await showLogoutConfirmationDialog(context);
                            if (confirmed && context.mounted) {
                              final auth = context.read<AuthProvider>();
                              await auth.signOut();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. USER PROFILE HEADER
  Widget _buildUserHeaderCard(
    bool isDark,
    String fullName,
    String email,
    String phone,
    String initials,
    bool isKycVerified,
    bool hasPhone,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circle avatar with edit tap
          InkWell(
            onTap: () => _openEditProfileModal(context, fullName, phone),
            borderRadius: BorderRadius.circular(40),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryCyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // User details & Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      tooltip: 'Edit name & phone',
                      onPressed: () => _openEditProfileModal(context, fullName, phone),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 14,
                      color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        email,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Badges row: Tier badge & Real KYC status badge
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_outline_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            isKycVerified ? 'Tier 2 Member' : 'Tier 1 (Standard)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isKycVerified
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isKycVerified
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isKycVerified ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 12,
                            color: isKycVerified ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isKycVerified ? 'KYC Verified' : (hasPhone ? 'KYC Pending' : 'KYC Unverified'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isKycVerified ? AppColors.success : AppColors.warning,
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
        ],
      ),
    );
  }

  // 2. DOWNLOAD OFFICIAL MOBILE APP (APK) PROMO CARD
  Widget _buildDownloadApkCard(bool isDark) {
    return InkWell(
      onTap: _showDownloadApkModal,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.5),
            width: 1.5,
          ),
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkCardVariant,
                    AppColors.darkCard,
                  ],
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Download Official Mobile App (APK)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const Icon(Icons.arrow_outward_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Get the official Avotek mobile application directly on your Android phone for ultra-fast transactions, biometric security, and push receipts.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTagPill('OFFICIAL ANDROID APK', isDark),
                _buildTagPill('FAST RECHARGE', isDark),
                _buildTagPill('PUSH RECEIPTS', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPill(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222B3F) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
    );
  }

  // 3. KYC STATUS / TIERED VERIFICATION CARD
  Widget _buildKycStatusCard(
    bool isDark,
    String fullName,
    String email,
    String phone,
    UserModel? user,
    bool hasPhone,
  ) {
    final isTier2 = user?.isTier2Verified ?? false;
    final isTier1 = isTier2 || (user?.isTier1Verified ?? hasPhone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTier2
              ? AppColors.success.withValues(alpha: 0.4)
              : (isTier1
                  ? const Color(0xFF0052FF).withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTier2
                    ? Icons.check_circle_rounded
                    : (isTier1
                        ? Icons.verified_user_rounded
                        : Icons.pending_actions_rounded),
                color: isTier2
                    ? AppColors.success
                    : (isTier1 ? const Color(0xFF0052FF) : AppColors.warning),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTier2
                      ? 'Tier 2 KYC Verified (NIN Verified 🛡️)'
                      : (isTier1
                          ? 'Tier 1 KYC Verified (Phone Active ✅)'
                          : 'Tier 0 (Phone Verification Required ⚠️)'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isTier2
                        ? AppColors.success
                        : (isTier1
                            ? (isDark ? Colors.white : const Color(0xFF0052FF))
                            : (isDark ? Colors.white : const Color(0xFF0F172A))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTier2
                ? 'Your identity, Nigerian phone number, and National Identity Number (NIN) have been fully verified. Enjoy maximum daily transaction limits.'
                : (isTier1
                    ? 'Your Nigerian phone number is recorded. Upgrade to Tier 2 by providing your 11-digit NIN for unlimited transactions and priority service.'
                    : 'Add your Nigerian phone number to complete Tier 1 KYC and activate automated transfer funding.'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons: Upgrade to Tier 2 / Update Phone / View Profile
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              if (!isTier2)
                ElevatedButton.icon(
                  onPressed: () => _openNinVerificationModal(context),
                  icon: const Icon(Icons.shield_rounded, size: 16),
                  label: const Text('Upgrade to Tier 2 (Add NIN)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () => _openEditProfileModal(context, fullName, phone),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: Text(hasPhone ? 'Update Phone' : 'Add Phone (Tier 1)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openViewProfileModal(
                  context,
                  fullName,
                  email,
                  phone,
                  isTier2,
                  hasPhone,
                ),
                icon: const Icon(Icons.person_outline_rounded, size: 16),
                label: const Text('View Profile'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
