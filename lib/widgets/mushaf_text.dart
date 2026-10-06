import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Quran text in the Mushaf face, with a single drawn ayah mark.
///
/// The font's own end-of-ayah glyph draws as an empty ornament on the phone,
/// so the mark is painted here and that character is left out of the line.
class MushafText extends StatelessWidget {
  const MushafText({super.key, required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  static final _ayah = RegExp('\u06dd([0-9\u0660-\u0669]*)');

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Uthmanic',
      fontFamilyFallback: const ['Amiri', 'Cairo'],
      fontSize: fontSize,
      height: 1.8,
      color: AppColors.ink,
    );
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _ayah.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final raw = match.group(1) ?? '';
      if (raw.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _AyahMark(number: _eastern(raw), fontSize: fontSize),
          ),
        );
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text));

    return Text.rich(
      TextSpan(children: spans, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }
}

String _eastern(String raw) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();
  for (final char in raw.split('')) {
    final index = western.indexOf(char);
    buffer.write(index >= 0 ? eastern[index] : char);
  }
  return buffer.toString();
}

class _AyahMark extends StatelessWidget {
  const _AyahMark({required this.number, required this.fontSize});

  final String number;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final height = fontSize * 0.92;
    final width = number.length > 1 ? height + (number.length - 1) * fontSize * 0.28 : height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: AppColors.ink, width: 1.4),
        ),
        child: Text(
          number,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: fontSize * (number.length > 2 ? 0.3 : 0.38),
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
