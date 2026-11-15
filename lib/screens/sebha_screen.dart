import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/progress_logic.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class SebhaScreen extends StatelessWidget {
  const SebhaScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('السبحة')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final count = controller.state.sebhaCount;
          final target = controller.state.sebhaTarget;
          final reached = target > 0 && count > 0 && count % target == 0;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Text(
                    target == 0
                        ? 'عدّ حر بلا هدف'
                        : 'الهدف ${arabicDigits(target)}',
                    style: TextStyle(
                      color: context.palette.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _TargetChip(
                        label: 'بلا هدف',
                        selected: target == 0,
                        onTap: () => controller.setSebhaTarget(0),
                      ),
                      _TargetChip(
                        label: arabicDigits(33),
                        selected: target == 33,
                        onTap: () => controller.setSebhaTarget(33),
                      ),
                      _TargetChip(
                        label: arabicDigits(100),
                        selected: target == 100,
                        onTap: () => controller.setSebhaTarget(100),
                      ),
                      _TargetChip(
                        label: 'رقم آخر',
                        selected: target != 0 && target != 33 && target != 100,
                        onTap: () => _pickCustom(context),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    arabicDigits(count),
                    key: const ValueKey('sebha-count'),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: reached
                          ? context.palette.green
                          : context.palette.greenDark,
                    ),
                  ),
                  if (reached) ...[
                    const SizedBox(height: 8),
                    Text(
                      'تم الهدف',
                      style: TextStyle(
                        color: context.palette.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 88,
                    child: FilledButton(
                      key: const ValueKey('sebha-tap'),
                      onPressed: () {
                        controller.incrementSebha();
                        if (controller.state.hapticsOn) {
                          HapticFeedback.lightImpact();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('سبّح'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: controller.resetSebha,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('تصفير'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final field = TextEditingController(
      text: controller.state.sebhaTarget > 0
          ? '${controller.state.sebhaTarget}'
          : '',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('هدف السبحة'),
          content: TextField(
            controller: field,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'مثال: ٥٠'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(_westernDigits(field.text));
                Navigator.pop(context, parsed);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    field.dispose();
    if (value == null || value <= 0) return;
    controller.setSebhaTarget(value);
  }
}

String _westernDigits(String text) {
  const indic = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final index = indic.indexOf(char);
    if (index >= 0) {
      buffer.write(index);
    } else if (RegExp('[0-9]').hasMatch(char)) {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: context.palette.goldSoft,
      labelStyle: TextStyle(
        color: context.palette.ink,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
