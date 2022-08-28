import 'package:another_dart/features/renderer/drawable.dart';
import 'package:another_dart/features/renderer/palette.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

class DisplayList {
  final _commands = <DrawCommand>[];
  Palette? palette;

  List<DrawCommand> get commands => List.unmodifiable(_commands);

  void addCommand(DrawCommand command) {
    _commands.add(command);
  }

  void clear(int colorIndex) {
    _commands.clear();
    _commands.add(FillPageCommand(colorIndex));
  }

  void copy(DisplayList source) {
    _commands.clear();
    _commands.addAll(source.commands);
    palette = source.palette;
  }

  DisplayList clone() {
    final cloned = DisplayList();
    cloned._commands.addAll(_commands);
    cloned.palette = palette;
    return cloned;
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

  bool get isHighRes => (resourceIndex >= 3000);
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
