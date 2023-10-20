import 'dart:io';
import 'dart:ui' as ui;

import 'package:another_dart/features/renderer/display_list.dart';
import 'package:another_dart/features/renderer/drawable.dart';
import 'package:another_dart/utils/load_image.dart';
import 'package:charcode/charcode.dart';
import 'package:flutter/widgets.dart';

final _imageCache = <int, ui.Image>{};

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

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 320.0, size.height / 200.0);
    displayList.paint(
      canvas,
      size,
      font: font,
      showBorder: showBorder,
      drawHiResImages: drawHiResImages,
    );
    canvas.restore();
  }
}

extension ExtDisplayListPaint on DisplayList {
  void paint(
    Canvas canvas,
    Size size, {
    ui.Image? font,
    bool showBorder = false,
    bool drawHiResImages = false,
  }) {
    canvas.save();
    try {
      for (final command in commands) {
        if (command is DrawClonedPolygonsCommand) {
          canvas.drawPicture(command.picture);
          if (showBorder) {
            final paint = _borderPaint(const Color(0xffff0000));
            canvas.drawPath(command.outline, paint);
          }
        } else if (command is DrawPolygonCommand) {
          command.polygon
              .paint(canvas, command.pos.x, command.pos.y, lookupColor, showBorder: showBorder);
        } else if (command is FillPageCommand) {
          canvas.drawRect(
            Offset.zero & size,
            Paint()
              ..color = lookupColor(command.colorIndex)
              ..style = PaintingStyle.fill,
          );
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
        } else if (command is DrawStringCommand) {
          if (font != null) {
            _drawString(canvas, command, font, lookupColor(command.colorIndex));
          }
        } else if (command is VerticalOffsetCommand) {
          canvas.translate(0.0, command.yOffset.toDouble());
        }
      }
    } catch (error, stackTrace) {
      print('$error\n$stackTrace');
    }
    canvas.restore();
  }

  Color lookupColor(int colorIndex) {
    if (palette == null) {
      return const Color(0xff000000);
    }
    return colorIndex == 0x10 // Semi-transparent.. guess fixed palette entry for now
        ? Color(palette!.colors[12]).withOpacity(0.5)
        : Color(palette!.colors[colorIndex & 0xf]);
  }

  void _drawString(Canvas canvas, DrawStringCommand command, ui.Image font, Color color) {
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
        transforms.add(RSTransform(0.5, 0.0, x + 0.5, y + 0.5));
        rects.add(Rect.fromLTWH((char % 16) * 16, (char ~/ 16) * 16, 16, 16));
        x += 8;
      }
    }
    final colors = List.generate(transforms.length, (_) => color);
    canvas.drawAtlas(font, transforms, rects, colors, BlendMode.dstIn, null, Paint());
  }
}

typedef ColorLookup = Color Function(int color);

extension ExtPolygonPaint on Polygon {
  void paint(Canvas canvas, double x, double y, ColorLookup lookupColor,
      {bool showBorder = false}) {
    canvas.save();
    canvas.translate(x, y);
    if (scale != 1.0) {
      canvas.scale(scale, scale);
    }
    for (final drawable in drawables) {
      if (drawable.color >= 0x11) {
        // this should never happen
        continue;
      }
      final paint = Paint()
        ..color = lookupColor(drawable.color)
        ..style = PaintingStyle.fill;
      if(drawable.color == 0x10) {
        paint.blendMode = BlendMode.screen;
      }
      if (drawable is Shape) {
        final path = drawable.getPath();
        canvas.drawPath(path, paint);
        if (showBorder) {
          canvas.drawPath(path, _borderPaint(lookupColor(drawable.color)));
        }
      } else if (drawable is Line) {
        final pt0 = drawable.points[0];
        final pt1 = drawable.points[1];
        canvas.drawLine(
          Offset(pt0.x, pt0.y),
          Offset(pt1.x, pt1.y),
          Paint()
            ..color = lookupColor(drawable.color)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke,
        );
      } else if (drawable is Point) {
        final rect = drawable.getRect();
        canvas.drawRect(rect, paint);
        if (showBorder) {
          canvas.drawRect(rect, _borderPaint(lookupColor(drawable.color)));
        }
      }
    }
    canvas.restore();
  }
}

Paint _borderPaint(Color color) {
  return Paint()
    ..color = HSVColor.fromColor(color).withValue(1.0).toColor().withOpacity(0.5)
    ..strokeWidth = 0.2
    ..style = PaintingStyle.stroke;
}

String _imagePath(int index) {
  String fileName;
  if (index >= 3000) {
    fileName = 'highres/e$index.png';
  } else {
    fileName = 'original/file${index.toString().padLeft(3, '0')}.png';
  }
  return 'assets/images/$fileName';
}

Future<void> precacheHiresImages() async {
  for (int index = 3000; index < 3400; index++) {
    if (await File(_imagePath(index)).exists()) {
      precacheImage(index);
    }
  }
}

Future<void> precacheImage(int index) async {
  if (!_imageCache.containsKey(index)) {
    try {
      final image = await loadImageAsset(_imagePath(index));
      _imageCache[index] = image;
    } catch (error) {
      print('Failed to pre-cache bitmap $index: $error');
    }
  }
}
