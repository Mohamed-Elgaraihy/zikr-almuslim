import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/azkar_repository.dart';
import '../logic/progress_logic.dart';
import '../models/azkar.dart';
import '../logic/backup.dart';
import '../services/device_bridge.dart';
import '../services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    AzkarRepository? repository,
    NotificationService? notifications,
    DateTime Function()? clock,
    this.enableNotifications = true,
  }) : _repository = repository ?? const AzkarRepository(),
       _notifications = notifications ?? NotificationService(),
       _clock = clock ?? DateTime.now;

  final bool enableNotifications;

  static const _storageKey = 'zikr_state_v1';

  final AzkarRepository _repository;
  final NotificationService _notifications;
  final DateTime Function() _clock;

  PersistedState state = PersistedState.fresh(DateTime.now());
  AzkarLibrary? library;
  String? loadError;
  String? pendingCategoryId;
  bool ready = false;

  DateTime get now => _clock();

  AzkarLibrary get azkar {
    final loaded = library;
    if (loaded == null) {
      throw StateError('Azkar library is not loaded');
    }
    return loaded;
  }

  Future<void> bootstrap() async {
    _listenForWidget();
    final clockNow = now;
    try {
      library = await _repository.load();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        state = PersistedState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
          clockNow,
        );
      } else {
        state = PersistedState.fresh(clockNow);
      }
      state = rollTo(state, clockNow);
      loadError = null;
    } catch (error) {
      loadError = 'تعذّر فتح الأذكار. أعد المحاولة.';
      debugPrint('bootstrap failed: $error');
    }
    ready = true;
    notifyListeners();
    _pushWidget();
    if (!enableNotifications) return;
    try {
      await _notifications.init((payload) {
        if (payload == 'morning' || payload == 'evening') {
          pendingCategoryId = payload;
          notifyListeners();
        }
      });
      await syncReminders(reschedule: true);
    } catch (error) {
      debugPrint('notifications unavailable: $error');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  void _commit(PersistedState next) {
    state = next;
    notifyListeners();
    _save();
    _pushWidget();
  }

  void _listenForWidget() {
    DeviceBridge.listen((slot) {
      if (slot != 'morning' && slot != 'evening') return;
      pendingCategoryId = slot;
      notifyListeners();
    });
    DeviceBridge.takePendingSlot().then((slot) {
      if (slot != 'morning' && slot != 'evening') return;
      pendingCategoryId = slot;
      notifyListeners();
    });
  }

  void _pushWidget() {
    final loaded = library;
    if (loaded == null) return;
    DeviceBridge.updateWidget(
      day: state.day,
      morningDone: slotDone(state, loaded, WirdSlot.morning),
      eveningDone: slotDone(state, loaded, WirdSlot.evening),
    );
  }

  TapResult tap(String categoryId, int itemId, {int step = 1}) {
    final result = registerTap(state, azkar, categoryId, itemId, step: step);
    if (!result.changed) return result;
    _commit(result.state);
    if (result.categoryCompleted &&
        (categoryId == 'morning' || categoryId == 'evening')) {
      syncReminders(reschedule: true);
    }
    return result;
  }

  void clearItem(String categoryId, int itemId) {
    _commit(resetItem(state, azkar, categoryId, itemId));
    syncReminders(reschedule: true);
  }

  void clearCategory(String categoryId) {
    _commit(resetCategory(state, azkar, categoryId));
    syncReminders(reschedule: true);
  }

  void clearToday() {
    _commit(resetToday(state));
    syncReminders(reschedule: true);
  }

  void dismissHint() {
    if (state.hintSeen) return;
    _commit(state.copyWith(hintSeen: true));
  }

  Future<void> setReminders(bool enabled) async {
    _commit(state.copyWith(remindersOn: enabled));
    if (enabled) {
      try {
        await _notifications.requestPermission();
        await _notifications.requestExactAlarm();
      } catch (error) {
        debugPrint('permission request failed: $error');
      }
    }
    await syncReminders(reschedule: true);
  }

  Future<void> setMorningTime(int hour, int minute) async {
    _commit(
      state.copyWith(
        morningHour: hour,
        morningMinute: minute,
        clearMorningPing: true,
      ),
    );
    await syncReminders(reschedule: true);
  }

  Future<void> setEveningTime(int hour, int minute) async {
    _commit(
      state.copyWith(
        eveningHour: hour,
        eveningMinute: minute,
        clearEveningPing: true,
      ),
    );
    await syncReminders(reschedule: true);
  }

  void completeOnboarding() {
    if (state.onboardingSeen) return;
    _commit(state.copyWith(onboardingSeen: true));
  }

  void setShowTashkeel(bool shown) {
    if (shown == state.showTashkeel) return;
    _commit(state.copyWith(showTashkeel: shown));
  }

  void setDarkMode(bool enabled) {
    if (enabled == state.darkMode) return;
    _commit(state.copyWith(darkMode: enabled));
  }

  String backupText() => encodeBackup(state);

  String? restoreBackup(String raw) {
    final payload = decodeBackup(raw);
    if (payload == null) return 'هذا النص ليس نسخة من ذكر المسلم.';
    _commit(applyBackup(state, payload));
    syncReminders(reschedule: true);
    return null;
  }

  void setFontSize(double size) {
    final clamped = size.clamp(kMinDhikrFontSize, kMaxDhikrFontSize).toDouble();
    if (clamped == state.fontSize && state.fontTuned) return;
    _commit(state.copyWith(fontSize: clamped, fontTuned: true));
  }

  Future<bool> sendTestNotification() async {
    try {
      if (!_notifications.ready) {
        await _notifications.init((payload) {
          if (payload == 'morning' || payload == 'evening') {
            pendingCategoryId = payload;
            notifyListeners();
          }
        });
      }
      final granted = await _notifications.requestPermission();
      if (!granted && kIsWeb) return false;
      await _notifications.showNow(
        id: 42,
        title: 'ذكر المسلم',
        body: 'هذا تنبيه تجريبي. سنذكّرك إذا فات ورد الصباح أو المساء.',
        payload: 'morning',
      );
      return true;
    } catch (error) {
      debugPrint('test notification failed: $error');
      return false;
    }
  }

  Future<void> syncReminders({bool reschedule = false}) async {
    if (library == null) return;
    final clockNow = now;
    var next = rollTo(state, clockNow);
    var changed =
        next.day != state.day || next.taps.length != state.taps.length;
    if (_notifications.ready) {
      for (final notice in unsentNotices(next, azkar, clockNow)) {
        try {
          await _notifications.showNow(
            id: notice.slot == WirdSlot.morning ? 11 : 12,
            title: notice.title,
            body: notice.body,
            payload: notice.payload,
          );
          next = markSent(next, notice.slot);
          changed = true;
        } catch (error) {
          debugPrint('show reminder failed: $error');
        }
      }
      if (reschedule) {
        try {
          await _notifications.scheduleWeek(
            state: next,
            now: clockNow,
            morningDone: slotDone(next, azkar, WirdSlot.morning),
            eveningDone: slotDone(next, azkar, WirdSlot.evening),
          );
        } catch (error) {
          debugPrint('schedule failed: $error');
        }
      }
    }
    if (changed) {
      state = next;
      notifyListeners();
      await _save();
    } else {
      state = next;
    }
    _pushWidget();
  }

  void consumePendingCategory() {
    pendingCategoryId = null;
  }

  List<DueNotice> get banners {
    final loaded = library;
    if (loaded == null) return const [];
    return overdueNotices(state, loaded, now);
  }

  int streakNow() => visibleStreak(state, formatDay(now));
}
