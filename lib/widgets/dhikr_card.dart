import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/arabic_text.dart';
import '../models/azkar.dart';
import '../services/device_bridge.dart';
import '../theme/app_theme.dart';
import 'counter_button.dart';
import 'mushaf_text.dart';

class _Heading extends StatelessWidget {
  const _Heading({
    required this.text,
    required this.fontSize,
    required this.showTashkeel,
  });

  final String text;
  final double fontSize;
  final bool showTashkeel;

  String get _shown => showTashkeel ? text : stripTashkeel(text);

  bool get _vocalized => RegExp(r'[\u064B-\u0652]').hasMatch(_shown);

  @override
  Widget build(BuildContext context) {
    if (_vocalized) {
      return MushafText(text: _shown, fontSize: fontSize * 0.78);
    }
    return Text(
      _shown,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: (fontSize * 0.62).clamp(18, 26),
        height: 1.5,
        color: context.palette.greenDark,
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
    this.showTashkeel = true,
    this.haptics = true,
  });

  final String categoryId;
  final int index;
  final AzkarItem item;
  final int remaining;
  final double fontSize;
  final bool Function() onCount;
  final VoidCallback onReset;
  final bool showTashkeel;
  final bool haptics;

  bool get done => remaining == 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      decoration: BoxDecoration(
        color: done ? context.palette.done : context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done
              ? context.palette.green.withValues(alpha: 0.28)
              : context.palette.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.heading != null) ...[
            _Heading(
              text: item.heading!,
              fontSize: fontSize,
              showTashkeel: showTashkeel,
            ),
            const SizedBox(height: 10),
          ],
          MushafText(
            text: showTashkeel ? item.text : stripTashkeel(item.text),
            fontSize: fontSize,
          ),
          if (item.virtue != null) ...[
            const SizedBox(height: 14),
            Text(
              showTashkeel ? item.virtue! : stripTashkeel(item.virtue!),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: (fontSize * 0.55).clamp(18, 26),
                height: 1.65,
                color: context.palette.virtue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Row(
            children: [
              IconButton(
                tooltip: 'نسخ',
                iconSize: 24,
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _shareText(item)),
                  );
                  if (!context.mounted) return;
                  showQuietNotice(context, 'نُسخ الذكر');
                },
                icon: Icon(Icons.copy_rounded, color: context.palette.inkSoft),
              ),
              IconButton(
                tooltip: 'مشاركة',
                iconSize: 24,
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                onPressed: () async {
                  final shared = await DeviceBridge.shareText(
                    _shareText(item),
                    subject: item.heading ?? 'ذكر',
                  );
                  if (!context.mounted || shared) return;
                  await Clipboard.setData(
                    ClipboardData(text: _shareText(item)),
                  );
                  if (!context.mounted) return;
                  showQuietNotice(context, 'تعذّرت المشاركة، فنُسخ الذكر');
                },
                icon: Icon(Icons.share_rounded, color: context.palette.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CounterButton(
            key: ValueKey('counter-$categoryId-${item.id}'),
            remaining: remaining,
            done: done,
            haptics: haptics,
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

OverlayEntry? _quietNotice;

void showQuietNotice(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  _quietNotice?.remove();
  late OverlayEntry entry;
  var removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    if (identical(_quietNotice, entry)) _quietNotice = null;
    try {
      entry.remove();
    } catch (_) {}
  }

  entry = OverlayEntry(
    builder: (context) {
      final landscape =
          MediaQuery.orientationOf(context) == Orientation.landscape;
      final top = MediaQuery.paddingOf(context).top + (landscape ? 52 : 108);
      return Positioned(
        top: top,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: Material(
            color: AppColors.greenDark,
            elevation: 3,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  _quietNotice = entry;
  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 1400), remove);
}

String _shareText(AzkarItem item) {
  final times = item.count <= 1 ? 'مرة واحدة' : '${item.count} مرات';
  return [
    if (item.heading != null) item.heading,
    item.text,
    'العدد: $times',
    if (item.virtue != null) item.virtue,
  ].join('\n');
}
