import 'package:flutter/material.dart';

import '../logic/arabic_text.dart';
import '../logic/progress_logic.dart';
import '../models/azkar.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/pattern_painter.dart';
import '../widgets/placed_ad.dart';
import 'sebha_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onOpen,
    this.showAd = true,
  });

  final AppController controller;
  final void Function(String categoryId) onOpen;
  final bool showAd;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _searchKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _search.addListener(_onSearchChanged);
    _searchFocus.addListener(_onSearchFocus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.removeListener(_onSearchChanged);
    _searchFocus.removeListener(_onSearchFocus);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_searchFocus.hasFocus && _search.text.trim().isNotEmpty) {
      _revealResults();
    }
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {});
    if (_search.text.trim().isNotEmpty) _revealResults();
  }

  void _onSearchFocus() {
    if (_searchFocus.hasFocus) _revealResults();
  }

  void _revealResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _searchKey.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _clearSearch({bool unfocus = true}) {
    if (unfocus) _searchFocus.unfocus();
    if (_search.text.isEmpty) return;
    _search.clear();
  }

  void _open(String categoryId) {
    _clearSearch();
    widget.onOpen(categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final library = controller.library;
    if (library == null) {
      return const Center(child: Text('تعذّر تحميل الأذكار'));
    }
    final query = _search.text.trim();
    final width = MediaQuery.sizeOf(context).width;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(controller: controller)),
        if (controller.banners.isNotEmpty)
          SliverToBoxAdapter(
            child: _ReminderBanner(notices: controller.banners, onOpen: _open),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: _FeaturedRow(
              controller: controller,
              wide: width >= 720,
              onOpen: _open,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _SebhaEntry(controller: controller)),
        SliverToBoxAdapter(
          child: Padding(
            key: _searchKey,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              focusNode: _searchFocus,
              autofocus: false,
              scrollPadding: const EdgeInsets.only(top: 12, bottom: 240),
              textInputAction: TextInputAction.search,
              onTap: _revealResults,
              decoration: InputDecoration(
                hintText: 'ابحث في الأبواب أو نص الذكر',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح',
                        onPressed: () => _clearSearch(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: context.palette.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.palette.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.palette.line),
                ),
              ),
            ),
          ),
        ),
        if (query.isEmpty) ...[
          ..._groups(library, controller, width),
          if (widget.showAd)
            const SliverToBoxAdapter(
              child: PlacedAd(margin: EdgeInsets.fromLTRB(16, 28, 16, 8)),
            ),
        ] else
          ..._results(library, query),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  List<AzkarCategory> _gridCategories(AzkarLibrary library, String groupId) {
    return library
        .inGroup(groupId)
        .where(
          (category) => category.id != 'morning' && category.id != 'evening',
        )
        .toList();
  }

  List<Widget> _groups(
    AzkarLibrary library,
    AppController controller,
    double width,
  ) {
    final columns = width >= 1500
        ? 5
        : width >= 1200
        ? 4
        : width >= 800
        ? 3
        : 2;
    return [
      for (final group in library.groups)
        if (_gridCategories(library, group.id).isNotEmpty) ...[
          if (group.title.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Text(
                  group.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.palette.greenDark,
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
                final categories = _gridCategories(library, group.id);
                final category = categories[index];
                return _CategoryTile(
                  category: category,
                  done: completedItems(controller.state, category),
                  onTap: () => _open(category.id),
                );
              }, childCount: _gridCategories(library, group.id).length),
            ),
          ),
        ],
    ];
  }

  List<Widget> _results(AzkarLibrary library, String query) {
    final categories = library.categories.where((category) {
      return arabicContains(category.title, query) ||
          category.items.any(
            (item) =>
                arabicContains(item.text, query) ||
                (item.heading != null && arabicContains(item.heading!, query)),
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
            if (arabicContains(item.text, query)) {
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
              onTap: () => _open(category.id),
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
                  label: dayPhrase(streak),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.fingerprint_rounded,
                  label: '${tapPhrase(taps)} اليوم',
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
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _SebhaEntry extends StatelessWidget {
  const _SebhaEntry({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const ValueKey('open-sebha'),
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => SebhaScreen(controller: controller),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.brightness_low_rounded,
                  color: context.palette.green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السبحة',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: context.palette.greenDark,
                        ),
                      ),
                      Text(
                        'عدّ حر يحفظ على الجهاز',
                        style: TextStyle(
                          color: context.palette.ink,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: context.palette.greenDark,
                ),
              ],
            ),
          ),
        ),
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
        color: context.palette.alertWash,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onOpen(notice.payload),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: context.palette.alert,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تذكير',
                        style: TextStyle(
                          color: context.palette.alert,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(body),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: context.palette.alert),
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
      return Column(children: [morning, const SizedBox(height: 10), evening]);
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
      color: context.palette.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: finished ? context.palette.green : context.palette.line,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: finished
                    ? context.palette.done
                    : context.palette.goldSoft,
                foregroundColor: context.palette.greenDark,
                child: Icon(finished ? Icons.check_rounded : icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: context.palette.greenDark,
                      ),
                    ),
                    Text(
                      finished
                          ? 'اكتمل الورد'
                          : (blurb.isEmpty
                                ? fraction(done, total)
                                : '$blurb · ${fraction(done, total)}'),
                      style: TextStyle(
                        color: context.palette.inkSoft,
                        fontSize: 15,
                      ),
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
      color: finished ? context.palette.done : const Color(0xFF1AA888),
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
                  color: finished ? context.palette.greenDark : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: finished
                      ? context.palette.green
                      : const Color(0xFFE7FFF6),
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
