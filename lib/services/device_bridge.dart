import 'device_bridge_io.dart'
    if (dart.library.js_interop) 'device_bridge_web.dart'
    as bridge;

class DeviceBridge {
  static Future<bool> shareText(
    String text, {
    String? subject,
    String? filename,
  }) {
    return bridge.shareText(text, subject: subject, filename: filename);
  }

  static Future<String?> pickText() => bridge.pickText();

  static Future<void> setAwake(bool on) => bridge.setAwake(on);

  static Future<void> updateWidget({
    required String day,
    required bool morningDone,
    required bool eveningDone,
  }) {
    return bridge.updateWidget(
      day: day,
      morningDone: morningDone,
      eveningDone: eveningDone,
    );
  }

  static Future<String?> takePendingSlot() => bridge.takePendingSlot();

  static void listen(void Function(String slot) onSlot) =>
      bridge.listen(onSlot);
}
