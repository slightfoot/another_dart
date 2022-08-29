import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:another_dart/utils/extensions.dart';
import 'package:vector_math/vector_math.dart';

abstract class Drawable {
  int get color;
}

class Point extends Drawable {
  Point(this.color, this.point);

  @override
  final int color;

  final Vector2 point;

  ui.Rect? _cached;

  ui.Rect getRect() {
    return _cached ??= (ui.Offset(point.x - 0.5, point.y - 0.5) & const ui.Size(1, 1));
  }
}

class Shape extends Drawable {
  Shape(this.color, this.size, List<Vector2> points) //
      : points = List.unmodifiable(points);

  @override
  final int color;

  final Vector2 size;
  final List<Vector2> points;

  ui.Path? _cached;

  ui.Path getPath() {
    return _cached ??= ui.Path()
      ..addPolygon(points.map((el) => ui.Offset(el.x, el.y)).toList(), true);
  }
}

class Polygon {
  Polygon(this.dataOffset, this.scale, this.drawables, this.boundingBox);

  final int dataOffset;
  final double scale;
  final List<Drawable> drawables;
  final Aabb2 boundingBox;

  String get description {
    return '${dataOffset.toWordString()} :: count:${drawables.length} :: box:${boundingBox.min} - ${boundingBox.max}';
  }

  ui.Path? _cached;

  ui.Path getPath() {
    if (_cached == null) {
      var path = ui.Path();
      for (final drawable in drawables) {
        if (drawable is Shape) {
          path = ui.Path.combine(ui.PathOperation.union, path, drawable.getPath());
        } else if (drawable is Point) {
          path.addRect(drawable.getRect());
        }
      }
      _cached = path;
    }
    return _cached!;
  }
}

class PolygonBuilder {
  PolygonBuilder(this._offset, this._scale);

  final int _offset;
  final double _scale;
  final _half = Vector2(0.5, 0.5);
  final _drawables = <Drawable>[];
  final _min = Vector2(double.infinity, double.infinity);
  final _max = Vector2(double.negativeInfinity, double.negativeInfinity);

  void addPoint(Point point) {
    Vector2.min(point.point - _half, _min, _min);
    Vector2.max(point.point + _half, _max, _max);
    _drawables.add(point);
  }

  void addShape(Shape shape) {
    for (final point in shape.points) {
      Vector2.min(point, _min, _min);
      Vector2.max(point, _max, _max);
    }
    _drawables.add(shape);
  }

  Polygon? build() {
    if (_drawables.isEmpty) {
      debugPrint('Failed to add polygon for offset: ${_offset.toWordString()}');
      return null;
    }
    final box = Aabb2.minMax(_min, _max);
    return Polygon(_offset, _scale, List.unmodifiable(_drawables), box);
  }
}
