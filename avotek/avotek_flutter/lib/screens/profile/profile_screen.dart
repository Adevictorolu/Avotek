import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/top_notification.dart';

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

  void _showOwnVtuWebsiteModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: AppColors.electricCyan),
            const SizedBox(width: 10),
            Text('Start Your Own VTU Business', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get a ready-made website connected to your account. Buy, launch, and start earning from ₦200,000.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• 100% White-Labeled with Your Domain', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('• 1 Year Premium Cloud Hosting Included', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('• Automated API Processing & Instant Wallet Funding', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Our VTU team will contact you shortly!'), backgroundColor: AppColors.success),
              );
            },
            child: Text('Order Portal (₦200,000)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
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

                  // --- CARD 2: START YOUR OWN VTU BUSINESS ---
                  _buildStartVtuBusinessCard(isDark),
                  const SizedBox(height: 20),

                  // --- CARD 3: VERIFICATION / KYC STATUS CARD ---
                  _buildKycStatusCard(isDark, fullName, email, phone, isKycVerified, hasPhone),
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
                            final auth = context.read<AuthProvider>();
                            await auth.signOut();
                            if (context.mounted) {
                              context.go('/login');
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

  // 2. START YOUR OWN VTU BUSINESS PROMO CARD
  Widget _buildStartVtuBusinessCard(bool isDark) {
    return InkWell(
      onTap: _showOwnVtuWebsiteModal,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryCyan.withValues(alpha: 0.5),
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
                    color: AppColors.electricCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: AppColors.electricCyan, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start Your Own VTU Business',
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
              'Get a ready-made website connected to your account. Buy, launch, and start earning - from ₦200,000.',
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
                _buildTagPill('WHITE-LABELED', isDark),
                _buildTagPill('1YR HOSTING', isDark),
                _buildTagPill('AUTO-PROCESS', isDark),
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

  // 3. KYC STATUS / VERIFICATION CARD
  Widget _buildKycStatusCard(
    bool isDark,
    String fullName,
    String email,
    String phone,
    bool isKycVerified,
    bool hasPhone,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isKycVerified
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isKycVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                color: isKycVerified ? AppColors.success : AppColors.warning,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                isKycVerified ? 'Fully KYC Verified' : (hasPhone ? 'KYC Under Review' : 'KYC Verification Required'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isKycVerified ? AppColors.success : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isKycVerified
                ? 'Your identity and Nigerian phone number have been verified successfully.'
                : (hasPhone
                    ? 'Your phone number is recorded. Our team verifies accounts in batches.'
                    : 'Add your phone number and complete your details to qualify for higher daily limits.'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons: Update Profile & View Profile
          Row(
            children: [
              if (!isKycVerified) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openEditProfileModal(context, fullName, phone),
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: const Text('Update Phone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openViewProfileModal(
                    context,
                    fullName,
                    email,
                    phone,
                    isKycVerified,
                    hasPhone,
                  ),
                  icon: const Icon(Icons.person_outline_rounded, size: 16),
                  label: const Text('View Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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
