import 'dart:ui' as ui;

import 'package:another_dart/features/renderer/display_list.dart';
import 'package:another_dart/features/renderer/drawable.dart';
import 'package:another_dart/utils/load_image.dart';
import 'package:charcode/charcode.dart';
import 'package:flutter/widgets.dart';

final _imageCache = <int, ui.Image>{};

Future<void> precacheImage(int index) async {
  if (!_imageCache.containsKey(index)) {
    try {
      String fileName;
      if (index >= 3000) {
        fileName = 'highres/e$index.png';
      } else {
        fileName = 'original/file${index.toString().padLeft(3, '0')}.png';
      }
      final image = await loadImageAsset('assets/images/$fileName');
      _imageCache[index] = image;
    } catch (error) {
      print('Failed to pre-cache bitmap $index: $error');
    }
  }
}

@immutable
class DisplayListPaint extends StatelessWidget {
  const DisplayListPaint({
    super.key,
    required this.displayList,
    required this.font,
    this.showBorder = false,
    this.drawHiResImages = false,
  });

  final DisplayList displayList;
  final ui.Image font;
  final bool showBorder;
  final bool drawHiResImages;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DisplayListPainter(
        displayList,
        font,
        showBorder,
        drawHiResImages,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DisplayListPainter extends CustomPainter {
  _DisplayListPainter(
    this.displayList,
    this.font,
    this.showBorder,
    this.drawHiResImages,
  ) : super();

  final DisplayList displayList;
  final ui.Image font;
  final bool showBorder;
  final bool drawHiResImages;

  @override
  bool shouldRepaint(covariant _DisplayListPainter oldDelegate) {
    return (displayList != oldDelegate.displayList || font != oldDelegate.font);
  }

  Color getColor(int colorIndex) {
    if (colorIndex > 0x10) {
      // debugPrint('Invalid Color: ${colorIndex.toRadixString(16).padLeft(2, '0')}');
    }
    if (displayList.palette == null) {
      return const Color(0xff000000);
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
    canvas.clipRect(Offset.zero & size);
    try {
      canvas.scale(size.width / 320.0, size.height / 200.0);
      for (final command in displayList.commands) {
        if (command is FillPageCommand) {
          canvas.drawRect(Offset.zero & size, getPaintForColor(command.colorIndex));
        } else if (command is DrawStringCommand) {
          _drawString(canvas, command, getColor(command.colorIndex));
        } else if (command is DrawBitmapCommand) {
          if (!drawHiResImages && command.isHighRes) {
            continue;
          }
          final image = _imageCache[command.resourceIndex];
          if (image != null) {
            final src = Rect.fromLTWH(0.0, 0.0, image.width.toDouble(), image.height.toDouble());
            const dst = Rect.fromLTWH(0.0, 0.0, 320.0, 200.0);
            canvas.drawImageRect(image, src, dst, Paint());
          }
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
              if (showBorder) {
                _debugBorder(canvas, path, getColor(drawable.color));
              }
            } else if (drawable is Point) {
              final offset = Offset(drawable.point.x - 0.5, drawable.point.y - 0.5);
              canvas.drawRect(offset & const Size(1, 1), paint);
            }
          }
          canvas.restore();
        }
      }
    } catch (error, stackTrace) {
      print('$error\n$stackTrace');
    }
    canvas.restore();
  }

  void _debugBorder(Canvas canvas, Path path, Color color) {
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = HSVColor.fromColor(color).withValue(1.0).toColor().withOpacity(0.5)
        ..strokeWidth = 0.2
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
