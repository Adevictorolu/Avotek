import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ServiceItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;

  const ServiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.borderColor,
  });
}

class QuickServiceGrid extends StatelessWidget {
  final void Function(String serviceId) onServiceSelected;

  const QuickServiceGrid({super.key, required this.onServiceSelected});

  static const List<ServiceItem> services = [
    ServiceItem(
      id: 'data',
      title: 'Data Bundle',
      subtitle: 'SME & Gifting',
      icon: Icons.wifi_rounded,
      color: Color(0xFF00A3FF),
      backgroundColor: Colors.white,
      borderColor: Color(0xFF00A3FF),
    ),
    ServiceItem(
      id: 'airtime',
      title: 'Airtime',
      subtitle: 'Instant Top-Up',
      icon: Icons.phone_android_rounded,
      color: Color(0xFF0284C7),
      backgroundColor: Colors.white,
      borderColor: Color(0xFF0284C7),
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
      id: 'airtime_cash',
      title: 'Airtime to Cash',
      subtitle: 'Instant Cash Out',
      icon: Icons.currency_exchange_rounded,
      color: Color(0xFF059669),
    ),
    ServiceItem(
      id: 'cac',
      title: 'CAC Register',
      subtitle: 'Biz Name & LTD',
      icon: Icons.corporate_fare_rounded,
      color: Color(0xFF6366F1),
    ),
    ServiceItem(
      id: 'print_card',
      title: 'Recharge PIN',
      subtitle: 'Print VTU Cards',
      icon: Icons.print_rounded,
      color: Color(0xFFEA580C),
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
        final cardBg = isDark
            ? (service.backgroundColor != null ? const Color(0xFF1E293B) : AppColors.darkCard)
            : (service.backgroundColor ?? AppColors.lightCard);

        final cardBorder = service.borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);

        return InkWell(
          onTap: () => onServiceSelected(service.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cardBorder,
                width: service.borderColor != null ? 1.5 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: cardBorder.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
