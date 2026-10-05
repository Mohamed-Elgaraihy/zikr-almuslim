import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/shell_screen.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

class ZikrApp extends StatelessWidget {
  const ZikrApp({
    super.key,
    required this.controller,
    this.enableTicker = true,
  });

  final AppController controller;
  final bool enableTicker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ذكر المسلم',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: ShellScreen(
        controller: controller,
        enableTicker: enableTicker,
      ),
    );
  }
}
