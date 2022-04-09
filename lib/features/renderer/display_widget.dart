import 'dart:ui' as ui;

import 'package:another_dart/features/renderer/display_list.dart';
import 'package:another_dart/features/renderer/drawable.dart';
import 'package:flutter/widgets.dart';

@immutable
class DisplayWidget extends StatelessWidget {
  const DisplayWidget({
    super.key,
    required this.displayListNotifier,
  });

  final ValueNotifier<DisplayList> displayListNotifier;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DisplayListPainter(displayListNotifier),
      child: const SizedBox.expand(),
    );
  }
}

class _DisplayListPainter extends CustomPainter {
  _DisplayListPainter(this.displayListNotifier) : super(repaint: displayListNotifier);

  final ValueNotifier<DisplayList> displayListNotifier;

  @override
  bool shouldRepaint(covariant _DisplayListPainter oldDelegate) {
    return (displayListNotifier != oldDelegate.displayListNotifier);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320.0, size.height / 200.0);
    final displayList = displayListNotifier.value;
    for (final command in displayList.commands) {
      if (command is FillPageCommand) {
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = displayList.getColor(command.colorIndex),
        );
      } else if (command is DrawStringCommand) {
        // Text screen is 35x25 (or 9px x 8px cells)
        final style = ui.ParagraphStyle(
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          fontFamily: 'Courier New',
          fontSize: 200.0 / 25.0,
        );
        final builder = ui.ParagraphBuilder(style)
          ..pushStyle(ui.TextStyle(
            color: displayList.getColor(command.colorIndex),
            fontFeatures: [
              const ui.FontFeature.tabularFigures(),
            ],
          )) //
          ..addText(command.text)
          ..pop();
        final paragraph = builder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
        //print('drawString ${command.pos}: ${command.text}');
        canvas.drawParagraph(paragraph, Offset(command.pos.x, command.pos.y));
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
          final paint = Paint()
            ..color = displayList.getColor(drawable.color)
            ..style = PaintingStyle.fill;
          if (drawable is Shape) {
            final offsets = drawable.points.map((el) => Offset(el.x, el.y)).toList();
            final path = Path()..addPolygon(offsets, true);
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
    }
    canvas.restore();
  }

  void _drawString() {}
}
