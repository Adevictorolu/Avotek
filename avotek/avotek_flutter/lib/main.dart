import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/client/client_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/vtu_provider.dart';
import 'providers/wallet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ClientProvider.initialize();

  runApp(const AvotekApp());
}

class AvotekApp extends StatefulWidget {
  const AvotekApp({super.key});

  @override
  State<AvotekApp> createState() => _AvotekAppState();
}

class _AvotekAppState extends State<AvotekApp> {
  ThemeMode _themeMode =
      ThemeMode.dark; // Default to sleek dark mode matching the logo

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(client: ClientProvider.client),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(client: ClientProvider.client),
        ),
        ChangeNotifierProvider(
          create: (_) => VtuProvider(client: ClientProvider.client),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Avotek - Virtual Top-Up',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode,
        routerConfig: AppRouter.createRouter(onToggleTheme: _toggleTheme),
      ),
    );
  }
}
