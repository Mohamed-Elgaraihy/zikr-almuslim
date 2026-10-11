import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<bool>? _starting;

Future<bool> startMobileAds() {
  return _starting ??= _start();
}

Future<bool> _start() async {
  if (!Platform.isAndroid && !Platform.isIOS) return false;
  try {
    await MobileAds.instance.initialize();
    return true;
  } catch (error, stack) {
    debugPrint('mobile ads unavailable: $error\n$stack');
    return false;
  }
}
