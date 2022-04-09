import 'dart:async';

import 'package:another_dart/features/polygon/parser.dart';
import 'package:flutter/material.dart';
import 'package:another_dart/app/asset.dart';
import 'package:another_dart/features/renderer/palette.dart';

@immutable
class PolygonViewer extends StatefulWidget {
  const PolygonViewer({super.key});

  @override
  State<PolygonViewer> createState() => _PolygonViewerState();
}

class _PolygonViewerState extends State<PolygonViewer> {
  Future<void>? _future;
  List<Polygon>? _polygons;
  List<Palette>? _palettes;
  AssetItem? _selected;
  Palette? _palette;

  Future<void> _parsePolygons() async {
    _polygons = await PolygonParser.loadDemo(
      'assets/${_selected!.polygon1}',
      'assets/offsets_16001.csv',
    );
    _palettes = await Palette.load('assets/${_selected!.palette}');
    _palette = _palettes![0];
    if (mounted) {
      setState(() {});
    }
    _future = null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: 12.0),
                DropdownButton<AssetItem>(
                  onChanged: (AssetItem? item) {
                    setState(() => _selected = item);
                  },
                  value: _selected,
                  items: [
                    for (final asset in assets) //
                      DropdownMenuItem(
                        value: asset,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          child: Text(asset.title),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16.0),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _future ??= _parsePolygons();
                    },
                    child: const Text('Parse Polygons'),
                  ),
                ),
                const SizedBox(width: 16.0),
                const SizedBox(
                  width: 1.0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                if (_palettes != null)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<Palette>(
                      onChanged: (Palette? palette) {
                        setState(() => _palette = palette);
                      },
                      value: _palette,
                      items: [
                        for (final palette in _palettes!) //
                          DropdownMenuItem(
                            value: palette,
                            child: PaletteDisplay(
                              palette: palette,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_polygons != null)
            Expanded(
              child: Builder(
                builder: (BuildContext context) {
                  final polygons = _polygons!;
                  return GridView.builder(
                    itemCount: polygons.length,
                    itemBuilder: (BuildContext context, int index) {
                      final polygon = polygons[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                polygon.description,
                                style: const TextStyle(fontSize: 11.0),
                              ),
                              const SizedBox(height: 8.0),
                              Expanded(
                                child: PolygonDisplay(
                                  polygon: polygon,
                                  palette: _palette!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400.0,
                      childAspectRatio: 1.0,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

@immutable
class PaletteDisplay extends StatelessWidget {
  const PaletteDisplay({
    super.key,
    required this.palette,
  });

  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < 8; i++) //
              PaletteColor(color: palette.colors[i]),
          ],
        ),
        Row(
          children: [
            for (int i = 8; i < 16; i++) //
              PaletteColor(color: palette.colors[i]),
          ],
        ),
      ],
    );
  }
}

@immutable
class PaletteColor extends StatelessWidget {
  const PaletteColor({
    super.key,
    required this.color,
  });

  final int color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(color),
      ),
      child: const SizedBox.square(
        dimension: kMinInteractiveDimension / 2,
      ),
    );
  }
}

@immutable
class PolygonDisplay extends StatelessWidget {
  const PolygonDisplay({
    super.key,
    required this.polygon,
    required this.palette,
  });

  final Polygon polygon;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final size = polygon.boundingBox.max - polygon.boundingBox.min;
    return FittedBox(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white38),
        child: Padding(
          padding: EdgeInsets.zero, // EdgeInsets.all(size.x * 0.05),
          child: SizedBox.fromSize(
            size: Size(size.x, size.y),
            child: CustomPaint(
              painter: _PolygonDisplayPainter(polygon, palette),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolygonDisplayPainter extends CustomPainter {
  _PolygonDisplayPainter(this.polygon, this.palette);

  final Polygon polygon;
  final Palette palette;

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white38);

    final center = size.center(Offset.zero);
    final boxCenter = polygon.boundingBox.center;
    canvas.save();
    canvas.translate(
      center.dx - boxCenter.x,
      center.dy - boxCenter.y,
    );
    if (polygon.scale != 1.0) {
      canvas.scale(polygon.scale, polygon.scale);
    }
    for (final drawable in polygon.drawables) {
      final color = drawable.color;
      final paint = Paint()
        ..color = color == 0x10 // Semi-transparent.. guess fixed palette entry for now
            ? Color(palette.colors[12]).withOpacity(0.5)
            : Color(palette.colors[color & 0xf])
        ..style = PaintingStyle.fill;
      if (drawable is Shape) {
        final offsets = drawable.points.map((el) => Offset(el.x, el.y)).toList();
        final path = Path()..addPolygon(offsets, true);
        if (color > 0x10) {
          debugPrint('Invalid Color: ${color.toRadixString(16).padLeft(2, '0')}');
        }
        canvas.drawPath(path, paint);
        //canvas.drawPath(
        //  path,
        //  ui.Paint()
        //    ..color = const ui.Color(0x7f000000)
        //    ..style = ui.PaintingStyle.stroke,
        //);
      } else if (drawable is Point) {
        final offset = Offset(drawable.point.x - 0.5, drawable.point.y - 0.5);
        canvas.drawRect(offset & const Size(1, 1), paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PolygonDisplayPainter oldDelegate) {
    return polygon != oldDelegate.polygon || palette != oldDelegate.palette;
  }
}
