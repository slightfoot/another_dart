import 'package:flutter/services.dart' show rootBundle;
import 'package:another_dart/utils/data_buffer.dart';

class Palette {
  Palette(this.index, List<int> colors) //
      : colors = List.unmodifiable(colors);
  final int index;
  final List<int> colors;

  static Future<List<Palette>> load(String assetPath) async {
    final palette = DataBuffer(await rootBundle.load(assetPath));
    final count = palette.length ~/ 32; // 32 bytes per palette
    return List.generate(count, (index) {
      return Palette(
        index,
        List.generate(16, (_) {
          // RGB444 to ARGB888
          int color = palette.readWord();
          int r = (color >> 8) & 0xf;
          r = (r << 4) | r;
          int g = (color >> 4) & 0xf;
          g = (g << 4) | g;
          int b = color & 0xf;
          b = (b << 4) | b;
          return 0xff000000 | (r << 16) | (g << 8) | b;
        }),
      );
    });
  }
}
