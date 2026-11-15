import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

import '../theme/app_theme.dart';

const playPackageId = 'com.zikralmuslim.zikr_almuslim';
const playMarketListing = 'market://details?id=$playPackageId';
const playHttpsListing =
    'https://play.google.com/store/apps/details?id=$playPackageId';

enum _UpdateAttempt { updated, stillRequired, checkFailed }

/// Blocks the app when Play has a newer build, and stays out of the way when
/// the Play API itself cannot run (sideload, debug, offline, or no Play Store).
class PlayUpdateGuard extends StatefulWidget {
  const PlayUpdateGuard({super.key, required this.child});

  final Widget child;

  @override
  State<PlayUpdateGuard> createState() => _PlayUpdateGuardState();
}

class _PlayUpdateGuardState extends State<PlayUpdateGuard>
    with WidgetsBindingObserver {
  var _blocked = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_busy || !mounted || !Platform.isAndroid) return;
    _busy = true;
    try {
      final attempt = await _attemptImmediate();
      if (!mounted) return;
      setState(() => _blocked = attempt == _UpdateAttempt.stillRequired);
    } finally {
      _busy = false;
    }
  }

  Future<void> _retryFromWall() async {
    if (_busy) return;
    _busy = true;
    try {
      final attempt = await _attemptImmediate();
      if (!mounted) return;
      if (attempt == _UpdateAttempt.checkFailed ||
          attempt == _UpdateAttempt.updated) {
        setState(() => _blocked = false);
        return;
      }
      setState(() => _blocked = true);
      await _openStoreListing();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blocked) {
      return _UpdateWall(onUpdate: _retryFromWall);
    }
    return widget.child;
  }
}

Future<_UpdateAttempt> _attemptImmediate() async {
  try {
    final info = await InAppUpdate.checkForUpdate();
    final inProgress =
        info.updateAvailability ==
        UpdateAvailability.developerTriggeredUpdateInProgress;
    final available =
        info.updateAvailability == UpdateAvailability.updateAvailable ||
        inProgress;
    if (!available) return _UpdateAttempt.updated;
    if (info.immediateUpdateAllowed || inProgress) {
      final result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.success) return _UpdateAttempt.updated;
      return _UpdateAttempt.stillRequired;
    }
    return _UpdateAttempt.stillRequired;
  } catch (error) {
    debugPrint('play update check failed: $error');
    return _UpdateAttempt.checkFailed;
  }
}

Future<void> _openStoreListing() async {
  const channel = MethodChannel('zikr/links');
  try {
    final opened =
        await channel.invokeMethod<bool>('open', {'url': playMarketListing}) ??
        false;
    if (opened) return;
  } catch (_) {}
  try {
    await channel.invokeMethod<bool>('open', {'url': playHttpsListing});
  } catch (_) {}
}

class _UpdateWall extends StatelessWidget {
  const _UpdateWall({required this.onUpdate});

  final Future<void> Function() onUpdate;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.greenDeep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.goldSoft,
                  size: 72,
                ),
                const SizedBox(height: 24),
                const Text(
                  'يوجد تحديث جديد ولازم تحدّث التطبيق عشان تكمل',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onUpdate,
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
                    child: const Text('تحديث الآن'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
