import 'dart:async';
import 'dart:ui' as ui;

import 'package:another_dart/features/renderer/display_list.dart';
import 'package:another_dart/features/renderer/drawable.dart';
import 'package:charcode/charcode.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

@immutable
class DisplayWidget extends StatefulWidget {
  const DisplayWidget({
    super.key,
    required this.displayListNotifier,
  });

  final ValueNotifier<DisplayList> displayListNotifier;

  @override
  State<DisplayWidget> createState() => _DisplayWidgetState();
}

class _DisplayWidgetState extends State<DisplayWidget> {
  late Future _future;
  late ui.Image _font;

  @override
  void initState() {
    super.initState();
    _future = () async {
      final data = await rootBundle.load('assets/font.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frameInfo = await codec.getNextFrame();
      _font = frameInfo.image;
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox();
        }
        return CustomPaint(
          painter: _DisplayListPainter(widget.displayListNotifier, _font),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _DisplayListPainter extends CustomPainter {
  _DisplayListPainter(this.displayListNotifier, this.font) : super(repaint: displayListNotifier);

  final ValueNotifier<DisplayList> displayListNotifier;
  final ui.Image font;

  DisplayList get displayList => displayListNotifier.value;

  @override
  bool shouldRepaint(covariant _DisplayListPainter oldDelegate) {
    return (displayListNotifier != oldDelegate.displayListNotifier);
  }

  Color getColor(int colorIndex) {
    if (colorIndex > 0x10) {
      // debugPrint('Invalid Color: ${colorIndex.toRadixString(16).padLeft(2, '0')}');
    }
    return colorIndex == 0x10 // Semi-transparent.. guess fixed palette entry for now
        ? Color(displayList.palette!.colors[12]).withOpacity(0.5)
        : Color(displayList.palette!.colors[colorIndex & 0xf]);
  }

  Paint getPaintForColor(int colorIndex) {
    return Paint()
      ..color = getColor(colorIndex)
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320.0, size.height / 200.0);
    final displayList = displayListNotifier.value;
    for (final command in displayList.commands) {
      if (command is FillPageCommand) {
        canvas.drawRect(Offset.zero & size, getPaintForColor(command.colorIndex));
      } else if (command is DrawStringCommand) {
        _drawString(canvas, command, getColor(command.colorIndex));
      } else if (command is DrawBitmapCommand) {
        // canvas.drawImage();
      } else if (command is DrawPolygonCommand) {
        final polygon = command.polygon;
        canvas.save();
        canvas.translate(command.pos.x, command.pos.y);
        if (polygon.scale != 1.0) {
          canvas.scale(polygon.scale, polygon.scale);
        }
        for (final drawable in polygon.drawables) {
          if (drawable.color == 0x11) {
            // This color is used for a clone parts of the background buffer
            // in the display buffer.
            continue;
          }
          final paint = getPaintForColor(drawable.color);
          if (drawable is Shape) {
            final offsets = drawable.points.map((el) => Offset(el.x, el.y)).toList();
            final path = Path()..addPolygon(offsets, true);
            canvas.drawPath(path, paint);
            // _debugBorder(canvas, path);
          } else if (drawable is Point) {
            final offset = Offset(drawable.point.x - 0.5, drawable.point.y - 0.5);
            canvas.drawRect(offset & const Size(1, 1), paint);
          }
        }
        canvas.restore();
      }
    }
    canvas.restore();
  }

  void _debugBorder(Canvas canvas, Path path) {
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = const ui.Color(0x7f00ff00)
        ..style = ui.PaintingStyle.stroke,
    );
  }

  void _drawString(Canvas canvas, DrawStringCommand command, Color color) {
    final start = command.pos.x * 8;
    double x = start, y = command.pos.y;
    final chars = command.text.codeUnits;
    final transforms = <RSTransform>[];
    final rects = <Rect>[];
    for (final char in chars) {
      if (char == $lf) {
        y += 8;
        x = start;
      } else {
        transforms.add(RSTransform(0.5, 0.0, x, y));
        rects.add(Rect.fromLTWH((char % 16) * 16, (char ~/ 16) * 16, 16, 16));
        x += 8;
      }
    }
    final colors = List.generate(transforms.length, (_) => color);
    canvas.drawAtlas(font, transforms, rects, colors, BlendMode.dstIn, null, Paint());
  }
}
