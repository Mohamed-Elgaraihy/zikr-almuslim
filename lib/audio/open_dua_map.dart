/// Offline Open Dua recitations (Muhammad Jumah) that match an azkar item.
///
/// Morning and evening variants are separate files. An item is absent when
/// the recording is a different wording or not in the set. The three
/// Mu'awwidhat are one clip, attached only to al-Ikhlas.
const openDuaTracks = <String, Map<int, String>>{
  'morning': {
    1: 'OD-075.mp3',
    2: 'OD-076.mp3',
    5: 'OD-077-1.mp3',
    6: 'OD-079.mp3',
    7: 'OD-087.mp3',
    8: 'OD-080-1.mp3',
    9: 'OD-081-1.mp3',
    10: 'OD-083.mp3',
    11: 'OD-086.mp3',
    12: 'OD-078-1.mp3',
    13: 'OD-090-1.mp3',
    14: 'OD-094.mp3',
    17: 'OD-084.mp3',
    18: 'OD-088.mp3',
    19: 'OD-089-1.mp3',
    20: 'OD-085.mp3',
    21: 'OD-097.mp3',
    25: 'OD-250.mp3',
    27: 'OD-095.mp3',
    29: 'OD-092.mp3',
    30: 'OD-091.mp3',
    31: 'OD-096.mp3',
  },
  'evening': {
    1: 'OD-075.mp3',
    2: 'OD-101.mp3',
    3: 'OD-076.mp3',
    6: 'OD-077-2.mp3',
    7: 'OD-079.mp3',
    8: 'OD-087.mp3',
    9: 'OD-080-2.mp3',
    10: 'OD-081-2.mp3',
    11: 'OD-083.mp3',
    12: 'OD-086.mp3',
    13: 'OD-078-2.mp3',
    14: 'OD-090-2.mp3',
    15: 'OD-094.mp3',
    18: 'OD-084.mp3',
    19: 'OD-088.mp3',
    20: 'OD-089-2.mp3',
    21: 'OD-085.mp3',
    22: 'OD-097.mp3',
    26: 'OD-250.mp3',
    28: 'OD-092.mp3',
    30: 'OD-091.mp3',
  },
};

String? openDuaAsset(String categoryId, int itemId) {
  final file = openDuaTracks[categoryId]?[itemId];
  if (file == null) return null;
  return 'assets/audio/opendua/$file';
}
