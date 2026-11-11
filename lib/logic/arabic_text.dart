final _tashkeel = RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]');
final _spaces = RegExp(r'\s+');

String stripTashkeel(String text) => text.replaceAll(_tashkeel, '');

/// Search form of Arabic: no diacritics, and أ/إ/آ/ٱ/ا, ة/ه, ى/ي match.
String normalizeArabic(String text) {
  final stripped = stripTashkeel(text);
  final buffer = StringBuffer();
  for (final rune in stripped.runes) {
    final letter = switch (rune) {
      0x0622 || 0x0623 || 0x0625 || 0x0671 => 'ا',
      0x0629 => 'ه',
      0x0649 => 'ي',
      0x0640 => '',
      _ => String.fromCharCode(rune),
    };
    buffer.write(letter);
  }
  return buffer.toString().replaceAll(_spaces, ' ').trim();
}

bool arabicContains(String haystack, String needle) {
  final query = normalizeArabic(needle);
  if (query.isEmpty) return true;
  return normalizeArabic(haystack).contains(query);
}
