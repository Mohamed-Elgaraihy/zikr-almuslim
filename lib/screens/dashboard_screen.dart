import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/progress_logic.dart';
import '../models/azkar.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onOpen,
  });

  final AppController controller;
  final void Function(String categoryId) onOpen;

  @override
  Widget build(BuildContext context) {
    final library = controller.library;
    if (library == null) {
      return const Center(child: Text('لا توجد بيانات بعد'));
    }
    final morningDone = completedItems(controller.state, library.morning);
    final eveningDone = completedItems(controller.state, library.evening);
    final morningTotal = library.morning.items.length;
    final eveningTotal = library.evening.items.length;
    final goalTotal = morningTotal + eveningTotal;
    final goalDone = morningDone + eveningDone;
    final progress = goalTotal == 0 ? 0.0 : goalDone / goalTotal;
    final touched = library.categories
        .where((category) => completedItems(controller.state, category) > 0)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        Text(
          arabicDate(controller.now),
          style: const TextStyle(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 4),
        const Text(
          'لوحة اليوم',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.greenDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'يكتمل ورد اليوم بقراءة أذكار الصباح والمساء.',
          style: TextStyle(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 18),
        _GoalCard(
          progress: progress,
          done: goalDone,
          total: goalTotal,
          streak: controller.streakNow(),
          taps: totalTaps(controller.state),
          chapters: completedCategories(controller.state, library),
        ),
        const SizedBox(height: 14),
        if (controller.banners.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MissingCard(
              notices: controller.banners,
              onOpen: onOpen,
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _MiniWird(
                title: 'الصباح',
                done: morningDone,
                total: morningTotal,
                icon: Icons.wb_sunny_rounded,
                onTap: () => onOpen('morning'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniWird(
                title: 'المساء',
                done: eveningDone,
                total: eveningTotal,
                icon: Icons.nights_stay_rounded,
                onTap: () => onOpen('evening'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'آخر سبعة أيام',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.greenDark),
        ),
        const SizedBox(height: 8),
        _WeekStrip(state: controller.state, today: controller.now),
        const SizedBox(height: 18),
        const Text(
          'ما بدأتَه اليوم',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.greenDark),
        ),
        const SizedBox(height: 8),
        if (touched.isEmpty)
          const _EmptyToday()
        else
          ...touched.map(
            (category) => _ProgressLine(
              category: category,
              done: completedItems(controller.state, category),
              onTap: () => onOpen(category.id),
            ),
          ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.progress,
    required this.done,
    required this.total,
    required this.streak,
    required this.taps,
    required this.chapters,
  });

  final double progress;
  final int done;
  final int total;
  final int streak;
  final int taps;
  final int chapters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _Ring(progress: progress, label: fraction(done, total)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ورد اليوم',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.greenDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${ltr(streak)} أيام متتالية'),
                Text('${ltr(taps)} تكرارًا · ${ltr(chapters)} أبواب مكتملة'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: CustomPaint(
        painter: _RingPainter(progress),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final base = Paint()
      ..color = AppColors.paperDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final arc = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MissingCard extends StatelessWidget {
  const _MissingCard({required this.notices, required this.onOpen});

  final List<DueNotice> notices;
  final void Function(String categoryId) onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alertWash,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لم يُقرأ بعد',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.alert),
          ),
          const SizedBox(height: 8),
          for (final notice in notices)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(notice.body)),
                  TextButton(
                    onPressed: () => onOpen(notice.payload),
                    child: const Text('اقرأ الآن'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniWird extends StatelessWidget {
  const _MiniWird({
    required this.title,
    required this.done,
    required this.total,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int done;
  final int total;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final finished = done == total;
    return Material(
      color: finished ? AppColors.done : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.green),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(finished ? 'تمّت' : fraction(done, total)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.state, required this.today});

  final PersistedState state;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (index) {
      return DateTime(today.year, today.month, today.day).subtract(
        Duration(days: 6 - index),
      );
    });
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: Column(
                children: [
                  Text(
                    shortWeekday(day),
                    style: const TextStyle(fontSize: 15, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.goalDays.contains(formatDay(day))
                          ? AppColors.green
                          : Colors.transparent,
                      border: Border.all(
                        color: formatDay(day) == formatDay(today)
                            ? AppColors.gold
                            : AppColors.line,
                        width: 2,
                      ),
                    ),
                    child: state.goalDays.contains(formatDay(day))
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.category,
    required this.done,
    required this.onTap,
  });

  final AzkarCategory category;
  final int done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = category.items.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(category.title)),
                    Text(fraction(done, total)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: total == 0 ? 0 : done / total,
                    backgroundColor: AppColors.paperDeep,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: const Text(
        'لم يُفتح باب اليوم بعد. ابدأ بأذكار الصباح أو المساء، ويُحسب كل ضغطة في لوحة اليوم.',
      ),
    );
  }
}
