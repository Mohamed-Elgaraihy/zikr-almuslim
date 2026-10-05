import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zikr_almuslim/app.dart';
import 'package:zikr_almuslim/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('morning counter counts down from the card', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(enableNotifications: false);
    await tester.runAsync(() => controller.bootstrap());
    await tester.pumpWidget(
      ZikrApp(controller: controller, enableTicker: false),
    );
    await tester.pump();

    expect(find.text('ذكر المسلم'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsWidgets);

    await tester.tap(find.text('أذكار الصباح').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final counter = find.byKey(const ValueKey('counter-morning-1'));
    expect(counter, findsOneWidget);
    expect(find.text('01'), findsWidgets);

    await tester.tap(counter);
    await tester.pump();

    expect(find.byIcon(Icons.check_rounded), findsWidgets);
    expect(controller.state.taps['morning:1'], 1);
  });
}
