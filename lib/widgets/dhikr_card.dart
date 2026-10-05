import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/azkar.dart';
import '../theme/app_theme.dart';
import 'counter_button.dart';

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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 16, 16, 14),
      decoration: BoxDecoration(
        color: done ? AppColors.done : AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: done ? AppColors.green.withValues(alpha: 0.35) : AppColors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14083C2E),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  item.text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: fontSize,
                    height: 2.05,
                    color: AppColors.ink,
                  ),
                ),
                if (item.virtue != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.virtue!,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: (fontSize * 0.62).clamp(13, 18),
                      height: 1.7,
                      color: AppColors.virtue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: item.text));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('نُسخ الذكر')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('نسخ'),
                    ),
                    if (remaining < item.count)
                      TextButton(
                        onPressed: onReset,
                        child: const Text('إعادة'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              CounterButton(
                key: ValueKey('counter-$categoryId-${item.id}'),
                remaining: remaining,
                done: done,
                onTap: onCount,
                label: 'الذكر رقم $index',
              ),
              const SizedBox(height: 8),
              Text(
                '$index',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
