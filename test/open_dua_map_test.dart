import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zikr_almuslim/audio/open_dua_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every morning and evening item is mapped or explicitly unmapped',
    () async {
      final raw = await rootBundle.loadString('assets/data/azkar.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final categories = data['categories'] as List<dynamic>;
      final unmapped = {
        'morning': {3, 4, 15, 16, 22, 23, 24, 26, 28},
        'evening': {4, 5, 16, 17, 23, 24, 25, 27, 29},
      };

      for (final category in categories) {
        final id = category['id'] as String;
        if (id != 'morning' && id != 'evening') {
          for (final item in category['items'] as List<dynamic>) {
            expect(openDuaAsset(id, item['id'] as int), isNull);
          }
          continue;
        }
        final seen = <int>{};
        for (final item in category['items'] as List<dynamic>) {
          final itemId = item['id'] as int;
          seen.add(itemId);
          final asset = openDuaAsset(id, itemId);
          if (unmapped[id]!.contains(itemId)) {
            expect(asset, isNull, reason: '$id $itemId should stay unmapped');
          } else {
            expect(asset, isNotNull, reason: '$id $itemId should have a track');
            final bytes = await rootBundle.load(asset!);
            expect(bytes.lengthInBytes, greaterThan(1000));
          }
        }
        expect(seen.containsAll(unmapped[id]!), isTrue);
        expect(openDuaTracks[id]!.keys.every(seen.contains), isTrue);
      }

      expect(openDuaAsset('morning', 2), 'assets/audio/opendua/OD-076.mp3');
      expect(openDuaAsset('evening', 3), 'assets/audio/opendua/OD-076.mp3');
      expect(openDuaAsset('morning', 3), isNull);
      expect(openDuaAsset('morning', 4), isNull);
      expect(openDuaAsset('evening', 4), isNull);
      expect(openDuaAsset('evening', 5), isNull);
      expect(openDuaAsset('morning', 5), 'assets/audio/opendua/OD-077-1.mp3');
      expect(openDuaAsset('evening', 6), 'assets/audio/opendua/OD-077-2.mp3');
      expect(openDuaAsset('morning', 12), 'assets/audio/opendua/OD-078-1.mp3');
      expect(openDuaAsset('evening', 13), 'assets/audio/opendua/OD-078-2.mp3');
      expect(openDuaAsset('morning', 14), 'assets/audio/opendua/OD-094.mp3');
      expect(openDuaAsset('morning', 30), 'assets/audio/opendua/OD-091.mp3');
    },
  );
}
