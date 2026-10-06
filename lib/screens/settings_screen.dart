import 'package:flutter/material.dart';

import '../content/info_copy.dart';
import '../logic/progress_logic.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final library = controller.library;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.greenDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'يصل التذكير إذا حلّ الوقت ولم يُقرأ ورد الصباح أو المساء.',
          style: TextStyle(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تذكير يومي'),
                subtitle: const Text('تنبيه للصباح والمساء إن لم يُقرأ الورد'),
                value: state.remindersOn,
                onChanged: (value) {
                  controller.setReminders(value);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('وقت أذكار الصباح'),
                trailing: Text(formatClock(state.morningHour, state.morningMinute)),
                onTap: () => _pickTime(
                  context,
                  initial: TimeOfDay(
                    hour: state.morningHour,
                    minute: state.morningMinute,
                  ),
                  onPicked: controller.setMorningTime,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('وقت أذكار المساء'),
                trailing: Text(formatClock(state.eveningHour, state.eveningMinute)),
                onTap: () => _pickTime(
                  context,
                  initial: TimeOfDay(
                    hour: state.eveningHour,
                    minute: state.eveningMinute,
                  ),
                  onPicked: controller.setEveningTime,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await controller.sendTestNotification();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'أُرسل تنبيه تجريبي'
                              : 'لم يُسمح بالتنبيه. فعّله من المتصفح أو إعدادات الجهاز.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: const Text('تجربة التنبيه'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('حجم خط الذكر: ${state.fontSize.round()}'),
              const SizedBox(height: 4),
              const Text(
                'الحجم الطبيعي ٢٨، ويمكن تكبيره أو تصغيره من هنا.',
                style: TextStyle(color: AppColors.inkSoft, height: 1.5),
              ),
              Slider(
                value: state.fontSize,
                min: kMinDhikrFontSize,
                max: kMaxDhikrFontSize,
                divisions: (kMaxDhikrFontSize - kMinDhikrFontSize).round(),
                label: '${state.fontSize.round()}',
                onChanged: controller.setFontSize,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.menu_book_outlined,
                title: 'عن التطبيق',
                kind: InfoKind.about,
              ),
              _InfoTile(
                icon: Icons.person_outline_rounded,
                title: 'من نحن',
                kind: InfoKind.developer,
              ),
              _InfoTile(
                icon: Icons.privacy_tip_outlined,
                title: 'سياسة الخصوصية',
                kind: InfoKind.privacy,
              ),
              _InfoTile(
                icon: Icons.gavel_rounded,
                title: 'شروط الاستخدام',
                kind: InfoKind.terms,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () => _confirm(
                  context,
                  title: 'تصفير اليوم؟',
                  body: 'تُمسح عدّادات اليوم ويبقى سجل الأيام السابقة.',
                  action: controller.clearToday,
                ),
                child: const Text('تصفير عدّاد اليوم'),
              ),
              if (library != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    library.source,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      height: 1.6,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay initial,
    required Future<void> Function(int hour, int minute) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    await onPicked(picked.hour, picked.minute);
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required VoidCallback action,
  }) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تصفير'),
            ),
          ],
        );
      },
    );
    if (approved == true) action();
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.kind,
  });

  final IconData icon;
  final String title;
  final InfoKind kind;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.greenDark),
      title: Text(title),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => InfoScreen(kind: kind),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}
