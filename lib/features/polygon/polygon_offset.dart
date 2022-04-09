import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

const _csv = CsvToListConverter(shouldParseNumbers: false);

class PolygonOffset {
  const PolygonOffset(this.set, this.offset, this.palette);

  final int set;
  final int offset;
  final int palette;

  static Future<List<PolygonOffset>> load(String assetPath) async {
    final offsetsCsv = await rootBundle.loadString(assetPath);
    final offsets = _csv
        .convert<String>(offsetsCsv) //
        .mapIndexed((i, el) {
          try {
            return PolygonOffset(int.parse(el[0]), int.parse(el[1]), int.parse(el[2]));
          } catch (e) {
            debugPrint('Failed to parse on line: $i: $e');
            return null;
          }
        })
        .whereType<PolygonOffset>()
        .toList();
    return offsets;
  }
}
