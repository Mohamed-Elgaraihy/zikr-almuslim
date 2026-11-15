import 'package:flutter_test/flutter_test.dart';
import 'package:zikr_almuslim/logic/arabic_text.dart';
import 'package:zikr_almuslim/logic/backup.dart';
import 'package:zikr_almuslim/logic/progress_logic.dart';
import 'package:zikr_almuslim/models/azkar.dart';

AzkarLibrary sampleLibrary() {
  AzkarCategory category(String id, String title, List<int> counts) {
    return AzkarCategory(
      id: id,
      title: title,
      group: 'daily',
      daily: id == 'morning' || id == 'evening',
      items: [
        for (var i = 0; i < counts.length; i++)
          AzkarItem(id: i + 1, text: 'ذكر', count: counts[i]),
      ],
    );
  }

  return AzkarLibrary(
    title: 'ذكر المسلم',
    source: 'اختبار',
    groups: const [AzkarGroup(id: 'daily', title: 'اليوم')],
    categories: [
      category('morning', 'أذكار الصباح', [1, 3]),
      category('evening', 'أذكار المساء', [1]),
      category('c2', 'أذكار النوم', [2]),
    ],
  );
}

void main() {
  final library = sampleLibrary();

  test('a tap counts down and stops at the target', () {
    final state = PersistedState(day: '2026-10-05');
    final once = registerTap(state, library, 'morning', 2);
    expect(once.changed, isTrue);
    expect(tapsFor(once.state, 'morning', 2), 1);
    expect(remainingFor(once.state, 'morning', library.morning.items[1]), 2);

    final filled = registerTap(once.state, library, 'morning', 2, step: 5);
    expect(tapsFor(filled.state, 'morning', 2), 3);
    expect(itemDone(filled.state, 'morning', library.morning.items[1]), isTrue);

    final extra = registerTap(filled.state, library, 'morning', 2);
    expect(extra.changed, isFalse);
  });

  test(
    'morning and evening together award a streak and a missed day breaks it',
    () {
      var state = PersistedState(
        day: '2026-10-05',
        streak: 2,
        lastGoalDay: '2026-10-04',
      );
      state = registerTap(state, library, 'morning', 1).state;
      state = registerTap(state, library, 'morning', 2, step: 3).state;
      final evening = registerTap(state, library, 'evening', 1);
      expect(evening.goalCompleted, isTrue);
      expect(evening.state.streak, 3);
      expect(visibleStreak(evening.state, '2026-10-05'), 3);
      expect(visibleStreak(evening.state, '2026-10-07'), 0);
    },
  );

  test('a new day clears taps and keeps yesterday streak visible', () {
    final done = PersistedState(
      day: '2026-10-04',
      taps: {'morning:1': 1},
      streak: 4,
      lastGoalDay: '2026-10-04',
      goalDays: ['2026-10-04'],
    );
    final rolled = rollTo(done, DateTime(2026, 10, 5, 8));
    expect(rolled.day, '2026-10-05');
    expect(rolled.taps, isEmpty);
    expect(visibleStreak(rolled, '2026-10-05'), 4);
  });

  test('resetting a finished wird removes today from the streak', () {
    final state = PersistedState(
      day: '2026-10-05',
      taps: {'morning:1': 1, 'morning:2': 3, 'evening:1': 1},
      streak: 2,
      lastGoalDay: '2026-10-05',
      goalDays: ['2026-10-04', '2026-10-05'],
    );
    final cleared = resetToday(state);
    expect(cleared.taps, isEmpty);
    expect(cleared.lastGoalDay, '2026-10-04');
    expect(cleared.streak, 1);
    expect(dailyGoalMet(cleared, library), isFalse);
  });

  test(
    'the reminder appears only after its time and only if the wird is open',
    () {
      final morning = DateTime(2026, 10, 5, 6, 30);
      final early = PersistedState(day: '2026-10-05');
      expect(overdueNotices(early, library, DateTime(2026, 10, 5, 5)), isEmpty);

      final due = overdueNotices(early, library, morning);
      expect(due.map((notice) => notice.slot), [WirdSlot.morning]);

      final read = registerTap(
        registerTap(early, library, 'morning', 1).state,
        library,
        'morning',
        2,
        step: 3,
      ).state;
      expect(
        overdueNotices(read, library, morning).map((notice) => notice.slot),
        isEmpty,
      );

      final sent = markSent(early, WirdSlot.morning);
      expect(unsentNotices(sent, library, morning), isEmpty);
      expect(overdueNotices(sent, library, morning), isNotEmpty);
    },
  );

  test('the natural dhikr size is 28 unless the reader chose another', () {
    final now = DateTime(2026, 10, 5);
    final legacy = PersistedState.fromJson({
      'day': '2026-10-05',
      'fontSize': 22,
    }, now);
    expect(legacy.fontSize, 28);
    expect(legacy.onboardingSeen, isFalse);

    final previousDefault = PersistedState.fromJson({
      'day': '2026-10-05',
      'fontSize': 36,
    }, now);
    expect(previousDefault.fontSize, 28);

    final chosen = PersistedState.fromJson({
      'day': '2026-10-05',
      'fontSize': 40,
      'onboardingSeen': true,
    }, now);
    expect(chosen.fontSize, 40);
    expect(chosen.onboardingSeen, isTrue);

    final kept = PersistedState.fromJson({
      'day': '2026-10-05',
      'fontSize': 36,
      'fontTuned': true,
    }, now);
    expect(kept.fontSize, 36);
    expect(kept.copyWith().toJson()['fontTuned'], isTrue);
  });

  test('counts and weekdays agree in Arabic', () {
    expect(dayPhrase(0), '٠ يومًا');
    expect(dayPhrase(1), '١ يوم');
    expect(dayPhrase(2), '٢ يومين');
    expect(dayPhrase(5), '٥ أيام');
    expect(dayPhrase(12), '١٢ يومًا');
    expect(tapPhrase(1), '١ تكرار');
    expect(tapPhrase(2), '٢ تكرارين');
    expect(tapPhrase(4), '٤ تكرارات');
    expect(tapPhrase(15), '١٥ تكرارًا');
    expect(arabicDigits('1.5.8'), '١.٥.٨');
    expect(formatCount(1), '٠١');
    final monday = DateTime(2026, 10, 5);
    expect(monday.weekday, DateTime.monday);
    expect(weekdayName(monday), 'الإثنين');
    expect(weekdayName(DateTime(2026, 10, 10)), 'السبت');
    expect(weekdayName(DateTime(2026, 10, 11)), 'الأحد');
  });

  test('the sebha count is kept apart from the daily wird', () {
    final state = PersistedState(
      day: '2026-10-05',
      sebhaCount: 40,
      sebhaTarget: 33,
      taps: {'morning:1': 1},
    );
    final rolled = rollTo(state, DateTime(2026, 10, 6));
    expect(rolled.taps, isEmpty);
    expect(rolled.sebhaCount, 40);
    expect(rolled.sebhaTarget, 33);
    final saved = PersistedState.fromJson(
      state.toJson(),
      DateTime(2026, 10, 5),
    );
    expect(saved.sebhaCount, 40);
    expect(saved.sebhaTarget, 33);
  });

  test('diacritics can be hidden without dropping the letters', () {
    expect(stripTashkeel('الْحَمْدُ لِلَّهِ'), 'الحمد لله');
    expect(stripTashkeel('بِسْمِ'), 'بسم');
  });

  test('arabic search treats alef, teh marbuta, and alef maksura as equal', () {
    expect(normalizeArabic('أَذْكَار'), 'اذكار');
    expect(normalizeArabic('إسلام'), 'اسلام');
    expect(normalizeArabic('آية'), 'ايه');
    expect(normalizeArabic('صلاة'), 'صلاه');
    expect(normalizeArabic('موسى'), 'موسي');
    expect(normalizeArabic('ٱلْحَمْدُ'), 'الحمد');
    expect(arabicContains('أَذْكَارُ الصَّبَاحِ', 'اذكار الصباح'), isTrue);
    expect(arabicContains('أذكار الصلاة', 'صلاه'), isTrue);
    expect(arabicContains('هدى', 'هدي'), isTrue);
    expect(arabicContains('صلاة', 'صيام'), isFalse);
  });

  test('a backup restores today and leaves an older day off the counter', () {
    final current = PersistedState(
      day: '2026-10-07',
      taps: {'morning:1': 1},
      streak: 1,
    );
    final today = decodeBackup(
      encodeBackup(
        PersistedState(
          day: '2026-10-07',
          taps: {'evening:1': 2},
          streak: 9,
          lastGoalDay: '2026-10-06',
          goalDays: ['2026-10-06'],
        ),
      ),
    );
    expect(today, isNotNull);
    final applied = applyBackup(current, today!);
    expect(applied.taps['evening:1'], 2);
    expect(applied.taps.containsKey('morning:1'), isFalse);
    expect(applied.streak, 9);
    expect(applied.goalDays, ['2026-10-06']);

    final older = decodeBackup(
      '{"kind":"zikr-backup","version":1,"day":"2026-10-01","taps":{"morning:1":5},"streak":4,"lastGoalDay":"2026-10-01","goalDays":["2026-10-01"]}',
    );
    final kept = applyBackup(current, older!);
    expect(kept.taps['morning:1'], 1);
    expect(kept.streak, 4);

    expect(decodeBackup('ليس نسخة'), isNull);
    final fresh = PersistedState.fromJson({
      'day': '2026-10-07',
    }, DateTime(2026, 10, 7));
    expect(fresh.showTashkeel, isTrue);
    expect(fresh.darkMode, isFalse);
    expect(fresh.hapticsOn, isTrue);
    expect(fresh.autoAdvance, isTrue);
    expect(
      fresh.copyWith(hapticsOn: false, autoAdvance: false).toJson(),
      containsPair('hapticsOn', false),
    );
  });
}
