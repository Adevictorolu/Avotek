import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/app_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/vtu_provider.dart';
import 'providers/wallet_provider.dart';
import 'core/supabase/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.instance.initialize();
  await AppDatabaseService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => VtuProvider()),
      ],
      child: const AvotekApp(),
    ),
  );
}

class AvotekApp extends StatefulWidget {
  const AvotekApp({super.key});

  @override
  State<AvotekApp> createState() => _AvotekAppState();
}

class _AvotekAppState extends State<AvotekApp> {
  late final _router = AppRouter.createRouter(
    onToggleTheme: () => context.read<ThemeProvider>().toggleTheme(),
  );

  @override
  void dispose() {
    _router.dispose();
    AppRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Avotek — Data, Airtime & Bill Payments',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
