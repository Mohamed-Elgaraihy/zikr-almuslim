import 'dart:js_interop';

@JS('zikrShare')
external JSPromise<JSBoolean> _share(JSString text, JSString? filename);

@JS('zikrPick')
external JSPromise<JSString?> _pick();

@JS('zikrAwake')
external JSPromise<JSAny?> _awake(JSBoolean on);

Future<bool> shareText(String text, {String? subject, String? filename}) async {
  try {
    final shared = await _share(text.toJS, filename?.toJS).toDart;
    return shared.toDart;
  } catch (_) {
    return false;
  }
}

Future<String?> pickText() async {
  try {
    final value = await _pick().toDart;
    return value?.toDart;
  } catch (_) {
    return null;
  }
}

Future<void> setAwake(bool on) async {
  try {
    await _awake(on.toJS).toDart;
  } catch (_) {
    return;
  }
}

Future<void> updateWidget({
  required String day,
  required bool morningDone,
  required bool eveningDone,
}) async {}

Future<void> allowBackgroundReminders() async {}

Future<String?> takePendingSlot() async => null;

void listen(void Function(String slot) onSlot) {}
