import 'package:flutter/material.dart';

import '../logic/progress_logic.dart';
import '../models/azkar.dart';
import '../services/device_bridge.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/dhikr_card.dart';
import '../widgets/placed_ad.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    super.key,
    required this.controller,
    required this.categoryId,
  });

  final AppController controller;
  final String categoryId;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    DeviceBridge.setAwake(true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showFirstOpen());
  }

  @override
  void dispose() {
    DeviceBridge.setAwake(false);
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int index) => _keys.putIfAbsent(index, GlobalKey.new);

  Future<void> _showFirstOpen() async {
    if (!mounted) return;
    final library = widget.controller.library;
    if (library == null) return;
    final category = library.byId(widget.categoryId);
    final index = category.items.indexWhere(
      (item) => remainingFor(widget.controller.state, category.id, item) > 0,
    );
    if (index <= 0) return;
    await _reveal(index);
  }

  int? _nextOpen(AzkarCategory category, int after) {
    for (var index = after + 1; index < category.items.length; index++) {
      if (remainingFor(
            widget.controller.state,
            category.id,
            category.items[index],
          ) >
          0) {
        return index;
      }
    }
    return null;
  }

  Future<void> _reveal(int index) async {
    final key = _keyFor(index);
    for (var step = 0; step < 24; step++) {
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!_scroll.hasClients) continue;
      final targetContext = key.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.08,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      final position = _scroll.position;
      final next = (position.pixels + position.viewportDimension * 0.85).clamp(
        0.0,
        position.maxScrollExtent,
      );
      if (next > position.pixels + 1) {
        _scroll.jumpTo(next);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final library = controller.library;
    if (library == null) {
      return const Scaffold(body: Center(child: Text('الأذكار غير متاحة')));
    }
    final category = library.byId(widget.categoryId);
    final done = completedItems(controller.state, category);
    final total = category.items.length;
    final progress = total == 0 ? 0.0 : done / total;
    final adAfter = total > 3 ? 2 : total - 1;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final progressBar = ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        minHeight: landscape ? 3 : 4,
        value: progress,
        backgroundColor: Colors.white24,
        color: AppColors.gold,
      ),
    );
    final progressLabel = Text(
      fraction(done, total),
      style: TextStyle(color: Colors.white, fontSize: landscape ? 13 : 16),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: landscape ? 48 : kToolbarHeight,
        title: landscape
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      category.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  progressLabel,
                ],
              )
            : Text(category.title),
        actions: [
          IconButton(
            tooltip: 'إعادة الباب',
            onPressed: done == 0
                ? null
                : () => controller.clearCategory(category.id),
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(landscape ? 4 : 46),
          child: landscape
              ? progressBar
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      progressBar,
                      const SizedBox(height: 6),
                      progressLabel,
                    ],
                  ),
                ),
        ),
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: [
          if (!controller.state.hintSeen)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, landscape ? 8 : 12),
              child: Material(
                color: context.palette.goldSoft,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(landscape ? 8 : 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'اضغط الشريط الأخضر للعدّ، وأبقِ الضغط للعدّ السريع. يصل العداد إلى الصفر حين يكتمل الذكر.',
                          maxLines: landscape ? 1 : null,
                          overflow: landscape ? TextOverflow.ellipsis : null,
                          style: landscape
                              ? const TextStyle(fontSize: 14, height: 1.3)
                              : null,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('reading-hint-close'),
                        tooltip: 'إغلاق',
                        onPressed: controller.dismissHint,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          for (final entry in category.items.indexed) ...[
            KeyedSubtree(
              key: _keyFor(entry.$1),
              child: DhikrCard(
                categoryId: category.id,
                index: entry.$1 + 1,
                item: entry.$2,
                remaining: remainingFor(
                  controller.state,
                  category.id,
                  entry.$2,
                ),
                fontSize: controller.state.fontSize,
                showTashkeel: controller.state.showTashkeel,
                haptics: controller.state.hapticsOn,
                onCount: () {
                  final before = remainingFor(
                    controller.state,
                    category.id,
                    entry.$2,
                  );
                  final result = controller.tap(category.id, entry.$2.id);
                  if (!context.mounted) return result.changed;
                  final finished =
                      before > 0 &&
                      remainingFor(controller.state, category.id, entry.$2) ==
                          0;
                  if (finished && controller.state.autoAdvance) {
                    final next = _nextOpen(category, entry.$1);
                    if (next != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _reveal(next);
                      });
                    }
                  }
                  if (result.goalCompleted) {
                    _celebrate(
                      context,
                      title: 'تقبّل الله',
                      body:
                          'أتممت ورد اليوم. سلسلتك الآن ${dayPhrase(controller.streakNow())}.',
                    );
                  } else if (result.categoryCompleted &&
                      (category.id == 'morning' || category.id == 'evening')) {
                    _celebrate(
                      context,
                      title: 'أتممت ${category.title}',
                      body: 'بقيت البركة في المواظبة.',
                    );
                  }
                  return result.changed;
                },
                onReset: () => controller.clearItem(category.id, entry.$2.id),
              ),
            ),
            if (entry.$1 == adAfter)
              const PlacedAd(
                labeled: true,
                margin: EdgeInsets.fromLTRB(16, 36, 16, 36),
              ),
          ],
        ],
      ),
    );
  }

  void _celebrate(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('الحمد لله'),
            ),
          ],
        );
      },
    );
  }
}
