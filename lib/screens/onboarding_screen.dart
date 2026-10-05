import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _GuidePage(
      title: 'ذكر المسلم',
      body:
          'وردك اليومي من حصن المسلم في مكان واحد: أذكار الصباح والمساء، والنوم، والصلاة، وبقية أبواب يومك.',
    ),
    _GuidePage(
      title: 'عدّ بلمسة واحدة',
      body:
          'اضغط الدائرة الخضراء مرة لكل تسبيحة. أبقِ إصبعك عليها ليسرع العدّ حتى تظهر علامة الصح، ويمكنك إعادة الذكر متى شئت.',
    ),
    _GuidePage(
      title: 'لا يفوتك الورد',
      body:
          'شاشة اليوم تُريك ما تبقّى وكم يومًا واصلت. وإذا جاء وقت الصباح أو المساء ولم تقرأ، يصلك تذكير لطيف.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _last => _page == _pages.length - 1;

  void _next() {
    if (_last) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenDeep,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                child: _last
                    ? const SizedBox(height: 48)
                    : TextButton(
                        onPressed: widget.onDone,
                        child: const Text(
                          'تخطّي',
                          style: TextStyle(
                            color: AppColors.goldSoft,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  return _PageBody(page: _pages[index], index: index);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.gold : Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.goldSoft,
                    foregroundColor: AppColors.greenDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(_last ? 'ابدأ الورد' : 'التالي'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePage {
  const _GuidePage({required this.title, required this.body});

  final String title;
  final String body;
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page, required this.index});

  final _GuidePage page;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          if (index == 0) const BrandMark(size: 168) else _Illustration(index: index),
          const SizedBox(height: 36),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Color(0xFFD7E6DF),
              fontSize: 18,
              height: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final counting = index == 1;
    return Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 3),
      ),
      alignment: Alignment.center,
      child: counting
          ? const Text(
              '03',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: AppColors.goldSoft,
                height: 1,
              ),
            )
          : const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.goldSoft,
              size: 72,
            ),
    );
  }
}
