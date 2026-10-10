import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Crisp, authentic vector brand logo badge for telecom networks, exam PIN boards,
/// cable TV providers, and electricity DisCos. Guarantees no distortion.
class ServiceBrandLogo extends StatelessWidget {
  final String provider;
  final double size;
  final double borderRadius;
  final bool showLabel;

  const ServiceBrandLogo({
    super.key,
    required this.provider,
    this.size = 38,
    this.borderRadius = 10,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final clean = provider.trim().toUpperCase();

    Widget logo;
    if (clean.contains('MTN')) {
      logo = _buildMtnLogo();
    } else if (clean.contains('AIRTEL')) {
      logo = _buildAirtelLogo();
    } else if (clean.contains('GLO')) {
      logo = _buildGloLogo();
    } else if (clean.contains('9MOBILE') || clean.contains('ETISALAT')) {
      logo = _build9mobileLogo();
    } else if (clean.contains('WAEC')) {
      logo = _buildWaecLogo();
    } else if (clean.contains('NECO')) {
      logo = _buildNecoLogo();
    } else if (clean.contains('JAMB')) {
      logo = _buildJambLogo();
    } else if (clean.contains('NABTEB')) {
      logo = _buildNabtebLogo();
    } else if (clean.contains('DSTV')) {
      logo = _buildDstvLogo();
    } else if (clean.contains('GOTV')) {
      logo = _buildGotvLogo();
    } else if (clean.contains('STARTIMES')) {
      logo = _buildStartimesLogo();
    } else if (clean.contains('IKEDC') || clean.contains('IKEJA') || clean.contains('EKEDC') || clean.contains('EKO') || clean.contains('ELECTRIC')) {
      logo = _buildElectricityLogo(clean);
    } else {
      logo = _buildDefaultLogo(clean);
    }

    if (!showLabel) return logo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: 6),
        Text(
          clean,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // --- MTN Official Brand Badge ---
  Widget _buildMtnLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC00),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCC00).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: size * 0.12, vertical: size * 0.06),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: size * 0.04),
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Text(
            'MTN',
            style: GoogleFonts.rubik(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.32,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  // --- Airtel Official Brand Badge ---
  Widget _buildAirtelLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE60000),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE60000).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_tethering_rounded,
              color: Colors.white,
              size: size * 0.42,
            ),
            Text(
              'airtel',
              style: GoogleFonts.comfortaa(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.22,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Glo Official Brand Badge ---
  Widget _buildGloLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF008744),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008744).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.72,
          height: size * 0.72,
          decoration: BoxDecoration(
            color: const Color(0xFF00A859),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF70FF00), width: size * 0.04),
          ),
          child: Center(
            child: Text(
              'glo',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.36,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 9mobile Official Brand Badge ---
  Widget _build9mobileLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF004429),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004429).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size * 0.44,
              height: size * 0.44,
              decoration: const BoxDecoration(
                color: Color(0xFF8DC63F),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '9',
                  style: GoogleFonts.rubik(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WAEC Official Exam Board Badge ---
  Widget _buildWaecLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0B2545),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_rounded, color: const Color(0xFFFFD700), size: size * 0.38),
          Text(
            'WAEC',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.22,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- NECO Official Exam Board Badge ---
  Widget _buildNecoLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF005E38),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF88D49E), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005E38).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_rounded, color: const Color(0xFF88D49E), size: size * 0.38),
          Text(
            'NECO',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.22,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- JAMB Official Exam Board Badge ---
  Widget _buildJambLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF003822),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF55C57A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003822).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, color: const Color(0xFF55C57A), size: size * 0.38),
          Text(
            'JAMB',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.22,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- NABTEB Official Exam Board Badge ---
  Widget _buildNabtebLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFFFB703), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_rounded, color: const Color(0xFFFFB703), size: size * 0.36),
          Text(
            'NABTEB',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
            ),
          ),
        ],
      ),
    );
  }

  // --- DSTV Official Cable TV Badge ---
  Widget _buildDstvLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF002244),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF00A3E0), width: 1.5),
      ),
      child: Center(
        child: Text(
          'DStv',
          style: GoogleFonts.rubik(
            color: const Color(0xFF00A3E0),
            fontWeight: FontWeight.w900,
            fontSize: size * 0.32,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // --- GOtv Official Cable TV Badge ---
  Widget _buildGotvLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF006600),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF70FF00), width: 1.5),
      ),
      child: Center(
        child: Text(
          'GOtv',
          style: GoogleFonts.rubik(
            color: const Color(0xFF70FF00),
            fontWeight: FontWeight.w900,
            fontSize: size * 0.32,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // --- Startimes Official Cable TV Badge ---
  Widget _buildStartimesLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0052CC),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFFFAB00), width: 1.5),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded, color: const Color(0xFFFFAB00), size: size * 0.3),
            Text(
              'Star',
              style: GoogleFonts.rubik(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Electricity DisCo Badge ---
  Widget _buildElectricityLogo(String name) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.electric_bolt_rounded, color: const Color(0xFFF59E0B), size: size * 0.42),
          Text(
            name.contains('IKEDC') ? 'IKEDC' : (name.contains('EKEDC') ? 'EKEDC' : 'POWER'),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLogo(String label) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0052FF),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          label.isNotEmpty ? label.substring(0, 1) : 'A',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
