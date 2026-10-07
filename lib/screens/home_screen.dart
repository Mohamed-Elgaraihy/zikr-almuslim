import 'package:flutter/material.dart';

import '../logic/progress_logic.dart';
import '../models/azkar.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/pattern_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller, required this.onOpen});

  final AppController controller;
  final void Function(String categoryId) onOpen;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final library = controller.library;
    if (library == null) {
      return const Center(child: Text('تعذّر تحميل الأذكار'));
    }
    final query = _query.trim();
    final width = MediaQuery.sizeOf(context).width;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(controller: controller)),
        if (controller.banners.isNotEmpty)
          SliverToBoxAdapter(
            child: _ReminderBanner(
              notices: controller.banners,
              onOpen: widget.onOpen,
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: _FeaturedRow(
              controller: controller,
              wide: width >= 720,
              onOpen: widget.onOpen,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'ابحث في الأبواب أو نص الذكر',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
          ),
        ),
        if (query.isEmpty)
          ..._groups(library, controller, width)
        else
          ..._search(library, query),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  List<Widget> _groups(
    AzkarLibrary library,
    AppController controller,
    double width,
  ) {
    final columns = width >= 900 ? 3 : 2;
    return [
      for (final group in library.groups)
        if (library.inGroup(group.id).isNotEmpty) ...[
          if (group.title.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Text(
                  group.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 84,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = library.inGroup(group.id)[index];
                return _CategoryTile(
                  category: category,
                  done: completedItems(controller.state, category),
                  onTap: () => widget.onOpen(category.id),
                );
              }, childCount: library.inGroup(group.id).length),
            ),
          ),
        ],
    ];
  }

  List<Widget> _search(AzkarLibrary library, String query) {
    final categories = library.categories.where((category) {
      return category.title.contains(query) ||
          category.items.any(
            (item) =>
                item.text.contains(query) ||
                (item.heading?.contains(query) ?? false),
          );
    }).toList();
    if (categories.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('لا توجد أذكار مطابقة')),
        ),
      ];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final category = categories[index];
          AzkarItem? hit;
          for (final item in category.items) {
            if (item.text.contains(query)) {
              hit = item;
              break;
            }
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _CategoryTile(
              category: category,
              done: completedItems(widget.controller.state, category),
              subtitle: hit?.text.split('\n').first,
              onTap: () => widget.onOpen(category.id),
            ),
          );
        }, childCount: categories.length),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final hour = controller.now.hour;
    final greeting = hour < 12
        ? 'صباح النور'
        : hour < 17
        ? 'طاب يومك'
        : 'مساء النور';
    final streak = controller.streakNow();
    final taps = totalTaps(controller.state);
    return PatternHeader(
      height: 188,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(color: AppColors.goldSoft, fontSize: 17),
            ),
            const SizedBox(height: 4),
            const Text(
              'ذكر المسلم',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              arabicDate(controller.now),
              style: const TextStyle(color: Color(0xFFD7E6DF)),
            ),
            const Spacer(),
            Row(
              children: [
                _StatChip(
                  icon: Icons.local_fire_department_rounded,
                  label: '${ltr(streak)} يومًا',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.fingerprint_rounded,
                  label: '${ltr(taps)} تكرارًا اليوم',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.goldSoft),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.notices, required this.onOpen});

  final List<DueNotice> notices;
  final void Function(String categoryId) onOpen;

  @override
  Widget build(BuildContext context) {
    final notice = notices.last;
    final body = notices.length == 1
        ? notice.body
        : 'لم يُقرأ ورد الصباح ولا ورد المساء اليوم.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: AppColors.alertWash,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onOpen(notice.payload),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.alert),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تذكير',
                        style: TextStyle(
                          color: AppColors.alert,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(body),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: AppColors.alert),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({
    required this.controller,
    required this.wide,
    required this.onOpen,
  });

  final AppController controller;
  final bool wide;
  final void Function(String categoryId) onOpen;

  @override
  Widget build(BuildContext context) {
    final morning = _WirdCard(
      title: 'أذكار الصباح',
      blurb: controller.azkar.morning.blurb ?? '',
      icon: Icons.wb_sunny_rounded,
      done: completedItems(controller.state, controller.azkar.morning),
      total: controller.azkar.morning.items.length,
      onTap: () => onOpen('morning'),
    );
    final evening = _WirdCard(
      title: 'أذكار المساء',
      blurb: controller.azkar.evening.blurb ?? '',
      icon: Icons.nights_stay_rounded,
      done: completedItems(controller.state, controller.azkar.evening),
      total: controller.azkar.evening.items.length,
      onTap: () => onOpen('evening'),
    );
    if (!wide) {
      return Column(
        children: [
          morning,
          const SizedBox(height: 10),
          evening,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: morning),
        const SizedBox(width: 10),
        Expanded(child: evening),
      ],
    );
  }
}

class _WirdCard extends StatelessWidget {
  const _WirdCard({
    required this.title,
    required this.blurb,
    required this.icon,
    required this.done,
    required this.total,
    required this.onTap,
  });

  final String title;
  final String blurb;
  final IconData icon;
  final int done;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final finished = done == total && total > 0;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: finished ? AppColors.green : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: finished ? AppColors.done : AppColors.goldSoft,
                foregroundColor: AppColors.greenDark,
                child: Icon(finished ? Icons.check_rounded : icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.greenDark,
                      ),
                    ),
                    Text(
                      finished
                          ? 'اكتمل الورد'
                          : (blurb.isEmpty
                                ? fraction(done, total)
                                : '$blurb · ${fraction(done, total)}'),
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.done,
    required this.onTap,
    this.subtitle,
  });

  final AzkarCategory category;
  final int done;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final total = category.items.length;
    final finished = done == total && total > 0;
    final detail = subtitle ?? (finished ? 'تم' : fraction(done, total));
    return Material(
      color: finished ? AppColors.done : const Color(0xFF1AA888),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.35,
                  color: finished ? AppColors.greenDark : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: finished ? AppColors.green : const Color(0xFFE7FFF6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
