import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

Future<void> offerStoreUpdate(BuildContext context) async {
  if (!Platform.isAndroid) return;
  try {
    final info = await InAppUpdate.checkForUpdate();
    final available =
        info.updateAvailability == UpdateAvailability.updateAvailable;
    if (!available || !context.mounted) return;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('يتوفر تحديث'),
          content: const Text(
            'نزلت نسخة أحدث على المتجر. حدّث التطبيق ليصلك التذكير وآخر الإصلاحات.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لاحقًا'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تحديث'),
            ),
          ],
        );
      },
    );
    if (agreed != true) return;
    if (info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
    } else if (info.flexibleUpdateAllowed) {
      await InAppUpdate.startFlexibleUpdate();
    }
  } catch (error) {
    debugPrint('store update check failed: $error');
  }
}
