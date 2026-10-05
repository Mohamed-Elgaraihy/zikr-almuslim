import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'category_screen.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({
    super.key,
    required this.controller,
    this.enableTicker = true,
  });

  final AppController controller;
  final bool enableTicker;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onController);
    if (widget.enableTicker) {
      _ticker = Timer.periodic(const Duration(seconds: 45), (_) {
        widget.controller.syncReminders();
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.controller.removeListener(_onController);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.syncReminders(reschedule: true);
    }
  }

  void _onController() {
    final payload = widget.controller.pendingCategoryId;
    if (payload != null && mounted) {
      widget.controller.consumePendingCategory();
      _open(payload);
    }
    if (mounted) setState(() {});
  }

  void _open(String categoryId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            return CategoryScreen(
              controller: widget.controller,
              categoryId: categoryId,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(controller: widget.controller, onOpen: _open),
      DashboardScreen(controller: widget.controller, onOpen: _open),
      SettingsScreen(controller: widget.controller),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final destinations = const [
      (Icons.menu_book_rounded, 'الأذكار'),
      (Icons.today_rounded, 'اليوم'),
      (Icons.tune_rounded, 'الإعدادات'),
    ];

    if (widget.controller.loadError != null && widget.controller.library == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(widget.controller.loadError!),
          ),
        ),
      );
    }

    final body = IndexedStack(index: _index, children: pages);
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.card,
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppColors.greenDark),
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.$1),
                    label: Text(destination.$2),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.$1),
              label: destination.$2,
            ),
        ],
      ),
    );
  }
}
