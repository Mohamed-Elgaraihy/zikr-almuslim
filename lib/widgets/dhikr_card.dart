import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/azkar.dart';
import '../theme/app_theme.dart';
import 'counter_button.dart';
import 'mushaf_text.dart';

class _Heading extends StatelessWidget {
  const _Heading({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  bool get _vocalized => RegExp(r'[\u064B-\u0652]').hasMatch(text);

  @override
  Widget build(BuildContext context) {
    if (_vocalized) {
      return MushafText(text: text, fontSize: fontSize * 0.78);
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: (fontSize * 0.62).clamp(18, 26),
        height: 1.5,
        color: AppColors.greenDark,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class DhikrCard extends StatelessWidget {
  const DhikrCard({
    super.key,
    required this.categoryId,
    required this.index,
    required this.item,
    required this.remaining,
    required this.fontSize,
    required this.onCount,
    required this.onReset,
  });

  final String categoryId;
  final int index;
  final AzkarItem item;
  final int remaining;
  final double fontSize;
  final bool Function() onCount;
  final VoidCallback onReset;

  bool get done => remaining == 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      decoration: BoxDecoration(
        color: done ? AppColors.done : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done ? AppColors.green.withValues(alpha: 0.28) : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.heading != null) ...[
            _Heading(text: item.heading!, fontSize: fontSize),
            const SizedBox(height: 10),
          ],
          MushafText(text: item.text, fontSize: fontSize),
          if (item.virtue != null) ...[
            const SizedBox(height: 14),
            Text(
              item.virtue!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: (fontSize * 0.55).clamp(18, 26),
                height: 1.65,
                color: AppColors.virtue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              tooltip: 'نسخ',
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: [
                      if (item.heading != null) item.heading,
                      item.text,
                      if (item.virtue != null) item.virtue,
                    ].join('\n'),
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('نُسخ الذكر')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.inkSoft),
            ),
          ),
          CounterButton(
            key: ValueKey('counter-$categoryId-${item.id}'),
            remaining: remaining,
            done: done,
            onTap: onCount,
            onReset: onReset,
            index: index,
            label: 'الذكر رقم $index',
          ),
        ],
      ),
    );
  }
}
