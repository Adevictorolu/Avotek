import 'package:avotek_flutter/providers/auth_provider.dart';
import 'package:avotek_flutter/providers/wallet_provider.dart';
import 'package:avotek_flutter/screens/services/services_hub_screen.dart';
import 'package:avotek_flutter/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _StubAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? get user => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
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
