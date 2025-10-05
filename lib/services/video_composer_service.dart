import 'package:flutter/services.dart';

class VideoComposerService {
  static const MethodChannel _channel = MethodChannel('com.clipflow/video_composer');

  // Kotlinで実装したcomposeVideos関数を呼び出し
  static Future<bool> composeVideos({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('composeVideos', {
        'inputPaths': inputPaths,
        'outputPath': outputPath,
      });
      return result;
    } catch (e) {
      print('VideoComposerService error: $e');
      return false;
    }
  }
}