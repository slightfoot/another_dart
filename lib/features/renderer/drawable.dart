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
}

class Shape extends Drawable {
  Shape(this.color, this.size, List<Vector2> points) //
      : points = List.unmodifiable(points);

  @override
  final int color;

  final Vector2 size;
  final List<Vector2> points;
}

class Polygon {
  const Polygon(this.dataOffset, this.scale, this.drawables, this.boundingBox);

  final int dataOffset;
  final double scale;
  final List<Drawable> drawables;
  final Aabb2 boundingBox;

  String get description {
    return '${dataOffset.toWordString()} :: count:${drawables.length} :: box:${boundingBox.min} - ${boundingBox.max}';
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
