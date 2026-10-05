import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zikr_almuslim/app.dart';
import 'package:zikr_almuslim/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch explains the app, then opens the wird', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(enableNotifications: false);
    await tester.runAsync(() => controller.bootstrap());
    await tester.pumpWidget(
      ZikrApp(controller: controller, enableTicker: false),
    );
    await tester.pump();

    expect(find.text('عدّ بلمسة واحدة'), findsNothing);
    expect(find.text('التالي'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('عدّ بلمسة واحدة'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ابدأ الورد'), findsOneWidget);

    await tester.tap(find.text('ابدأ الورد'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.state.onboardingSeen, isTrue);
    expect(find.text('أذكار الصباح'), findsWidgets);
  });

  testWidgets('morning counter counts down from the card', (tester) async {
    SharedPreferences.setMockInitialValues({
      'zikr_state_v1': '{"onboardingSeen":true,"day":"2026-10-05"}',
    });
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
