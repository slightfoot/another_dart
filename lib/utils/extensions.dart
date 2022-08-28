import 'package:another_dart/features/renderer/drawable.dart';
import 'package:flutter/painting.dart';

extension HexFormat on int {
  String toHexString(int bitLength) => '0x${toRadixString(16).padLeft(bitLength ~/ 4, '0')}';

  String toByteString() => toHexString(8);

  String toWordString() => toHexString(16);
}

extension PointRect on Point {
  Rect getRect() {
    return Offset(point.x - 0.5, point.y - 0.5) & const Size(1, 1);
  }
}

extension ShapePath on Shape {
  Path getPath() {
    final offsets = points.map((el) => Offset(el.x, el.y)).toList();
    return Path()..addPolygon(offsets, true);
  }
}

extension PolygonPath on Polygon {
  Path getPath() {
    Path path = Path();
    for (final drawable in drawables) {
      if (drawable is Shape) {
        path = Path.combine(PathOperation.union, path, drawable.getPath());
      } else if (drawable is Point) {
        path.addRect(drawable.getRect());
      }
    }
    return path;
  }
}
