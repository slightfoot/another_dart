import 'package:another_dart/features/polygon/polygon_cache.dart';
import 'package:another_dart/utils/extensions.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:another_dart/features/polygon/polygon_offset.dart';
import 'package:another_dart/utils/data_buffer.dart';
import 'package:another_dart/features/renderer/drawable.dart';
import 'package:vector_math/vector_math.dart';

export 'package:another_dart/features/renderer/drawable.dart';

class PolygonParser {
  PolygonParser(this.data);

  final DataBuffer data;
  final _cache = PolygonCache();

  static Future<List<Polygon>> loadDemo(String assetData, String assetOffsets) async {
    final data = await rootBundle.load(assetData);
    final offsets = await PolygonOffset.load(assetOffsets);
    final parser = PolygonParser(DataBuffer(data));
    final polygons = <Polygon>[];
    for (final el in offsets) {
      final polygon = parser.parse(el.offset, 1.0);
      if (polygon != null) {
        polygons.add(polygon);
      }
    }
    return polygons;
  }

  Polygon? parse(int offset, double scale) {
    var polygon = _cache.get(offset, scale);
    if (polygon != null) {
      return polygon;
    }
    data.offset = offset;
    final builder = PolygonBuilder(offset, scale);
    _parseNode(builder, 0xff, Vector2.zero());
    polygon = builder.build();
    if (polygon != null) {
      _cache.add(polygon);
    }
    return polygon;
  }

  void _parseNode(PolygonBuilder builder, int color, Vector2 position) {
    var code = data.readByte();
    if (code >= 0xc0) {
      if ((color & 0x80) != 0) {
        color = code & 0x3f;
      }
      _parseLeaf(builder, color, position);
    } else {
      code &= 0x3f;
      if (code == 2) {
        _parseChildren(builder, position);
      } else {
        print('Warning: ${data.offset.toWordString()} ($code != 2)');
      }
    }
  }

  void _parseChildren(PolygonBuilder builder, Vector2 position) {
    final pos = position - _readPoint();
    final childCount = data.readByte();
    for (int i = 0; i <= childCount; i++) {
      final childOffset = data.readWord();
      final localPosition = _readPoint();
      final int color;
      if ((childOffset & 0x8000) != 0) {
        color = data.peekByte() & 0x7f;
        data.offset += 2;
      } else {
        color = 0xff;
      }
      final prevOffset = data.offset;
      data.offset = (childOffset & 0x7fff) * 2;
      _parseNode(builder, color, pos + localPosition);
      data.offset = prevOffset;
    }
  }

  void _parseLeaf(PolygonBuilder builder, int color, Vector2 center) {
    final size = _readPoint();
    final count = data.readByte();
    final position = Vector2(center.x - size.x / 2, center.y - size.y / 2);
    final points = List<Vector2>.generate(count, (_) => position + _readPoint());
    if (size.x == 0 && size.y <= 1 && count == 4) {
      builder.addPoint(Point(color, position));
    } else if ((size.x == 0 || size.y == 0) && (count == 2 || count == 4)) {
      final min = Vector2(double.infinity, double.infinity);
      final max = Vector2(double.negativeInfinity, double.negativeInfinity);
      for (final point in points) {
        Vector2.min(min, point, min);
        Vector2.max(max, point, max);
      }
      builder.addLine(Line(color, [min, max]));
    } else {
      builder.addShape(Shape(color, size, points));
    }
  }

  Vector2 _readPoint() {
    final x = data.readByte().toDouble();
    final y = data.readByte().toDouble();
    return Vector2(x, y);
  }
}
