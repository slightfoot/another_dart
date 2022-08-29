import 'dart:ui';

import 'package:another_dart/features/renderer/display_list.dart';
import 'package:another_dart/features/renderer/display_paint.dart';
import 'package:another_dart/features/renderer/drawable.dart';
import 'package:vector_math/vector_math.dart';

class DisplayListIntersect {
  static DrawClonedPolygonsCommand intersect(DisplayList source, Polygon intersection, Vector2 pos,
      {bool drawHiResImages = false}) {
    final polygonPath = intersection.getPath().shift(Offset(pos.x, pos.y));
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, polygonPath.getBounds());
    canvas.clipPath(polygonPath);
    source.paint(
      canvas,
      const Size(320.0, 200.0),
      drawHiResImages: drawHiResImages,
    );
    // canvas.drawPath(polygonPath, Paint()..color = const Color(0xffff0000));
    return DrawClonedPolygonsCommand(recorder.endRecording(), polygonPath);
  }
}
