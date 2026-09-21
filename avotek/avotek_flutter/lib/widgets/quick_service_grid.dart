import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ServiceItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ServiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class QuickServiceGrid extends StatelessWidget {
  final void Function(String serviceId) onServiceSelected;

  const QuickServiceGrid({super.key, required this.onServiceSelected});

  static const List<ServiceItem> services = [
    ServiceItem(
      id: 'airtime',
      title: 'Airtime',
      subtitle: 'Instant Top-Up',
      icon: Icons.phone_android_rounded,
      color: Color(0xFF00A3FF),
    ),
    ServiceItem(
      id: 'data',
      title: 'Data Bundle',
      subtitle: 'SME & Gifting',
      icon: Icons.wifi_rounded,
      color: Color(0xFF10B981),
    ),
    ServiceItem(
      id: 'electricity',
      title: 'Electricity',
      subtitle: 'Prepaid Token',
      icon: Icons.bolt_rounded,
      color: Color(0xFFF59E0B),
    ),
    ServiceItem(
      id: 'tv',
      title: 'Cable TV',
      subtitle: 'DStv, GOtv',
      icon: Icons.tv_rounded,
      color: Color(0xFF8B5CF6),
    ),
    ServiceItem(
      id: 'exam_pin',
      title: 'Exam PINs',
      subtitle: 'WAEC, JAMB',
      icon: Icons.school_rounded,
      color: Color(0xFFEC4899),
    ),
    ServiceItem(
      id: 'cac',
      title: 'CAC Register',
      subtitle: 'Biz Name & LTD',
      icon: Icons.corporate_fare_rounded,
      color: Color(0xFF6366F1),
    ),
    ServiceItem(
      id: 'betting',
      title: 'Betting',
      subtitle: 'SportyBet, etc',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFF06B6D4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return InkWell(
          onTap: () => onServiceSelected(service.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: service.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    service.icon,
                    size: 22,
                    color: service.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  service.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
