import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zikr_almuslim/app.dart';
import 'package:zikr_almuslim/logic/progress_logic.dart';
import 'package:zikr_almuslim/services/notification_service.dart';
import 'package:zikr_almuslim/state/app_controller.dart';

Finder get _verticalScroll => find.byWidgetPredicate(
  (widget) =>
      widget is Scrollable &&
      axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch explains the app, then opens the wird', (
    tester,
  ) async {
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
    expect(controller.library!.categories, hasLength(27));
    expect(controller.library!.byId('morning').items, hasLength(31));
    expect(controller.library!.byId('evening').items, hasLength(30));
    expect(controller.library!.byId('sleep').items, hasLength(15));
    expect(
      controller.library!.categories.map((category) => category.title),
      containsAll(['تسابيح', 'الرُّقية الشرعية', 'أسماء الله الحسنى']),
    );
  });

  testWidgets('the free sebha keeps its count', (tester) async {
    SharedPreferences.setMockInitialValues({
      'zikr_state_v1': '{"onboardingSeen":true,"day":"2026-10-05"}',
    });
    final controller = AppController(enableNotifications: false);
    await tester.runAsync(() => controller.bootstrap());
    await tester.pumpWidget(
      ZikrApp(controller: controller, enableTicker: false),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('open-sebha')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('٠'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('sebha-tap')));
    await tester.pump();
    expect(find.text('١'), findsWidgets);
    expect(controller.state.sebhaCount, 1);

    await tester.tap(find.text('٣٣'));
    await tester.pump();
    expect(controller.state.sebhaTarget, 33);
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
    await tester.scrollUntilVisible(
      counter,
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    expect(find.text('٠١'), findsWidgets);

    final copy = find.byTooltip('نسخ');
    expect(copy, findsWidgets);
    expect(tester.getSize(copy.first).shortestSide, greaterThanOrEqualTo(40));

    await tester.tap(counter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byIcon(Icons.check_rounded), findsWidgets);
    expect(find.text('تم'), findsWidgets);
    expect(controller.state.taps['morning:1'], 1);
  });

  testWidgets('onboarding dots start at the right in Arabic', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(enableNotifications: false);
    await tester.runAsync(() => controller.bootstrap());
    await tester.pumpWidget(
      ZikrApp(controller: controller, enableTicker: false),
    );
    await tester.pump();

    final first = tester.getCenter(
      find.byKey(const ValueKey('onboarding-dot-0')),
    );
    final last = tester.getCenter(
      find.byKey(const ValueKey('onboarding-dot-2')),
    );
    expect(first.dx, greaterThan(last.dx));
  });

  testWidgets('search normalizes Arabic, clears, and does not return focused', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'zikr_state_v1': '{"onboardingSeen":true,"day":"2026-10-05"}',
    });
    final controller = AppController(enableNotifications: false);
    await tester.runAsync(() => controller.bootstrap());
    await tester.pumpWidget(
      ZikrApp(controller: controller, enableTicker: false),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'صلاه');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('لا توجد أذكار مطابقة'), findsNothing);
    final prayer = find.text('أذكار الصلاة');
    await tester.scrollUntilVisible(prayer, 400, scrollable: _verticalScroll);
    expect(prayer, findsWidgets);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.text('لا توجد أذكار مطابقة'), findsNothing);
    expect(find.text('أذكار الصباح'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'اذكار الصباح');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('أذكار الصباح'), findsWidgets);
    expect(find.text('لا توجد أذكار مطابقة'), findsNothing);

    await tester.tap(find.text('أذكار الصباح').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(field.focusNode?.hasFocus, isFalse);
    expect(find.text('لا توجد أذكار مطابقة'), findsNothing);
    expect(find.text('أذكار الصباح'), findsWidgets);
  });

  testWidgets('closing the reading hint stays closed', (tester) async {
    SharedPreferences.setMockInitialValues({
      'zikr_state_v1': '{"onboardingSeen":true,"day":"2026-10-05"}',
    });
    final controller = AppController(enableNotifications: false);
    await tester.runAsync(() => controller.bootstrap());
    await tester.pumpWidget(
      ZikrApp(controller: controller, enableTicker: false),
    );
    await tester.pump();

    await tester.tap(find.text('أذكار الصباح').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('reading-hint-close')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-hint-close')));
    await tester.pump();
    expect(controller.state.hintSeen, isTrue);
    expect(find.byKey(const ValueKey('reading-hint-close')), findsNothing);

    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('أذكار الصباح').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reading-hint-close')), findsNothing);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    final again = AppController(enableNotifications: false);
    await tester.runAsync(() => again.bootstrap());
    expect(again.state.hintSeen, isTrue);
  });

  test('a reminder sync does not bring the reading hint back', () async {
    SharedPreferences.setMockInitialValues({});
    final notes = _SlowNotifications();
    final controller = AppController(
      enableNotifications: true,
      notifications: notes,
    );
    await controller.bootstrap();
    expect(controller.state.hintSeen, isFalse);

    final syncing = controller.syncReminders(reschedule: true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    controller.dismissHint();
    await syncing;
    expect(controller.state.hintSeen, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final again = AppController(enableNotifications: false);
    await again.bootstrap();
    expect(again.state.hintSeen, isTrue);
  });
}

class _SlowNotifications extends NotificationService {
  @override
  Future<void> init(void Function(String? payload) onTap) async {
    ready = true;
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {}

  @override
  Future<void> cancelWeek() async {}

  @override
  Future<void> scheduleWeek({
    required PersistedState state,
    required DateTime now,
    required bool morningDone,
    required bool eveningDone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }
}
