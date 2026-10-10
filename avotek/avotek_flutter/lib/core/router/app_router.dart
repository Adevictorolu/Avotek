import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../database/app_database.dart';
import '../supabase/supabase_service.dart';
import '../../screens/affiliate/affiliate_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/coupons/coupons_screen.dart';
import '../../screens/gifts/gifts_screen.dart';
import '../../screens/home/dashboard_screen.dart';
import '../../screens/landing/landing_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/rates/pricing_screen.dart';
import '../../screens/services/airtime_screen.dart';
import '../../screens/services/cable_screen.dart';
import '../../screens/services/data_screen.dart';
import '../../screens/services/electricity_screen.dart';
import '../../screens/services/services_hub_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/transactions/transactions_screen.dart';
import '../../screens/wallet/fund_wallet_screen.dart';
import '../../screens/wallet/wallet_screen.dart';
import '../../widgets/avotek_page_transition.dart';

class AppRouter {
  static GoRouter createRouter({VoidCallback? onToggleTheme}) {
    final themeToggle = onToggleTheme ?? () {};
    final bool hasSeenOnboarding = AppDatabaseService.instance.hasSeenOnboarding();

    return GoRouter(
      initialLocation: (kIsWeb || hasSeenOnboarding) ? '/' : '/onboarding',
      redirect: (context, state) {
        final path = state.matchedLocation;
        final hasSession = SupabaseService.instance.currentAuthUser != null ||
            AppDatabaseService.instance.getCachedSessionUser() != null;

        // Protected routes that unconditionally require authentication
        const protectedRoutes = [
          '/dashboard',
          '/wallet',
          '/services',
          '/transactions',
          '/history',
          '/profile',
          '/settings',
          '/coupons',
          '/gifts',
          '/affiliate',
          '/stats',
        ];

        final isProtected = protectedRoutes.any((r) => path == r || path.startsWith('$r/'));

        if (isProtected && !hasSession) {
          return '/login';
        }

        if (hasSession && (path == '/login' || path == '/register')) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) {
            if (!kIsWeb) {
              final hasSeen = AppDatabaseService.instance.hasSeenOnboarding();
              return hasSeen ? '/login' : '/onboarding';
            }
            return null;
          },
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            LandingScreen(onToggleTheme: themeToggle),
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
          path: '/services',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            ServicesHubScreen(onToggleTheme: themeToggle),
          ),
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            TransactionsScreen(onToggleTheme: themeToggle),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            TransactionsScreen(onToggleTheme: themeToggle),
          ),
        ),
        GoRoute(
          path: '/onboarding',
          redirect: (context, state) {
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
            DashboardScreen(onToggleTheme: themeToggle),
          ),
        ),
        GoRoute(
          path: '/wallet',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            WalletScreen(onToggleTheme: themeToggle),
          ),
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
          path: '/coupons',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            CouponsScreen(onToggleTheme: themeToggle),
          ),
        ),
        GoRoute(
          path: '/gifts',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            GiftsScreen(onToggleTheme: themeToggle),
          ),
        ),
        GoRoute(
          path: '/affiliate',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            AffiliateScreen(onToggleTheme: themeToggle),
          ),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            AffiliateScreen(onToggleTheme: themeToggle),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            ProfileScreen(onToggleTheme: themeToggle),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            SettingsScreen(onToggleTheme: themeToggle),
          ),
        ),
        // Core VTU Services
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
      ],
    );
  }
}
