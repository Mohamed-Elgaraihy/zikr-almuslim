import 'package:flutter/services.dart';

const _channel = MethodChannel('zikr/device');

Future<bool> shareText(String text, {String? subject, String? filename}) async {
  try {
    return await _channel.invokeMethod<bool>('share', {
          'text': text,
          'subject': subject,
          'filename': filename,
        }) ??
        false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

Future<String?> pickText() async {
  try {
    return await _channel.invokeMethod<String>('pickText');
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

Future<void> setAwake(bool on) async {
  try {
    await _channel.invokeMethod<void>('setAwake', {'on': on});
  } on MissingPluginException {
    return;
  } on PlatformException {
    return;
  }
}

Future<void> updateWidget({
  required String day,
  required bool morningDone,
  required bool eveningDone,
}) async {
  try {
    await _channel.invokeMethod<void>('updateWidget', {
      'day': day,
      'morningDone': morningDone,
      'eveningDone': eveningDone,
    });
  } on MissingPluginException {
    return;
  } on PlatformException {
    return;
  }
}

Future<void> allowBackgroundReminders() async {
  try {
    await _channel.invokeMethod<bool>('allowBackground');
  } on MissingPluginException {
    return;
  } on PlatformException {
    return;
  }
}

Future<String?> takePendingSlot() async {
  try {
    return await _channel.invokeMethod<String>('takePendingSlot');
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

void listen(void Function(String slot) onSlot) {
  _channel.setMethodCallHandler((call) async {
    if (call.method == 'openSlot' && call.arguments is String) {
      onSlot(call.arguments as String);
    }
  });
}
