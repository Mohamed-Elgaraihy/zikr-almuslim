import 'package:flutter_test/flutter_test.dart';
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

  test('morning and evening together award a streak and a missed day breaks it', () {
    var state = PersistedState(day: '2026-10-05', streak: 2, lastGoalDay: '2026-10-04');
    state = registerTap(state, library, 'morning', 1).state;
    state = registerTap(state, library, 'morning', 2, step: 3).state;
    final evening = registerTap(state, library, 'evening', 1);
    expect(evening.goalCompleted, isTrue);
    expect(evening.state.streak, 3);
    expect(visibleStreak(evening.state, '2026-10-05'), 3);
    expect(visibleStreak(evening.state, '2026-10-07'), 0);
  });

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

  test('the reminder appears only after its time and only if the wird is open', () {
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
  });

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
}
