import 'package:another_dart/features/renderer/drawable.dart';

class PolygonCache {
  final _cachedPolygons = <_PolygonCacheKey, Polygon>{};

  void add(Polygon polygon) {
    _cachedPolygons[_PolygonCacheKey(polygon.dataOffset, polygon.scale)] = polygon;
  }

  Polygon? get(int offset, double scale) {
    return _cachedPolygons[_PolygonCacheKey(offset, scale)];
  }
}

class _PolygonCacheKey {
  _PolygonCacheKey(this.offset, this.scale);

  final int offset;
  final double scale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PolygonCacheKey &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          scale == other.scale;

  @override
  int get hashCode => offset.hashCode ^ scale.hashCode;
}
