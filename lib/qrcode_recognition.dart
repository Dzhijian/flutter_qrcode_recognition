import 'dart:async';

import 'package:flutter/services.dart';

class QrcodeRecognition {
  static const MethodChannel _channel =
      const MethodChannel('qrcode_recognition');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  // base64 || url || file path
  static Future<Map> recognition(dynamic img) async {
    var result = await _channel.invokeMethod('recognitionQrcode', img);
    return result;
  }
}
