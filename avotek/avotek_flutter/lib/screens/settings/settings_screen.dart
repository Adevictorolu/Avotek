import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification_preferences.dart';
import '../../widgets/logout_dialog.dart';
import '../../widgets/top_notification.dart';
import '../../core/utils/legal_content.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const SettingsScreen({super.key, this.onToggleTheme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _whatsAppSupportNumber = '2348167002789';
  late NotificationPreferences _notificationPreferences;
  bool _savingNotificationPreferences = false;
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    _notificationPreferences = SupabaseService.instance
        .getNotificationPreferences();
  }

  Future<void> _saveNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    setState(() => _savingNotificationPreferences = true);
    try {
      await SupabaseService.instance.saveNotificationPreferences(preferences);
      if (!mounted) return;
      setState(() => _notificationPreferences = preferences);
      TopNotification.showSuccess(context, 'Notification settings saved.');
    } catch (error) {
      debugPrint('Saving notification preferences failed: $error');
      if (!mounted) return;
      TopNotification.showError(
        context,
        'Could not save notification settings. Try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _savingNotificationPreferences = false);
      }
    }
  }

  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.https('wa.me', '/$_whatsAppSupportNumber', {
      'text': 'Hello Avotek Support, I need help with my account.',
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Please try again later.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showTermsOfService() {
    AvotekLegalContent.showLegalDialog(
      context,
      title: 'Terms of Service',
      sections: AvotekLegalContent.termsOfService,
    );
  }

  void _showPrivacyPolicy() {
    AvotekLegalContent.showLegalDialog(
      context,
      title: 'Privacy Policy',
      sections: AvotekLegalContent.privacyPolicy,
    );
  }

  // --- MODAL: CHANGE / RESET TRANSACTION PIN (Matches Screenshots 1, 2, 5) ---
  void _openChangePinDialog() {
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();

    int activePinTab = 0; // 0: Change PIN, 1: Reset PIN
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: isDark ? Colors.white70 : Colors.black54,
                            onPressed: () => Navigator.pop(ctx),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppColors.darkCardVariant
                                  : AppColors.lightCardVariant,
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),

                      // Top Lock Icon inside Avotek cyan circular avatar
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryCyan.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.primaryCyan.withValues(
                              alpha: 0.35,
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.electricCyan.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            color: AppColors.electricCyan,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title & Subtitle (Dynamic based on tab)
                      Text(
                        activePinTab == 0
                            ? 'Change Transaction PIN'
                            : 'Reset Transaction PIN',
                        style: GoogleFonts.figtree(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activePinTab == 0
                            ? 'Update your 4-digit transaction PIN'
                            : 'Request OTP to reset your forgotten PIN',
                        style: GoogleFonts.figtree(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFA5B0CD)
                              : AppColors.slateGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),

                      // Segmented Control Tabs (Change PIN | Reset PIN)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardVariant
                              : AppColors.lightCardVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setDialogState(() => activePinTab = 0),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: activePinTab == 0
                                        ? AppColors.primaryBlue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: activePinTab == 0
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryBlue
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Change PIN',
                                      style: GoogleFonts.figtree(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: activePinTab == 0
                                            ? Colors.white
                                            : (isDark
                                                  ? AppColors.metallicLight
                                                  : AppColors.slateGrey),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setDialogState(() => activePinTab = 1),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: activePinTab == 1
                                        ? AppColors.primaryBlue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: activePinTab == 1
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryBlue
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Reset PIN',
                                      style: GoogleFonts.figtree(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: activePinTab == 1
                                            ? Colors.white
                                            : (isDark
                                                  ? AppColors.metallicLight
                                                  : AppColors.slateGrey),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Info callout under tabs
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardVariant
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.primaryCyan,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.figtree(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.metallicLight
                                        : const Color(0xFF0369A1),
                                  ),
                                  children: [
                                    const TextSpan(text: "Use "),
                                    TextSpan(
                                      text: "Reset PIN",
                                      style: GoogleFonts.figtree(
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const TextSpan(
                                      text: " if you've forgotten your old PIN",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- TAB 0: CHANGE PIN INPUTS ---
                      if (activePinTab == 0) ...[
                        _buildPinField(
                          label: 'Current PIN',
                          hint: 'Enter current PIN',
                          controller: currentPinCtrl,
                          obscure: obscureCurrent,
                          onToggleObscure: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent,
                          ),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildPinField(
                          label: 'New PIN',
                          hint: 'Enter 4-digit PIN',
                          controller: newPinCtrl,
                          obscure: obscureNew,
                          onToggleObscure: () =>
                              setDialogState(() => obscureNew = !obscureNew),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildPinField(
                          label: 'Confirm PIN',
                          hint: 'Re-enter PIN',
                          controller: confirmPinCtrl,
                          obscure: obscureConfirm,
                          onToggleObscure: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        // Security callout note
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardVariant
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.primaryCyan,
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: AppColors.electricCyan,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Keep your PIN secure! You'll need it to authorize all transactions.",
                                  style: GoogleFonts.figtree(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? AppColors.metallicLight
                                        : const Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Avotek Brand Action Button: Update PIN ✔
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              final currentPin = currentPinCtrl.text.trim();
                              final newPin = newPinCtrl.text.trim();
                              final confirmPin = confirmPinCtrl.text.trim();

                              if (newPin.length != 4 ||
                                  !RegExp(r'^\d{4}$').hasMatch(newPin)) {
                                TopNotification.showError(
                                  context,
                                  'New PIN must be exactly 4 digits.',
                                );
                                return;
                              }
                              if (newPin != confirmPin) {
                                TopNotification.showError(
                                  context,
                                  'New PINs do not match.',
                                );
                                return;
                              }

                              final auth = context.read<AuthProvider>();
                              // If user already has a PIN, verify current PIN first
                              if (!auth.needsPinSetup) {
                                if (currentPin.length != 4) {
                                  TopNotification.showError(
                                    context,
                                    'Enter your current 4-digit PIN.',
                                  );
                                  return;
                                }
                                final isValid = await auth.verifyPin(
                                  currentPin,
                                );
                                if (!isValid) {
                                  if (!mounted || !ctx.mounted) return;
                                  TopNotification.showError(
                                    context,
                                    'Current PIN is incorrect. Please try again.',
                                  );
                                  return;
                                }
                              }

                              final success = await auth.setTransactionPin(
                                newPin,
                              );
                              if (!mounted || !ctx.mounted) return;
                              if (success) {
                                Navigator.pop(ctx);
                                TopNotification.showSuccess(
                                  context,
                                  'Transaction PIN updated.',
                                );
                              } else {
                                TopNotification.showError(
                                  context,
                                  auth.errorMessage ??
                                      'Could not update transaction PIN.',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Update PIN',
                                  style: GoogleFonts.figtree(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.check_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // --- TAB 1: RESET PIN VIEW ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardVariant
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.primaryCyan,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Click the button below to receive a one-time password (OTP) via email. You\'ll use this to reset your PIN.',
                                  style: GoogleFonts.figtree(
                                    fontSize: 12.5,
                                    height: 1.45,
                                    color: isDark
                                        ? AppColors.metallicLight
                                        : const Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Avotek Brand Action Button: Send OTP to Email ✉
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'OTP sent to your registered email address.',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Send OTP to Email',
                                  style: GoogleFonts.figtree(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPinField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.figtree(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: GoogleFonts.figtree(
                      fontSize: 13,
                      color: isDark ? AppColors.slateGrey : Colors.black38,
                    ),
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: InkWell(
                  onTap: onToggleObscure,
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color: isDark ? AppColors.metallicLight : Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openChangePasswordDialog() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.lock_rounded,
                color: AppColors.primaryCyan,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Change Password',
                style: GoogleFonts.figtree(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                newPassCtrl.dispose();
                confirmPassCtrl.dispose();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final password = newPassCtrl.text;
                if (password.length < 6 || password != confirmPassCtrl.text) {
                  TopNotification.showError(
                    context,
                    'Enter a matching password with at least 6 characters.',
                  );
                  return;
                }

                final auth = context.read<AuthProvider>();
                final success = await auth.updatePassword(password);
                if (!mounted || !ctx.mounted) return;
                if (success) {
                  Navigator.pop(ctx);
                  newPassCtrl.dispose();
                  confirmPassCtrl.dispose();
                  TopNotification.showSuccess(
                    context,
                    'Password updated successfully.',
                  );
                } else {
                  TopNotification.showError(
                    context,
                    auth.errorMessage ?? 'Password update failed.',
                  );
                }
              },
              child: Text(
                'Save Password',
                style: GoogleFonts.figtree(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- MODAL: KYC VERIFICATION PROGRESS (Matches Screenshot 3) ---
  void _openKycVerificationModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Title, Subtitle, and Close (X)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Verify your account and enjoy\nunlimited transactions',
                          style: GoogleFonts.figtree(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your information is safe with us',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.metallicLight
                                : AppColors.slateGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: isDark ? Colors.white70 : Colors.black54,
                    onPressed: () => Navigator.pop(ctx),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkCardVariant
                          : AppColors.lightCardVariant,
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Progress Card Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardVariant
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'KYC Verification Progress',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '100%',
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
                    const SizedBox(height: 10),

                    // Full Avotek Cyan Progress Bar
                    Container(
                      height: 3,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.electricCyan,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.electricCyan.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4 Stepper Nodes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildKycStepNode('Liveness', isDark),
                        _buildKycStepNode('Profile', isDark),
                        _buildKycStepNode('Bank', isDark),
                        _buildKycStepNode('Validate', isDark),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // "Verification Under Review" Clock Card
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_rounded,
                    color: AppColors.electricCyan,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verification Under Review',
                style: GoogleFonts.figtree(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Your KYC verification has been submitted and is currently being reviewed. This usually takes a few minutes. You will be notified once your verification is complete.',
                  style: GoogleFonts.figtree(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark
                        ? AppColors.metallicLight
                        : AppColors.slateGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Callout Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardVariant
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.primaryCyan,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can close this modal and continue using the app. Your verification status will update automatically.',
                        style: GoogleFonts.figtree(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.metallicLight
                              : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKycStepNode(String title, bool isDark) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: Colors.white, size: 15),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.figtree(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.metallicLight : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // --- MODAL: UPGRADE TO CORPORATE ---
  void _openEditProfileModal(AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    final phoneCtrl = TextEditingController(text: auth.user?.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          title: Text(
            'Edit Profile Details',
            style: GoogleFonts.figtree(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final newName = nameCtrl.text.trim();
                final newPhone = phoneCtrl.text.trim();
                if (newName.isNotEmpty) {
                  auth.updateProfile(name: newName, phone: newPhone);
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text(
                'Save',
                style: GoogleFonts.figtree(fontWeight: FontWeight.w800),
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

    return ResponsiveShell(
      currentRoute: '/settings',
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

                  // Header: Settings - Manage your security, notifications, and preferences
                  Text(
                    'Settings',
                    style: GoogleFonts.figtree(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 1: ACCOUNT (Matches Screenshot 2) ---
                  _buildSectionContainer(
                    isDark: isDark,
                    icon: Icons.person_outline_rounded,
                    title: 'Account',
                    children: [
                      _buildSettingTile(
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                        iconBg: AppColors.success.withValues(alpha: 0.15),
                        title: 'Account Status (KYC)',
                        subtitle: null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Verified',
                            style: GoogleFonts.figtree(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        onTap: _openKycVerificationModal,
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildSettingTile(
                        icon: Icons.person_rounded,
                        iconColor: AppColors.primaryCyan,
                        iconBg: AppColors.primaryCyan.withValues(alpha: 0.15),
                        title: 'Edit Profile',
                        subtitle: null,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: () => _openEditProfileModal(auth),
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildSettingTile(
                        icon: Icons.people_outline_rounded,
                        iconColor: AppColors.electricCyan,
                        iconBg: AppColors.electricCyan.withValues(alpha: 0.15),
                        title: 'Affiliate Programme',
                        subtitle: null,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: () => context.go('/affiliate'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 2: SECURITY (Matches Screenshot 1 & 2) ---
                  _buildSectionContainer(
                    isDark: isDark,
                    icon: Icons.security_rounded,
                    title: 'Security',
                    children: [
                      _buildSettingTile(
                        icon: Icons.key_rounded,
                        iconColor: AppColors.primaryCyan,
                        iconBg: AppColors.primaryCyan.withValues(alpha: 0.15),
                        title: 'Change Transaction PIN',
                        subtitle: null,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: _openChangePinDialog,
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildSettingTile(
                        icon: Icons.lock_rounded,
                        iconColor: AppColors.primaryBlue,
                        iconBg: AppColors.primaryBlue.withValues(alpha: 0.15),
                        title: 'Change Password',
                        subtitle: null,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: _openChangePasswordDialog,
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildToggleTile(
                        icon: Icons.fingerprint_rounded,
                        title: 'Biometric Sign-In & Security',
                        badge: 'BIOMETRIC',
                        value: _biometricEnabled,
                        onChanged: (val) {
                          setState(() => _biometricEnabled = val);
                          TopNotification.showSuccess(
                            context,
                            val
                                ? 'Biometric authentication activated.'
                                : 'Biometric authentication disabled.',
                          );
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 3: APPEARANCE (Light & Dark Theme Sync) ---
                  _buildSectionContainer(
                    isDark: isDark,
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    children: [
                      _buildToggleTile(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: 'Dark Mode',
                        badge: isDark ? 'OBSIDIAN DARK' : 'SLATE LIGHT',
                        value: isDark,
                        onChanged: (_) {
                          context.read<ThemeProvider>().toggleTheme();
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 4: NOTIFICATIONS ---
                  _buildSectionContainer(
                    isDark: isDark,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    children: [
                      _buildToggleTile(
                        icon: Icons.phone_android_rounded,
                        title: 'In-app transaction alerts',
                        badge: 'IN APP',
                        value: _notificationPreferences.pushNotifications,
                        enabled: !_savingNotificationPreferences,
                        onChanged: (value) => _saveNotificationPreferences(
                          _notificationPreferences.copyWith(
                            pushNotifications: value,
                          ),
                        ),
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildToggleTile(
                        icon: Icons.mail_outline_rounded,
                        title: 'Email receipts',
                        badge: 'EMAIL',
                        value: _notificationPreferences.emailReceipts,
                        enabled: !_savingNotificationPreferences,
                        onChanged: (value) => _saveNotificationPreferences(
                          _notificationPreferences.copyWith(
                            emailReceipts: value,
                          ),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 5: HELP & SUPPORT ---
                  _buildSectionContainer(
                    isDark: isDark,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    children: [
                      _buildSettingTile(
                        icon: Icons.support_agent_rounded,
                        iconColor: AppColors.success,
                        iconBg: AppColors.success.withValues(alpha: 0.15),
                        title: 'WhatsApp Live Support',
                        subtitle: null,
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        onTap: _openWhatsAppSupport,
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildSettingTile(
                        icon: Icons.quiz_outlined,
                        iconColor: AppColors.electricCyan,
                        iconBg: AppColors.electricCyan.withValues(alpha: 0.15),
                        title: 'FAQs & Service Guides',
                        subtitle: null,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          // Trigger Avotek Help Modal
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tap the floating Help button at bottom-right for instant FAQs.',
                              ),
                              backgroundColor: AppColors.primaryBlue,
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 4: ABOUT (Matches Screenshot 1) ---
                  _buildSectionContainer(
                    isDark: isDark,
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    children: [
                      // App Version
                      _buildSettingTile(
                        icon: Icons.sell_outlined,
                        iconColor: isDark ? Colors.white70 : Colors.black87,
                        iconBg: Colors.transparent,
                        title: 'App Version',
                        subtitle: null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardVariant
                                : AppColors.lightCardVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'v2.00',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        onTap: null,
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      // Terms of Service
                      _buildSettingTile(
                        icon: Icons.description_outlined,
                        iconColor: isDark ? Colors.white70 : Colors.black87,
                        iconBg: Colors.transparent,
                        title: 'Terms of Service',
                        subtitle: null,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: _showTermsOfService,
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      // Privacy Policy
                      _buildSettingTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: isDark ? Colors.white70 : Colors.black87,
                        iconBg: Colors.transparent,
                        title: 'Privacy Policy',
                        subtitle: null,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: _showPrivacyPolicy,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 5: ACCOUNT SESSION (Sign Out) ---
                  _buildSectionContainer(
                    isDark: isDark,
                    icon: Icons.logout_rounded,
                    title: 'Account Session',
                    children: [
                      _buildSettingTile(
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.error,
                        iconBg: AppColors.error.withValues(alpha: 0.12),
                        title: 'Sign Out',
                        subtitle: null,
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.error,
                          size: 14,
                        ),
                        onTap: () async {
                          final confirmed = await showLogoutConfirmationDialog(
                            context,
                          );
                          if (confirmed && context.mounted) {
                            final auth = context.read<AuthProvider>();
                            await auth.signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          }
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Footer Copyright (Dynamic Year)
                  Center(
                    child: Text(
                      'avotek.com.ng Copyright 2023 - ${DateTime.now().year} By Avotek Technologies',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
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

  Widget _buildSectionContainer({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primaryCyan, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.figtree(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder,
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.figtree(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.figtree(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.metallicLight
                            : AppColors.slateGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String badge,
    String? warningNote,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.figtree(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badge == 'ACTIVE'
                      ? AppColors.success.withValues(alpha: 0.15)
                      : (isDark
                            ? AppColors.darkCardVariant
                            : AppColors.lightCardVariant),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.figtree(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: badge == 'ACTIVE'
                        ? AppColors.success
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              ),
              const Spacer(),
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primaryBlue,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: isDark
                    ? AppColors.darkCardVariant
                    : AppColors.lightCardVariant,
              ),
            ],
          ),
          if (warningNote != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  badge == 'ACTIVE'
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 12,
                  color: badge == 'ACTIVE'
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    warningNote,
                    style: GoogleFonts.figtree(
                      fontSize: 10.5,
                      color: badge == 'ACTIVE'
                          ? (isDark
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF15803D))
                          : (isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFB45309)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark
          ? AppColors.darkBorder.withValues(alpha: 0.5)
          : AppColors.lightBorder,
    );
  }
}
