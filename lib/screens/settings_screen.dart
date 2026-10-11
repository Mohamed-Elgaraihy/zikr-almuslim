import 'package:flutter/material.dart';

import '../content/info_copy.dart';
import '../logic/progress_logic.dart';
import '../services/device_bridge.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.palette.greenDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'يصل التذكير إذا حلّ الوقت ولم يُقرأ ورد الصباح أو المساء.',
          style: TextStyle(color: context.palette.inkSoft),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('تذكير يومي'),
                subtitle: Text('تنبيه للصباح والمساء إن لم يُقرأ الورد'),
                value: state.remindersOn,
                onChanged: (value) {
                  controller.setReminders(value);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('وقت أذكار الصباح'),
                trailing: Text(
                  formatClock(state.morningHour, state.morningMinute),
                ),
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
                title: Text('وقت أذكار المساء'),
                trailing: Text(
                  formatClock(state.eveningHour, state.eveningMinute),
                ),
                onTap: () => _pickTime(
                  context,
                  initial: TimeOfDay(
                    hour: state.eveningHour,
                    minute: state.eveningMinute,
                  ),
                  onPicked: controller.setEveningTime,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('العمل في الخلفية'),
                subtitle: const Text(
                  'بعض الأجهزة تجمّد التذكير. اسمح بالبطارية، ثم فعّل التشغيل التلقائي إن ظهرت قائمته.',
                ),
                onTap: controller.allowBackgroundReminders,
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
                          ok ? 'أُرسل تنبيه تجريبي' : 'لم يُسمح بالتنبيه. فعّله من المتصفح أو إعدادات الجهاز.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: Text('تجربة التنبيه'),
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
              Text(
                'الحجم الطبيعي ٢٨، ويمكن تكبيره أو تصغيره من هنا.',
                style: TextStyle(color: context.palette.inkSoft, height: 1.5),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('إظهار التشكيل'),
                subtitle: Text('إخفاؤه يترك الحروف بلا حركات'),
                value: state.showTashkeel,
                onChanged: controller.setShowTashkeel,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('الوضع الليلي'),
                subtitle: Text('خلفية داكنة للقراءة في الليل'),
                value: state.darkMode,
                onChanged: controller.setDarkMode,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نسخة على الجهاز',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: context.palette.greenDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تُحفظ السلسلة وورد اليوم في ملف عندك. لا تُرفع إلى أي خادم.',
                style: TextStyle(color: context.palette.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final shared = await DeviceBridge.shareText(
                      controller.backupText(),
                      subject: 'نسخة ذكر المسلم',
                      filename: 'zikr-backup.json',
                    );
                    if (!context.mounted || shared) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تعذّر تصدير النسخة من هذا الجهاز.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_rounded),
                  label: Text('تصدير النسخة'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _importBackup(context),
                  icon: const Icon(Icons.download_rounded),
                  label: Text('استيراد نسخة'),
                ),
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
                child: Text('تصفير عدّاد اليوم'),
              ),
            ],
          ),
        ),
      ],
        ),
      ),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    final picked = await DeviceBridge.pickText();
    if (!context.mounted) return;
    final text = (picked != null && picked.trim().isNotEmpty)
        ? picked
        : await _askPaste(context);
    if (!context.mounted || text == null || text.trim().isEmpty) return;
    final error = controller.restoreBackup(text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'استُعيدت النسخة على هذا الجهاز.')),
    );
  }

  Future<String?> _askPaste(BuildContext context) async {
    final field = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('لصق النسخة'),
          content: TextField(
            controller: field,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'الصق نص النسخة هنا'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, field.text),
              child: const Text('استيراد'),
            ),
          ],
        );
      },
    );
    field.dispose();
    return value;
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
              child: Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('تصفير'),
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
      leading: Icon(icon, color: context.palette.greenDark),
      title: Text(title),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (context) => InfoScreen(kind: kind)),
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
      color: context.palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.palette.line),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}
