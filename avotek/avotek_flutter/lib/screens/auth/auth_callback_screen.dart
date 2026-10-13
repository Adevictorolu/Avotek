import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/supabase/supabase_service.dart';

class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  StreamSubscription? _authSubscription;
  Timer? _timeout;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = SupabaseService.instance.onAuthStateChange.listen(
      (state) {
        if (state.session != null ||
            SupabaseService.instance.currentAuthUser != null) {
          _openDashboard();
        }
      },
      onError: (_) => _showError(),
    );

    if (SupabaseService.instance.currentAuthUser != null) {
      _openDashboard();
    } else {
      _timeout = Timer(const Duration(seconds: 20), _showError);
    }
  }

  void _openDashboard() {
    if (!mounted) return;
    _timeout?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final email = SupabaseService.instance.currentAuthUser?.email ??
          SupabaseService.instance.currentSession?.user.email;
      final destination = authenticatedHomeForEmail(email);
      context.go(destination);
    });
  }

  void _showError() {
    if (!mounted) return;
    setState(() => _hasError = true);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_hasError) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    'Signing you in…',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We could not complete sign-in. Please check your Google '
                    'and Supabase redirect settings, then try again.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
