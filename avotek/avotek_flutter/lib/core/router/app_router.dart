import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_gateway_screen.dart';
import '../../screens/admin/admin_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/community/community_screen.dart';
import '../../screens/home/dashboard_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/services/airtime_screen.dart';
import '../../screens/services/betting_screen.dart';
import '../../screens/services/cable_screen.dart';
import '../../screens/services/cac_screen.dart';
import '../../screens/services/data_screen.dart';
import '../../screens/services/electricity_screen.dart';
import '../../screens/services/exam_pin_screen.dart';
import '../../screens/wallet/fund_wallet_screen.dart';

class AppRouter {
  static GoRouter createRouter({required VoidCallback onToggleTheme}) {
    return GoRouter(
      // Web users get direct access with no splash screens; mobile users get onboarding
      initialLocation: kIsWeb ? '/login' : '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => DashboardScreen(onToggleTheme: onToggleTheme),
        ),
        GoRoute(
          path: '/services/airtime',
          builder: (context, state) => const AirtimeScreen(),
        ),
        GoRoute(
          path: '/services/data',
          builder: (context, state) => const DataScreen(),
        ),
        GoRoute(
          path: '/services/electricity',
          builder: (context, state) => const ElectricityScreen(),
        ),
        GoRoute(
          path: '/services/tv',
          builder: (context, state) => const CableScreen(),
        ),
        GoRoute(
          path: '/services/exam_pin',
          builder: (context, state) => const ExamPinScreen(),
        ),
        GoRoute(
          path: '/services/cac',
          builder: (context, state) => const CacScreen(),
        ),
        GoRoute(
          path: '/services/betting',
          builder: (context, state) => const BettingScreen(),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/wallet/fund',
          builder: (context, state) => const FundWalletScreen(),
        ),
        GoRoute(
          path: '/admin-portal',
          builder: (context, state) => const AdminGatewayScreen(),
        ),
        GoRoute(
          path: '/admin',
          redirect: (context, state) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (!auth.isSuperAdmin) {
              return '/admin-portal';
            }
            return null;
          },
          builder: (context, state) => const AdminScreen(),
        ),
      ],
    );
  }
}
