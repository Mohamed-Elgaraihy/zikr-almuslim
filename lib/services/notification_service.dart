import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../logic/progress_logic.dart';
import 'device_bridge.dart';

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
    await _useDeviceTimeZone();
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

  Future<void> _useDeviceTimeZone() async {
    try {
      final id = await DeviceBridge.timeZoneId();
      if (id != null && id.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(id));
        return;
      }
    } catch (error) {
      debugPrint('timezone lookup failed: $error');
    }
    _useLocalOffset();
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

  Future<bool> canScheduleExact() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.canScheduleExactNotifications() ?? true;
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
    for (final id in reminderAlarmIds) {
      await _plugin.cancel(id: id);
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
    final exact = await canScheduleExact();
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final plans = reminderSchedule(
      now: now,
      morningHour: state.morningHour,
      morningMinute: state.morningMinute,
      eveningHour: state.eveningHour,
      eveningMinute: state.eveningMinute,
      morningDone: morningDone,
      eveningDone: eveningDone,
    );
    for (final plan in plans) {
      final morning = plan.morning;
      await _scheduleOneShot(
        plan.id,
        morning ? 'أذكار الصباح' : 'أذكار المساء',
        morning
            ? 'لم تقرأ أذكار الصباح اليوم. هل قرأت وردك؟'
            : 'لم تقرأ أذكار المساء اليوم. تذكير لطيف بوردك.',
        plan.when,
        morning ? 'morning' : 'evening',
        mode,
      );
    }
  }

  Future<void> _scheduleOneShot(
    int id,
    String title,
    String body,
    DateTime when,
    String payload,
    AndroidScheduleMode mode,
  ) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    try {
      await _zoned(id, title, body, scheduled, payload, mode);
    } on PlatformException catch (error) {
      if (mode != AndroidScheduleMode.exactAllowWhileIdle) rethrow;
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
