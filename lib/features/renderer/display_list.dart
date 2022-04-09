import 'dart:ui' show Color;

import 'package:another_dart/features/renderer/drawable.dart';
import 'package:another_dart/features/renderer/palette.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:vector_math/vector_math.dart' show Vector2;

class DisplayList {
  final _commands = <DrawCommand>[];
  Palette? palette;

  List<DrawCommand> get commands => List.unmodifiable(_commands);

  Color getColor(int colorIndex) {
    if (colorIndex > 0x10) {
      // debugPrint('Invalid Color: ${colorIndex.toRadixString(16).padLeft(2, '0')}');
    }
    return colorIndex == 0x10 // Semi-transparent.. guess fixed palette entry for now
        ? Color(palette!.colors[12]).withOpacity(0.5)
        : Color(palette!.colors[colorIndex & 0xf]);
  }

  void clear(int colorIndex) {
    _commands.clear();
    _commands.add(FillPageCommand(colorIndex));
  }

  void addCommand(DrawCommand command) {
    _commands.add(command);
  }

  void copy(DisplayList source) {
    _commands.clear();
    _commands.addAll(source.commands);
    palette = source.palette;
  }
}

abstract class DrawCommand {
  //
}

class FillPageCommand implements DrawCommand {
  const FillPageCommand(this.colorIndex);

  final int colorIndex;
}

class DrawStringCommand implements DrawCommand {
  const DrawStringCommand(
    this.text,
    this.pos,
    this.colorIndex,
  );

  final String text;
  final Vector2 pos;
  final int colorIndex;
}

class DrawBitmapCommand implements DrawCommand {
  const DrawBitmapCommand(this.resourceIndex);

  final int resourceIndex;
}

class DrawPolygonCommand implements DrawCommand {
  const DrawPolygonCommand(
    this.polygon,
    this.color,
    this.pos,
  );

  final Polygon polygon;
  final int color;
  final Vector2 pos;
}
