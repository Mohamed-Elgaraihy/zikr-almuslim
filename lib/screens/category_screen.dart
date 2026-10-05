import 'package:flutter/material.dart';

import '../logic/progress_logic.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/dhikr_card.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({
    super.key,
    required this.controller,
    required this.categoryId,
  });

  final AppController controller;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final library = controller.library;
    if (library == null) {
      return const Scaffold(body: Center(child: Text('الأذكار غير متاحة')));
    }
    final category = library.byId(categoryId);
    final done = completedItems(controller.state, category);
    final total = category.items.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
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
          preferredSize: const Size.fromHeight(46),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fraction(done, total),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: [
          if (!controller.state.hintSeen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Material(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'اضغط الدائرة للعدّ، وأبقِ الضغط للعدّ السريع. يصل العداد إلى الصفر حين يكتمل الذكر.',
                        ),
                      ),
                      IconButton(
                        onPressed: controller.dismissHint,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          for (final entry in category.items.indexed)
            DhikrCard(
              categoryId: category.id,
              index: entry.$1 + 1,
              item: entry.$2,
              remaining: remainingFor(controller.state, category.id, entry.$2),
              fontSize: controller.state.fontSize,
              onCount: () {
                final result = controller.tap(category.id, entry.$2.id);
                if (!context.mounted) return result.changed;
                if (result.goalCompleted) {
                  _celebrate(
                    context,
                    title: 'تقبّل الله',
                    body:
                        'أتممت ورد اليوم. سلسلتك الآن ${controller.streakNow()} ${controller.streakNow() == 1 ? 'يوم' : 'أيام'}.',
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
        ],
          ),
        ),
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
