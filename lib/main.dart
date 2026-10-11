import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  try {
    await controller.bootstrap();
  } catch (error, stack) {
    debugPrint('bootstrap failed: $error\n$stack');
  }
  runApp(ZikrApp(controller: controller));
}
