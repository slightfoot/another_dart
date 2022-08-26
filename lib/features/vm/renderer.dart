import 'package:another_dart/app/strings_en.dart';
import 'package:another_dart/features/polygon/parser.dart';
import 'package:another_dart/features/renderer/display_list.dart';
import 'package:another_dart/features/renderer/palette.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

typedef UpdateDisplayFn = void Function(DisplayList displayList);

class VirtualRenderer {
  VirtualRenderer(this.updateDisplay) {
    reset();
  }

  List<String>? text;
  late List<Palette> palettes;
  late PolygonParser polygons1;
  late PolygonParser? polygons2;

  final UpdateDisplayFn updateDisplay;

  // Contains the display lists for each of the "frame buffers"
  late List<DisplayList> _displayLists;

  // [DisplayList] index which is currently being used for drawing.
  late int _displayList0 = 2;

  /// [DisplayList] index which is either background or display buffer.
  late int _displayList1 = 2;

  /// [DisplayList] index which is either background or display buffer.
  late int _displayList2 = 1;

  late int _paletteIndex = 0;

  void reset() {
    _displayLists = List.generate(4, (_) => DisplayList());
    _displayList0 = 0;
    _displayList1 = 2;
    _displayList2 = 1;
    _paletteIndex = 0;
  }

  void swapBuffers(int pageOperand) {
    if (pageOperand != -2) {
      if (pageOperand == -1) {
        // Swap _displayList1 and _displayList2
        final temp = _displayList1;
        _displayList1 = _displayList2;
        _displayList2 = temp;
      } else {
        _displayList1 = _pageIndexFromOperand(pageOperand);
      }
    }
    _displayLists[_displayList1].palette = palettes[_paletteIndex];
    updateDisplay(_displayLists[_displayList1]);
  }

  int _pageIndexFromOperand(int pageOperand) {
    if (pageOperand == -1) {
      return _displayList2;
    } else if (pageOperand == -2) {
      return _displayList1;
    } else {
      assert(pageOperand <= 3);
      return pageOperand;
    }
  }

  void setPalette(int paletteIndex) {
    _paletteIndex = paletteIndex;
  }

  void selectPage(int pageOperand) {
    _displayList0 = _pageIndexFromOperand(pageOperand);
  }

  void fillPage(int pageOperand, int colorIndex) {
    final pageIndex = _pageIndexFromOperand(pageOperand);
    _displayLists[pageIndex].clear(colorIndex);
  }

  void copyPage(int srcOperand, int destOperand, int yOffset) {
    final dstPageIndex = _pageIndexFromOperand(destOperand);
    if (srcOperand == -1 || srcOperand == -2) {
      final srcPageIndex = _pageIndexFromOperand(srcOperand);
      _displayLists[dstPageIndex].copy(_displayLists[srcPageIndex]);
    } else {
      final srcPageIndex = _pageIndexFromOperand(srcOperand & 0x03);
      if (dstPageIndex == srcPageIndex) {
        return;
      }
      if ((srcOperand & 0x80) == 0) {
        yOffset = 0;
      }
      // FIXME: also deal with yOffset
      _displayLists[dstPageIndex].copy(_displayLists[srcPageIndex]);
    }
  }

  void _addCommand(DrawCommand command) {
    _displayLists[_displayList0].addCommand(command);
  }

  void drawString(int index, int x, int y, int colorIndex) {
    final text = strings_en[index];
    if (text == null) {
      print('Failed to load string: $index');
      return;
    }
    _addCommand(
      DrawStringCommand(strings_en[index]!, Vector2(x.toDouble(), y.toDouble()), colorIndex),
    );
  }

  PolygonParser _polygonParserForSet(int polygonSet) {
    return (polygonSet == 0) ? polygons1 : polygons2!;
  }

  void drawPolygon(int polygonSet, int polygonOffset, int color, int zoom, int x, int y) {
    final parser = _polygonParserForSet(polygonSet);
    final polygon = parser.parse(polygonOffset, zoom / 64.0);
    if (polygon != null) {
      _addCommand(DrawPolygonCommand(polygon, color, Vector2(x.toDouble(), y.toDouble())));
    }
  }

  void drawBitmap(int resourceIndex) {
    _addCommand(DrawBitmapCommand(resourceIndex));
  }
}
