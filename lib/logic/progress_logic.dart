import '../models/azkar.dart';

const double kMinDhikrFontSize = 28;
const double kMaxDhikrFontSize = 52;
const double kDefaultDhikrFontSize = 36;

/// Sizes saved by the first release (around 22) are below the readable floor.
double normalizeDhikrFontSize(num? raw) {
  if (raw == null) return kDefaultDhikrFontSize;
  final size = raw.toDouble();
  if (size < kMinDhikrFontSize) return kDefaultDhikrFontSize;
  if (size > kMaxDhikrFontSize) return kMaxDhikrFontSize;
  return size;
}

enum WirdSlot { morning, evening }

class DueNotice {
  const DueNotice({
    required this.slot,
    required this.title,
    required this.body,
  });

  final WirdSlot slot;
  final String title;
  final String body;

  String get payload => slot == WirdSlot.morning ? 'morning' : 'evening';
}

class PersistedState {
  const PersistedState({
    required this.day,
    this.taps = const {},
    this.streak = 0,
    this.lastGoalDay,
    this.goalDays = const [],
    this.remindersOn = true,
    this.morningHour = 6,
    this.morningMinute = 0,
    this.eveningHour = 16,
    this.eveningMinute = 30,
    this.fontSize = kDefaultDhikrFontSize,
    this.hintSeen = false,
    this.onboardingSeen = false,
    this.morningPingDay,
    this.eveningPingDay,
  });

  final String day;
  final Map<String, int> taps;
  final int streak;
  final String? lastGoalDay;
  final List<String> goalDays;
  final bool remindersOn;
  final int morningHour;
  final int morningMinute;
  final int eveningHour;
  final int eveningMinute;
  final double fontSize;
  final bool hintSeen;
  final bool onboardingSeen;
  final String? morningPingDay;
  final String? eveningPingDay;

  factory PersistedState.fresh(DateTime now) {
    return PersistedState(day: formatDay(now));
  }

  PersistedState copyWith({
    String? day,
    Map<String, int>? taps,
    int? streak,
    String? lastGoalDay,
    bool clearLastGoal = false,
    List<String>? goalDays,
    bool? remindersOn,
    int? morningHour,
    int? morningMinute,
    int? eveningHour,
    int? eveningMinute,
    double? fontSize,
    bool? hintSeen,
    bool? onboardingSeen,
    String? morningPingDay,
    bool clearMorningPing = false,
    String? eveningPingDay,
    bool clearEveningPing = false,
  }) {
    return PersistedState(
      day: day ?? this.day,
      taps: taps ?? this.taps,
      streak: streak ?? this.streak,
      lastGoalDay: clearLastGoal ? null : (lastGoalDay ?? this.lastGoalDay),
      goalDays: goalDays ?? this.goalDays,
      remindersOn: remindersOn ?? this.remindersOn,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      eveningHour: eveningHour ?? this.eveningHour,
      eveningMinute: eveningMinute ?? this.eveningMinute,
      fontSize: fontSize ?? this.fontSize,
      hintSeen: hintSeen ?? this.hintSeen,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      morningPingDay: clearMorningPing
          ? null
          : (morningPingDay ?? this.morningPingDay),
      eveningPingDay: clearEveningPing
          ? null
          : (eveningPingDay ?? this.eveningPingDay),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'taps': taps,
      'streak': streak,
      'lastGoalDay': lastGoalDay,
      'goalDays': goalDays,
      'remindersOn': remindersOn,
      'morningHour': morningHour,
      'morningMinute': morningMinute,
      'eveningHour': eveningHour,
      'eveningMinute': eveningMinute,
      'fontSize': fontSize,
      'hintSeen': hintSeen,
      'onboardingSeen': onboardingSeen,
      'morningPingDay': morningPingDay,
      'eveningPingDay': eveningPingDay,
    };
  }

  factory PersistedState.fromJson(Map<String, dynamic> json, DateTime now) {
    final taps = <String, int>{};
    final rawTaps = json['taps'];
    if (rawTaps is Map) {
      rawTaps.forEach((key, value) {
        if (key is String && value is num) {
          taps[key] = value.toInt();
        }
      });
    }
    final goalDays = <String>[];
    final rawDays = json['goalDays'];
    if (rawDays is List) {
      for (final day in rawDays) {
        if (day is String) goalDays.add(day);
      }
    }
    return PersistedState(
      day: json['day'] as String? ?? formatDay(now),
      taps: taps,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastGoalDay: json['lastGoalDay'] as String?,
      goalDays: goalDays,
      remindersOn: json['remindersOn'] as bool? ?? true,
      morningHour: (json['morningHour'] as num?)?.toInt() ?? 6,
      morningMinute: (json['morningMinute'] as num?)?.toInt() ?? 0,
      eveningHour: (json['eveningHour'] as num?)?.toInt() ?? 16,
      eveningMinute: (json['eveningMinute'] as num?)?.toInt() ?? 30,
      fontSize: normalizeDhikrFontSize(json['fontSize'] as num?),
      hintSeen: json['hintSeen'] as bool? ?? false,
      onboardingSeen: json['onboardingSeen'] as bool? ?? false,
      morningPingDay: json['morningPingDay'] as String?,
      eveningPingDay: json['eveningPingDay'] as String?,
    );
  }
}

class TapResult {
  const TapResult({
    required this.state,
    required this.changed,
    required this.categoryCompleted,
    required this.goalCompleted,
  });

  final PersistedState state;
  final bool changed;
  final bool categoryCompleted;
  final bool goalCompleted;
}

String itemKey(String categoryId, int itemId) => '$categoryId:$itemId';

String formatDay(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime parseDay(String day) {
  final parts = day.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

String previousDay(String day) {
  return formatDay(parseDay(day).subtract(const Duration(days: 1)));
}

String arabicDate(DateTime date) {
  const weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
}

String shortWeekday(DateTime date) {
  const labels = ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أحد'];
  return labels[date.weekday - 1];
}

String formatClock(int hour, int minute) {
  final h = hour.toString().padLeft(2, '0');
  final m = minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatCount(int value) {
  if (value >= 100) return '$value';
  return value.toString().padLeft(2, '0');
}

/// Keeps digits and slashes in left-to-right order inside the Arabic layout.
String ltr(Object value) => '\u200E$value';

String fraction(int done, int total) => ltr('$done / $total');

int tapsFor(PersistedState state, String categoryId, int itemId) {
  return state.taps[itemKey(categoryId, itemId)] ?? 0;
}

int remainingFor(PersistedState state, String categoryId, AzkarItem item) {
  final left = item.count - tapsFor(state, categoryId, item.id);
  if (left < 0) return 0;
  if (left > item.count) return item.count;
  return left;
}

bool itemDone(PersistedState state, String categoryId, AzkarItem item) {
  return tapsFor(state, categoryId, item.id) >= item.count;
}

int completedItems(PersistedState state, AzkarCategory category) {
  return category.items
      .where((item) => itemDone(state, category.id, item))
      .length;
}

bool categoryDone(PersistedState state, AzkarCategory category) {
  if (category.items.isEmpty) return false;
  return completedItems(state, category) == category.items.length;
}

bool dailyGoalMet(PersistedState state, AzkarLibrary library) {
  return categoryDone(state, library.morning) &&
      categoryDone(state, library.evening);
}

int visibleStreak(PersistedState state, String today) {
  if (state.lastGoalDay == null || state.streak <= 0) return 0;
  if (state.lastGoalDay == today || state.lastGoalDay == previousDay(today)) {
    return state.streak;
  }
  return 0;
}

int totalTaps(PersistedState state) {
  return state.taps.values.fold(0, (sum, value) => sum + value);
}

int completedCategories(PersistedState state, AzkarLibrary library) {
  return library.categories
      .where((category) => categoryDone(state, category))
      .length;
}

AzkarCategory categoryForSlot(AzkarLibrary library, WirdSlot slot) {
  return slot == WirdSlot.morning ? library.morning : library.evening;
}

bool slotDone(PersistedState state, AzkarLibrary library, WirdSlot slot) {
  return categoryDone(state, categoryForSlot(library, slot));
}

DateTime slotMoment(PersistedState state, DateTime day, WirdSlot slot) {
  if (slot == WirdSlot.morning) {
    return DateTime(
      day.year,
      day.month,
      day.day,
      state.morningHour,
      state.morningMinute,
    );
  }
  return DateTime(
    day.year,
    day.month,
    day.day,
    state.eveningHour,
    state.eveningMinute,
  );
}

DueNotice noticeFor(WirdSlot slot) {
  if (slot == WirdSlot.morning) {
    return const DueNotice(
      slot: WirdSlot.morning,
      title: 'أذكار الصباح',
      body: 'لم تقرأ أذكار الصباح اليوم. هل قرأت وردك؟',
    );
  }
  return const DueNotice(
    slot: WirdSlot.evening,
    title: 'أذكار المساء',
    body: 'لم تقرأ أذكار المساء اليوم. تذكير لطيف بوردك.',
  );
}

List<DueNotice> overdueNotices(
  PersistedState state,
  AzkarLibrary library,
  DateTime now,
) {
  if (!state.remindersOn) return const [];
  final notices = <DueNotice>[];
  for (final slot in WirdSlot.values) {
    if (slotDone(state, library, slot)) continue;
    final when = slotMoment(state, now, slot);
    if (now.isBefore(when)) continue;
    notices.add(noticeFor(slot));
  }
  return notices;
}

List<DueNotice> unsentNotices(
  PersistedState state,
  AzkarLibrary library,
  DateTime now,
) {
  return overdueNotices(state, library, now).where((notice) {
    final ping = notice.slot == WirdSlot.morning
        ? state.morningPingDay
        : state.eveningPingDay;
    return ping != state.day;
  }).toList();
}

PersistedState markSent(PersistedState state, WirdSlot slot) {
  if (slot == WirdSlot.morning) {
    return state.copyWith(morningPingDay: state.day);
  }
  return state.copyWith(eveningPingDay: state.day);
}

PersistedState rollTo(PersistedState state, DateTime now) {
  final day = formatDay(now);
  if (state.day == day) return state;
  return state.copyWith(
    day: day,
    taps: const {},
    clearMorningPing: true,
    clearEveningPing: true,
  );
}

PersistedState _awardGoal(PersistedState state) {
  if (state.lastGoalDay == state.day) return state;
  final streak = state.lastGoalDay == previousDay(state.day)
      ? state.streak + 1
      : 1;
  final days = [...state.goalDays.where((day) => day != state.day), state.day];
  final trimmed = days.length > 120 ? days.sublist(days.length - 120) : days;
  return state.copyWith(streak: streak, lastGoalDay: state.day, goalDays: trimmed);
}

PersistedState _revokeTodayGoal(PersistedState state) {
  if (state.lastGoalDay != state.day) return state;
  final days = state.goalDays.where((day) => day != state.day).toList();
  if (days.isEmpty) {
    return state.copyWith(streak: 0, goalDays: days, clearLastGoal: true);
  }
  final streak = state.streak > 0 ? state.streak - 1 : 0;
  return state.copyWith(
    streak: streak,
    lastGoalDay: days.last,
    goalDays: days,
  );
}

TapResult registerTap(
  PersistedState state,
  AzkarLibrary library,
  String categoryId,
  int itemId, {
  int step = 1,
}) {
  final category = library.byId(categoryId);
  final item = category.items.firstWhere((entry) => entry.id == itemId);
  final key = itemKey(categoryId, itemId);
  final current = state.taps[key] ?? 0;
  if (current >= item.count || step <= 0) {
    return TapResult(
      state: state,
      changed: false,
      categoryCompleted: false,
      goalCompleted: false,
    );
  }
  final next = current + step > item.count ? item.count : current + step;
  final taps = Map<String, int>.from(state.taps);
  taps[key] = next;
  var updated = state.copyWith(taps: taps);
  final wasCategoryDone = categoryDone(state, category);
  final wasGoal = dailyGoalMet(state, library);
  final nowCategoryDone = categoryDone(updated, category);
  var goalCompleted = false;
  if (!wasGoal && dailyGoalMet(updated, library)) {
    updated = _awardGoal(updated);
    goalCompleted = true;
  }
  return TapResult(
    state: updated,
    changed: true,
    categoryCompleted: !wasCategoryDone && nowCategoryDone,
    goalCompleted: goalCompleted,
  );
}

PersistedState resetItem(
  PersistedState state,
  AzkarLibrary library,
  String categoryId,
  int itemId,
) {
  final taps = Map<String, int>.from(state.taps)
    ..remove(itemKey(categoryId, itemId));
  var updated = state.copyWith(taps: taps);
  if (!dailyGoalMet(updated, library)) {
    updated = _revokeTodayGoal(updated);
  }
  return updated;
}

PersistedState resetCategory(
  PersistedState state,
  AzkarLibrary library,
  String categoryId,
) {
  final prefix = '$categoryId:';
  final taps = Map<String, int>.from(state.taps)
    ..removeWhere((key, _) => key.startsWith(prefix));
  var updated = state.copyWith(taps: taps);
  if (!dailyGoalMet(updated, library)) {
    updated = _revokeTodayGoal(updated);
  }
  return updated;
}

PersistedState resetToday(PersistedState state) {
  return _revokeTodayGoal(
    state.copyWith(
      taps: const {},
      clearMorningPing: true,
      clearEveningPing: true,
    ),
  );
}
