import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../supabase/supabase_service.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/about/about_screen.dart';
import '../../screens/affiliate/affiliate_screen.dart';
import '../../screens/auth/auth_callback_screen.dart';
import '../../screens/auth/app_lock_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/coupons/coupons_screen.dart';
import '../../screens/gifts/gifts_screen.dart';
import '../../screens/home/dashboard_screen.dart';
import '../../screens/landing/landing_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/password_recovery_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/rates/pricing_screen.dart';
import '../../screens/services/airtime_screen.dart';
import '../../screens/services/cable_screen.dart';
import '../../screens/services/data_screen.dart';
import '../../screens/services/esim_screen.dart';
import '../../screens/services/electricity_screen.dart';
import '../../screens/services/extra_provider_services_screen.dart';
import '../../screens/services/internet_screen.dart';
import '../../screens/services/pay_for_me_screen.dart';
import '../../screens/services/services_hub_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/stats/statistics_screen.dart';
import '../../screens/transactions/transactions_screen.dart';
import '../../screens/wallet/fund_wallet_screen.dart';
import '../../screens/wallet/wallet_screen.dart';
import '../../widgets/avotek_page_transition.dart';

String authenticatedHomeForEmail(String? email) =>
    UserModel.isAdminEmail(email) ? '/admin' : '/dashboard';

class AppRouter {
  static _AuthStateRefreshNotifier? _authRefreshNotifier;

  static GoRouter createRouter({VoidCallback? onToggleTheme}) {
    final themeToggle = onToggleTheme ?? () {};
    _authRefreshNotifier?.dispose();
    final authRefreshNotifier = _AuthStateRefreshNotifier();
    _authRefreshNotifier = authRefreshNotifier;
    final mobileUser = SupabaseService.instance.currentAuthUser;
    final initialMobileLocation =
        AppDatabaseService.instance.hasSeenOnboarding() || mobileUser != null
        ? '/login'
        : '/onboarding';
    return GoRouter(
      initialLocation: kIsWeb ? '/' : initialMobileLocation,
      refreshListenable: authRefreshNotifier,
      redirect: (context, state) {
        final path = state.matchedLocation;
        final hasSession = SupabaseService.instance.currentAuthUser != null;
        final auth = context.read<AuthProvider>();
        final currentUser = auth.user;
        final currentUserEmail =
            currentUser?.email ??
            SupabaseService.instance.currentAuthUser?.email;
        final isAdmin =
            currentUser?.isAdmin ?? UserModel.isAdminEmail(currentUserEmail);

        // Protected routes that unconditionally require authentication
        const protectedRoutes = [
          '/admin',
          '/dashboard',
          '/wallet',
          '/services',
          '/transactions',
          '/history',
          '/profile',
          '/settings',
          '/about',
          '/coupons',
          '/gifts',
          '/affiliate',
          '/stats',
          '/app-lock',
        ];

        final isProtected = protectedRoutes.any(
          (r) => path == r || path.startsWith('$r/'),
        );

        if (isProtected && !hasSession) {
          if (path == '/coupons') {
            final code = state.uri.queryParameters['code'];
            if (code != null && code.trim().isNotEmpty) {
              final returnTo = Uri(
                path: '/coupons',
                queryParameters: {'code': code.trim()},
              ).toString();
              return Uri(
                path: '/login',
                queryParameters: {'returnTo': returnTo},
              ).toString();
            }
          }
          return '/login';
        }

        if (path == '/admin' && (!hasSession || !isAdmin)) {
          return hasSession ? '/dashboard' : '/login';
        }

        if (hasSession && (path == '/login' || path == '/register')) {
          final returnTo = state.uri.queryParameters['returnTo'];
          if (returnTo != null && returnTo.startsWith('/coupons?code=')) {
            return returnTo;
          }
          return authenticatedHomeForEmail(currentUserEmail);
        }

        if (hasSession && path == '/login-callback') {
          return authenticatedHomeForEmail(currentUserEmail);
        }

        if (hasSession && path == '/') {
          return authenticatedHomeForEmail(currentUserEmail);
        }

        if (hasSession && path == '/dashboard' && isAdmin) {
          return '/admin';
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
          path: '/pay',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            PayForMeScreen(
              reference: state.uri.queryParameters['ref'],
              serviceName: state.uri.queryParameters['service'],
              examCode: state.uri.queryParameters['exam'],
              quantity:
                  int.tryParse(state.uri.queryParameters['qty'] ?? '1') ?? 1,
              amount:
                  double.tryParse(state.uri.queryParameters['amt'] ?? '5250') ??
                  5250.0,
              recipient: state.uri.queryParameters['to'],
              note: state.uri.queryParameters['note'],
              status: state.uri.queryParameters['status'],
              onToggleTheme: themeToggle,
            ),
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
            if (kIsWeb) {
              return '/';
            }
            final currentUser = SupabaseService.instance.currentAuthUser;
            if (AppDatabaseService.instance.hasSeenOnboarding() ||
                currentUser != null) {
              return currentUser == null
                  ? '/login'
                  : authenticatedHomeForEmail(currentUser.email);
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
            LoginScreen(
              initialSignUp: false,
              returnTo: state.uri.queryParameters['returnTo'],
            ),
          ),
        ),
        GoRoute(
          path: '/app-lock',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            AppLockScreen(
              returnTo: state.uri.queryParameters['returnTo'],
            ),
          ),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            LoginScreen(
              initialSignUp: true,
              initialReferralCode: state.uri.queryParameters['ref'],
              returnTo: state.uri.queryParameters['returnTo'],
            ),
          ),
        ),
        GoRoute(
          path: '/reset-password',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const PasswordRecoveryScreen(),
          ),
        ),
        GoRoute(
          path: '/login-callback',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const AuthCallbackScreen(),
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
          path: '/admin',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const AdminDashboardScreen(),
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
            CouponsScreen(
              onToggleTheme: themeToggle,
              initialCode: state.uri.queryParameters['code'],
            ),
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
            StatisticsScreen(onToggleTheme: themeToggle),
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
        GoRoute(
          path: '/about',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            const AboutScreen(),
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
          path: '/services/esim',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            EsimScreen(onToggleTheme: themeToggle),
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
          path: '/services/exam-pins',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            ExtraProviderServicesScreen(
              service: ExtraProviderService.examPins,
              onToggleTheme: themeToggle,
            ),
          ),
        ),
        GoRoute(
          path: '/services/airtime-pins',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            ExtraProviderServicesScreen(
              service: ExtraProviderService.airtimePins,
              onToggleTheme: themeToggle,
            ),
          ),
        ),
        GoRoute(
          path: '/services/data-card',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            ExtraProviderServicesScreen(
              service: ExtraProviderService.dataCard,
              onToggleTheme: themeToggle,
            ),
          ),
        ),
        GoRoute(
          path: '/services/airtime-to-cash',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            ExtraProviderServicesScreen(
              service: ExtraProviderService.airtimeToCash,
              onToggleTheme: themeToggle,
            ),
          ),
        ),
        GoRoute(
          path: '/services/bulk-sms',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            ExtraProviderServicesScreen(
              service: ExtraProviderService.bulkSms,
              onToggleTheme: themeToggle,
            ),
          ),
        ),
        GoRoute(
          path: '/services/internet',
          pageBuilder: (context, state) => buildAvotekTransitionPage(
            context,
            state,
            InternetScreen(
              onToggleTheme: themeToggle,
            ),
          ),
        ),
      ],
    );
  }

  static void dispose() {
    _authRefreshNotifier?.dispose();
    _authRefreshNotifier = null;
  }
}

class _AuthStateRefreshNotifier extends ChangeNotifier {
  _AuthStateRefreshNotifier() {
    _subscription = SupabaseService.instance.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
