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
    } else if (clean.contains('IKEJA') || clean.contains('IKEDC')) {
      logo = _buildIkejaLogo();
    } else if (clean.contains('EKO') || clean.contains('EKEDC')) {
      logo = _buildEkoLogo();
    } else if (clean.contains('ABUJA') || clean.contains('AEDC')) {
      logo = _buildAbujaLogo();
    } else if (clean.contains('KANO') || clean.contains('KEDCO')) {
      logo = _buildKanoLogo();
    } else if (clean.contains('PORT HARCOURT') || clean.contains('PHED')) {
      logo = _buildPhedLogo();
    } else if (clean.contains('KADUNA') || clean.contains('KAEDCO')) {
      logo = _buildKadunaLogo();
    } else if (clean.contains('BENIN') || clean.contains('BEDC')) {
      logo = _buildBeninLogo();
    } else if (clean.contains('ABA') || clean.contains('APLE')) {
      logo = _buildAbaLogo();
    } else if (clean.contains('ELECTRIC') || clean.contains('DISCO') || clean.contains('POWER')) {
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
          style: GoogleFonts.figtree(
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
            style: GoogleFonts.figtree(
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
              style: GoogleFonts.figtree(
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
              style: GoogleFonts.figtree(
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
              width: size * 0.38,
              height: size * 0.38,
              decoration: const BoxDecoration(
                color: Color(0xFF8DC63F),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '9',
                  style: GoogleFonts.figtree(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.28,
                  ),
                ),
              ),
            ),
            SizedBox(width: size * 0.04),
            Text(
              '9mobile',
              style: GoogleFonts.figtree(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.17,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WAEC Official Exam Board Logo ---
  Widget _buildWaecLogo() {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF0F9D58).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/brands/waec.png',
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Center(
          child: Text(
            'WAEC',
            style: GoogleFonts.figtree(
              color: const Color(0xFF0F9D58),
              fontWeight: FontWeight.w900,
              fontSize: size * 0.22,
            ),
          ),
        ),
      ),
    );
  }

  // --- NECO Official Exam Board Logo ---
  Widget _buildNecoLogo() {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF0052FF).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/brands/neco.png',
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Center(
          child: Text(
            'NECO',
            style: GoogleFonts.figtree(
              color: const Color(0xFF0052FF),
              fontWeight: FontWeight.w900,
              fontSize: size * 0.22,
            ),
          ),
        ),
      ),
    );
  }

  // --- JAMB Official Exam Board Badge ---
  Widget _buildJambLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF004D25), // Official JAMB Forest Green
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5), // Gold Accent
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D25).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/brands/jamb.png',
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_rounded, color: const Color(0xFFFFD700), size: size * 0.38),
            Text(
              'JAMB',
              style: GoogleFonts.figtree(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.22,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NABTEB Official Exam Board Logo ---
  Widget _buildNabtebLogo() {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF8B0000).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/brands/nabteb.png',
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Center(
          child: Text(
            'NABTEB',
            style: GoogleFonts.figtree(
              color: const Color(0xFF8B0000),
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
            ),
          ),
        ),
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
          style: GoogleFonts.figtree(
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
          style: GoogleFonts.figtree(
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
              style: GoogleFonts.figtree(
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

  // --- Ikeja Electric (IKEDC) Official DisCo Badge ---
  Widget _buildIkejaLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626), // Ikeja Electric Vibrant Red
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.44),
          Text(
            'IKEJA',
            style: GoogleFonts.figtree(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- Eko Electricity (EKEDC) Official DisCo Badge ---
  Widget _buildEkoLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0D3B66), // EKEDC Deep Navy
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF2EC4B6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3B66).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flash_on_rounded, color: const Color(0xFF2EC4B6), size: size * 0.44),
          Text(
            'EKEDC',
            style: GoogleFonts.figtree(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- Abuja Electricity (AEDC) Official DisCo Badge ---
  Widget _buildAbujaLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF003F88), // AEDC Royal Blue
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFFFD166), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003F88).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_rounded, color: const Color(0xFFFFD166), size: size * 0.44),
          Text(
            'AEDC',
            style: GoogleFonts.figtree(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- Kano Electricity (KEDCO) Official DisCo Badge ---
  Widget _buildKanoLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF7B1113), // KEDCO Maroon
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFFFB703), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.electric_bolt_rounded, color: const Color(0xFFFFB703), size: size * 0.44),
          Text(
            'KEDCO',
            style: GoogleFonts.figtree(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- Port Harcourt Electricity (PHED) Official DisCo Badge ---
  Widget _buildPhedLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7), // PHED Sky/Ocean Blue
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF4ADE80), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.energy_savings_leaf_rounded, color: const Color(0xFF4ADE80), size: size * 0.4),
          Text(
            'PHED',
            style: GoogleFonts.figtree(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- Kaduna Electricity (KAEDCO) Official DisCo Badge ---
  Widget _buildKadunaLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF047857), // KAEDCO Deep Green
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.power_rounded, color: const Color(0xFFFDE047), size: size * 0.4),
          Text(
            'KAEDCO',
            style: GoogleFonts.figtree(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.17,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // --- Benin Electricity (BEDC) Official DisCo Badge ---
  Widget _buildBeninLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF15803D), // BEDC Green
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFEAB308), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.offline_bolt_rounded, color: const Color(0xFFEAB308), size: size * 0.44),
          Text(
            'BEDC',
            style: GoogleFonts.figtree(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- Aba Power (APLE) Official DisCo Badge ---
  Widget _buildAbaLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF312E81), // APLE Indigo
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFF97316), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_rounded, color: const Color(0xFFF97316), size: size * 0.44),
          Text(
            'ABA',
            style: GoogleFonts.figtree(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
            style: GoogleFonts.figtree(
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
          style: GoogleFonts.figtree(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
