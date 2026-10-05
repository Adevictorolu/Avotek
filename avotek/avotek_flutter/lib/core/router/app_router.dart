import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_gateway_screen.dart';
import '../../screens/admin/admin_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/dashboard_screen.dart';
import '../../screens/landing/landing_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/profile/student_profile_screen.dart';
import '../../screens/rates/pricing_screen.dart';
import '../../screens/services/airtime_screen.dart';
import '../../screens/services/cable_screen.dart';
import '../../screens/services/cac_screen.dart';
import '../../screens/services/data_screen.dart';
import '../../screens/services/electricity_screen.dart';
import '../../screens/transactions/transactions_screen.dart';
import '../../screens/wallet/fund_wallet_screen.dart';
import '../../screens/wallet/student_wallet_screen.dart';
import '../../widgets/avotek_page_transition.dart';

class AppRouter {
  static GoRouter createRouter({required VoidCallback onToggleTheme}) {
    final bool hasSeenOnboarding = AppDatabaseService.instance.hasSeenOnboarding();

    return GoRouter(
      // First-time mobile users get onboarding; once completed or on web, land directly on home
      initialLocation: (kIsWeb || hasSeenOnboarding) ? '/' : '/onboarding',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            LandingScreen(onToggleTheme: onToggleTheme),
          ),
        ),
        GoRoute(
          path: '/rates',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const PricingScreen(),
          ),
        ),
        GoRoute(
          path: '/pricing',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const PricingScreen(),
          ),
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const TransactionsScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const TransactionsScreen(),
          ),
        ),
        GoRoute(
          path: '/onboarding',
          redirect: (context, state) {
            // Once seen, never show onboarding again
            if (AppDatabaseService.instance.hasSeenOnboarding()) {
              return '/';
            }
            return null;
          },
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const OnboardingScreen(),
          ),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const LoginScreen(initialSignUp: false),
          ),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const LoginScreen(initialSignUp: true),
          ),
        ),
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            DashboardScreen(onToggleTheme: onToggleTheme),
          ),
        ),
        GoRoute(
          path: '/wallet',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            StudentWalletScreen(onToggleTheme: onToggleTheme),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            StudentProfileScreen(onToggleTheme: onToggleTheme),
          ),
        ),
        GoRoute(
          path: '/services/airtime',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const AirtimeScreen(),
          ),
        ),
        GoRoute(
          path: '/services/data',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const DataScreen(),
          ),
        ),
        GoRoute(
          path: '/services/electricity',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const ElectricityScreen(),
          ),
        ),
        GoRoute(
          path: '/services/tv',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const CableScreen(),
          ),
        ),
        GoRoute(
          path: '/services/cac',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const CacScreen(),
          ),
        ),
        // Betting is removed from offered services
        GoRoute(
          path: '/services/betting',
          redirect: (context, state) => '/dashboard',
        ),
        GoRoute(
          path: '/wallet/fund',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const FundWalletScreen(),
          ),
        ),
        GoRoute(
          path: '/admin-portal',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const AdminGatewayScreen(),
          ),
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
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const AdminScreen(),
          ),
        ),
      ],
    );
  }
}
