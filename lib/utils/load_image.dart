import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

Future<ui.Image> loadImageAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}
