import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OnboardingPinDialog extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingPinDialog({super.key, required this.onCompleted});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OnboardingPinDialog(
        onCompleted: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<OnboardingPinDialog> createState() => _OnboardingPinDialogState();
}

class _OnboardingPinDialogState extends State<OnboardingPinDialog> {
  int _currentStep = 0; // 0: Quick Tour, 1: Create PIN
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _errorMessage = 'Transaction PIN must be exactly 4 digits.');
      return;
    }
    if (pin != confirmPin) {
      setState(() => _errorMessage = 'The two PIN entries do not match. Please re-enter.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.setTransactionPin(pin);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Security PIN successfully set! Your account is now fully active.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onCompleted();
      } else {
        setState(() => _errorMessage = 'Failed to save PIN. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? 'Valued User';

    return PopScope(
      canPop: false, // Must create PIN before accessing account
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14171E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFFD4AF37).withOpacity(0.3) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Brand Logo
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F1117) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      isDark ? 'assets/images/logo.png' : 'assets/images/logo_light.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $userName!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentStep == 0 ? 'Account Setup & Quick Guide' : 'Set Your 4-Digit Security PIN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFF26334D)),
              const SizedBox(height: 20),

              if (_currentStep == 0) ...[
                // STEP 0: ONBOARDING QUICK GUIDE
                Text(
                  'How to use your Avotek Account:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                _buildGuideTile(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFFD4AF37),
                  title: '1. Fund Your Wallet Instantly',
                  description: 'Transfer directly to your dedicated virtual account number shown on the dashboard. Wallet credits in seconds.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildGuideTile(
                  icon: Icons.wifi_rounded,
                  iconColor: AppColors.primaryCyan,
                  title: '2. Buy Data & Airtime at Wholesale Rates',
                  description: 'Select MTN, Glo, Airtel, or 9mobile, choose your plan, and enter your 4-digit PIN for instant top-up.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildGuideTile(
                  icon: Icons.chat_bubble_rounded,
                  iconColor: const Color(0xFF25D366),
                  title: '3. Buy Directly on WhatsApp',
                  description: 'Click the green banner to chat with Avotek automated bot on WhatsApp anytime.',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0A0E17),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to PIN Creation',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ] else ...[
                // STEP 1: CREATE 4-DIGIT PIN
                Text(
                  'Create your 4-digit transaction PIN:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This PIN protects your wallet and will be required to authorize every transaction.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
                const SizedBox(height: 20),

                // PIN Field
                Text(
                  '4-Digit PIN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm PIN Field
                Text(
                  'Confirm 4-Digit PIN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSavePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0A0E17),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          'Save PIN & Access Dashboard',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
}
