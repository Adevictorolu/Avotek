import 'package:avotek_flutter/providers/auth_provider.dart';
import 'package:avotek_flutter/providers/vtu_provider.dart';
import 'package:avotek_flutter/providers/wallet_provider.dart';
import 'package:avotek_flutter/core/shell/responsive_shell.dart';
import 'package:avotek_flutter/screens/services/cable_screen.dart';
import 'package:avotek_flutter/screens/services/services_hub_screen.dart';
import 'package:avotek_flutter/models/user_model.dart';
import 'package:avotek_flutter/widgets/transaction_audit_dialog.dart';
import 'package:avotek_flutter/widgets/transaction_success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _StubAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? get user => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubVtuProvider extends VtuProvider {
  @override
  Future<List<Map<String, dynamic>>> fetchCablePackages(String provider) async {
    return [];
  }
}

void main() {
  testWidgets('subscription back button returns to the services hub', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/services/tv',
      routes: [
        GoRoute(
          path: '/services',
          builder: (context, state) =>
              const Scaffold(body: Text('Services hub')),
        ),
        GoRoute(
          path: '/services/tv',
          builder: (context, state) => const CableScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: _StubAuthProvider(),
          ),
          ChangeNotifierProvider<WalletProvider>.value(value: WalletProvider()),
          ChangeNotifierProvider<VtuProvider>.value(value: _StubVtuProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Services hub'), findsOneWidget);
    router.dispose();
  });

  testWidgets('subscription route activates only its sidebar item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: _StubAuthProvider(),
          ),
          ChangeNotifierProvider<WalletProvider>.value(value: WalletProvider()),
        ],
        child: const MaterialApp(
          home: ResponsiveShell(
            currentRoute: '/services/cable',
            child: Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    final services = tester.widget<Text>(find.text('Services'));
    final subscriptions = tester.widget<Text>(find.text('Subscriptions'));
    expect(services.style?.fontWeight, FontWeight.w600);
    expect(subscriptions.style?.fontWeight, FontWeight.w800);
  });

  testWidgets('transaction audit has no outer dialog border or elevation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => TransactionAuditDialog.show(context, const []),
              child: const Text('Open audit'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open audit'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    final shape = dialog.shape! as RoundedRectangleBorder;
    final dialogContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(dialog.elevation, 0);
    expect(shape.side.style, BorderStyle.none);
    expect(dialogContainer.decoration, isA<BoxDecoration>());
    expect(
      (dialogContainer.decoration! as BoxDecoration).boxShadow ?? [],
      isEmpty,
    );
  });

  testWidgets('receipt has no outer dialog border or elevation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => TransactionSuccessDialog.show(
                context,
                serviceType: 'Airtime',
                recipient: '08000000000',
                amount: 100,
              ),
              child: const Text('Open receipt'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open receipt'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    final shape = dialog.shape! as RoundedRectangleBorder;
    final dialogContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(dialog.elevation, 0);
    expect(shape.side.style, BorderStyle.none);
    expect(dialogContainer.decoration, isA<BoxDecoration>());
    expect(
      (dialogContainer.decoration! as BoxDecoration).boxShadow ?? [],
      isEmpty,
    );
  });

  testWidgets('desktop service list uses full-width rows without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: _StubAuthProvider(),
          ),
          ChangeNotifierProvider<WalletProvider>.value(value: WalletProvider()),
        ],
        child: MaterialApp(
          home: ServicesHubScreen(onToggleTheme: () {}),
        ),
      ),
    );

    await tester.tap(find.text('List view'));
    await tester.pumpAndSettle();

    final serviceGrid = tester.widget<GridView>(find.byType(GridView).first);
    final delegate =
        serviceGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 1);
    expect(delegate.mainAxisExtent, 76);
    expect(find.text('Buy Airtime'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
