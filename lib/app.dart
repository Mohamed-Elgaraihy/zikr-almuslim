import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'navigation/app_route_observer.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'services/store_update.dart';
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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'ذكر المسلم - ZikrAlmuslim',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          darkTheme: buildTheme(dark: true),
          themeMode: controller.state.darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          navigatorObservers: [appRouteObserver],
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: _LaunchHost(
            controller: controller,
            enableTicker: enableTicker,
          ),
        );
      },
    );
  }
}

class _LaunchHost extends StatefulWidget {
  const _LaunchHost({required this.controller, required this.enableTicker});

  final AppController controller;
  final bool enableTicker;

  @override
  State<_LaunchHost> createState() => _LaunchHostState();
}

class _LaunchHostState extends State<_LaunchHost> {
  var _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  Future<void> _ask() async {
    if (_asked || !mounted) return;
    _asked = true;
    await widget.controller.prepareLaunch();
    if (!mounted) return;
    await offerStoreUpdate(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !widget.controller.state.onboardingSeen) {
      return OnboardingScreen(onDone: widget.controller.completeOnboarding);
    }
    return ShellScreen(
      controller: widget.controller,
      enableTicker: widget.enableTicker,
    );
  }
}
