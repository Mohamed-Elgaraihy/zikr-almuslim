import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// A short vibration that does not depend on the system "touch feedback" toggle.
Future<void> lightTick({bool strong = false}) async {
  final duration = strong ? 40 : 25;
  final amplitude = strong ? 140 : 70;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Vibration.vibrate(duration: duration, amplitude: amplitude);
      return;
    } catch (_) {}
  }
  try {
    if (strong) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
  } catch (_) {}
}
