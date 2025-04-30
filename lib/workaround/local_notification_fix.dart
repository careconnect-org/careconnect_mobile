import 'package:flutter/services.dart';

/// Temporary workaround for flutter_local_notifications namespace issue
class LocalNotificationsFixPlugin {
  static const MethodChannel _channel =
      MethodChannel('local_notifications_fix');

  static Future<void> initialize() async {
    try {
      // This is just a placeholder - the method doesn't actually need to do anything
      await _channel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      print(
          'Failed to initialize local notifications workaround: ${e.message}');
    }
  }
}
