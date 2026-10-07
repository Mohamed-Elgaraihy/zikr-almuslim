import 'dart:convert';

import 'progress_logic.dart';

const backupKind = 'zikr-backup';

String encodeBackup(PersistedState state) {
  return jsonEncode({
    'kind': backupKind,
    'version': 1,
    'day': state.day,
    'taps': state.taps,
    'streak': state.streak,
    'lastGoalDay': state.lastGoalDay,
    'goalDays': state.goalDays,
  });
}

class BackupPayload {
  const BackupPayload({
    required this.day,
    required this.taps,
    required this.streak,
    required this.lastGoalDay,
    required this.goalDays,
  });

  final String day;
  final Map<String, int> taps;
  final int streak;
  final String? lastGoalDay;
  final List<String> goalDays;
}

BackupPayload? decodeBackup(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    if (decoded['kind'] != backupKind) return null;
    if (decoded['version'] != 1) return null;
    final day = decoded['day'];
    if (day is! String || day.isEmpty) return null;
    final taps = <String, int>{};
    final rawTaps = decoded['taps'];
    if (rawTaps is Map) {
      rawTaps.forEach((key, value) {
        if (key is String && value is num) taps[key] = value.toInt();
      });
    }
    final goalDays = <String>[];
    final rawDays = decoded['goalDays'];
    if (rawDays is List) {
      for (final entry in rawDays) {
        if (entry is String) goalDays.add(entry);
      }
    }
    return BackupPayload(
      day: day,
      taps: taps,
      streak: (decoded['streak'] as num?)?.toInt() ?? 0,
      lastGoalDay: decoded['lastGoalDay'] as String?,
      goalDays: goalDays,
    );
  } catch (_) {
    return null;
  }
}

PersistedState applyBackup(PersistedState current, BackupPayload backup) {
  return current.copyWith(
    taps: backup.day == current.day ? backup.taps : current.taps,
    streak: backup.streak,
    lastGoalDay: backup.lastGoalDay,
    clearLastGoal: backup.lastGoalDay == null,
    goalDays: backup.goalDays,
  );
}
