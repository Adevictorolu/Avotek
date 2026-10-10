import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'avotek_logo.dart';

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
  // 0: Enter PIN (4 digits), 1: Confirm PIN (4 digits)
  int _step = 0;
  String _pin = '';
  String _firstPin = '';
  String? _errorMessage;
  bool _isSubmitting = false;

  void _appendDigit(String digit) {
    if (_isSubmitting) return;
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _handlePinEntered();
      }
    }
  }

  void _backspace() {
    if (_isSubmitting) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _handlePinEntered() {
    if (_step == 0) {
      // Step 0 completed: Save first PIN and proceed to confirmation
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _step = 1;
        _errorMessage = null;
      });
    } else {
      // Step 1 completed: Verify match
      if (_pin == _firstPin) {
        _submitPin(_pin);
      } else {
        setState(() {
          _errorMessage = 'PINs do not match. Please try again.';
          _pin = '';
          _firstPin = '';
          _step = 0;
        });
      }
    }
  }

  Future<void> _submitPin(String pin) async {
    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.setTransactionPin(pin);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      widget.onCompleted();
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? 'Failed to save PIN. Try again.';
        _pin = '';
        _firstPin = '';
        _step = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 380,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtle Top Brand Icon
              const Center(
                child: AvotekBrandAsset(
                  height: 38,
                  isDark: true,
                  hasFrame: true,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(height: 20),

              // Title & Subtitle
              Text(
                _step == 0 ? 'Create Transaction PIN' : 'Confirm Your PIN',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _step == 0
                    ? 'Enter a 4-digit security PIN to authorize transactions.'
                    : 'Re-enter your 4-digit security PIN to confirm.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),

              // 4 PIN Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    width: isFilled ? 18 : 16,
                    height: isFilled ? 18 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppColors.primaryCyan
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      border: Border.all(
                        color: isFilled
                            ? AppColors.primaryCyan
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        width: 1.5,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 26),

              // Clean Number Keypad
              if (_isSubmitting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: CircularProgressIndicator(color: AppColors.primaryCyan),
                )
              else
                _buildKeypad(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'DEL'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 72, height: 52);
              }

              if (key == 'DEL') {
                return InkWell(
                  onTap: _backspace,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 72,
                    height: 52,
                    child: Center(
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 22,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: () => _appendDigit(key),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 72,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF28354D) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    key,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
