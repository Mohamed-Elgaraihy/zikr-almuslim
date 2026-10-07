import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../logic/progress_logic.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'zikr_reminders',
      'تذكير الأذكار',
      channelDescription: 'تذكير إذا لم تُقرأ أذكار الصباح أو المساء',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );

  Future<void> init(void Function(String? payload) onTap) async {
    tzdata.initializeTimeZones();
    _useLocalOffset();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'فتح'),
      windows: WindowsInitializationSettings(
        appName: 'ذكر المسلم',
        appUserModelId: 'Com.ZikrAlmuslim.App',
        guid: '7c3a1d4e-6b8f-4a2e-9d1c-5f0e8a7b6c4d',
      ),
      web: WebInitializationSettings(),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
    ready = true;
  }

  void _useLocalOffset() {
    final offset = DateTime.now().timeZoneOffset;
    tz.Location? match;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(location).timeZoneOffset == offset) {
        match = location;
        break;
      }
    }
    tz.setLocalLocation(match ?? tz.UTC);
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) {
      final web = _plugin
          .resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin
          >();
      return await web?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final mac = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      return await mac?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> requestExactAlarm() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      await android?.requestExactAlarmsPermission();
    } catch (error) {
      debugPrint('exact alarm permission: $error');
    }
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
  }

  Future<void> cancelWeek() async {
    for (var day = 0; day < 7; day++) {
      await _plugin.cancel(id: 1100 + day);
      await _plugin.cancel(id: 2100 + day);
    }
  }

  Future<void> scheduleWeek({
    required PersistedState state,
    required DateTime now,
    required bool morningDone,
    required bool eveningDone,
  }) async {
    await cancelWeek();
    if (!state.remindersOn || kIsWeb) return;
    final start = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset < 7; offset++) {
      final date = start.add(Duration(days: offset));
      if (!(offset == 0 && morningDone)) {
        final when = DateTime(
          date.year,
          date.month,
          date.day,
          state.morningHour,
          state.morningMinute,
        );
        if (when.isAfter(now)) {
          await _schedule(
            1100 + offset,
            'أذكار الصباح',
            'لم تقرأ أذكار الصباح اليوم. هل قرأت وردك؟',
            when,
            'morning',
          );
        }
      }
      if (!(offset == 0 && eveningDone)) {
        final when = DateTime(
          date.year,
          date.month,
          date.day,
          state.eveningHour,
          state.eveningMinute,
        );
        if (when.isAfter(now)) {
          await _schedule(
            2100 + offset,
            'أذكار المساء',
            'لم تقرأ أذكار المساء اليوم. تذكير لطيف بوردك.',
            when,
            'evening',
          );
        }
      }
    }
  }

  Future<void> _schedule(
    int id,
    String title,
    String body,
    DateTime when,
    String payload,
  ) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    try {
      await _zoned(
        id,
        title,
        body,
        scheduled,
        payload,
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (error) {
      debugPrint('exact schedule failed, using inexact: $error');
      await _zoned(
        id,
        title,
        body,
        scheduled,
        payload,
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _zoned(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduled,
    String payload,
    AndroidScheduleMode mode,
  ) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: mode,
      payload: payload,
    );
  }
}
