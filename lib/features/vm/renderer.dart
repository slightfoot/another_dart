import 'package:another_dart/app/strings.dart';
import 'package:another_dart/features/polygon/parser.dart';
import 'package:another_dart/features/renderer/display_list.dart';
import 'package:another_dart/features/renderer/display_list_intersect.dart';
import 'package:another_dart/features/renderer/display_paint.dart';
import 'package:another_dart/features/renderer/palette.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

typedef UpdateDisplayFn = void Function(VirtualRenderer renderer);

class VirtualRenderer {
  VirtualRenderer(this._updateDisplay) {
    reset();
  }

  late List<Palette> palettes;
  late PolygonParser polygons1;
  late PolygonParser? polygons2;

  final UpdateDisplayFn _updateDisplay;

  // Contains the display lists for each of the "frame buffers"
  late List<DisplayList> _displayLists;

  // [DisplayList] index which is currently being used for drawing.
  late int _displayList0 = 2;

  /// [DisplayList] index which is either background or display buffer.
  late int _displayList1 = 2;

  /// [DisplayList] index which is either background or display buffer.
  late int _displayList2 = 1;

  late int _paletteIndex = 0;

  DisplayList get activeDisplayList => _displayLists[_displayList1].clone();

  List<DisplayList> get displayLists {
    return <DisplayList>[
      _displayLists[1].clone(),
      _displayLists[2].clone(),
      _displayLists[0].clone(),
      _displayLists[3].clone(),
    ];
  }

  bool _drawHiResImages = false;

  set drawHiResImages(bool value) {
    _drawHiResImages = value;
  }

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

    final palette = palettes[_paletteIndex];
    for (final list in _displayLists) {
      list.palette = palette;
    }
    // _displayLists[_displayList1].palette = palette;

    updateDisplay();
  }

  void updateDisplay() {
    _updateDisplay(this);
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
    // final palette = palettes[_paletteIndex];
    // _displayLists[_displayList1].palette = palette;
  }

  void addFillPage(int pageOperand, int colorIndex) {
    final pageIndex = _pageIndexFromOperand(pageOperand);
    _displayLists[pageIndex].clear(colorIndex);
  }

  void addCopyPage(int srcOperand, int destOperand, int yOffset) {
    final dstPageIndex = _pageIndexFromOperand(destOperand);
    if (srcOperand == -1 || srcOperand == -2) {
      final srcPageIndex = _pageIndexFromOperand(srcOperand);
      _displayLists[dstPageIndex].copy(_displayLists[srcPageIndex], 0);
    } else {
      final srcPageIndex = _pageIndexFromOperand(srcOperand & 0x03);
      if (dstPageIndex == srcPageIndex) {
        return;
      }
      if ((srcOperand & 0x80) == 0) {
        yOffset = 0;
      }
      _displayLists[dstPageIndex].copy(_displayLists[srcPageIndex], yOffset);
    }
  }

  void _addCommand(DrawCommand command) {
    _displayLists[_displayList0].addCommand(command);
  }

  void addDrawString(int id, int x, int y, int colorIndex) {
    final text = langEn[id];
    if (text == null) {
      print('Failed to find string with id: $id');
      return;
    }
    // print('drawString: $id: $text');
    _addCommand(
      DrawStringCommand(text, Vector2(x.toDouble(), y.toDouble()), colorIndex),
    );
  }

  PolygonParser _polygonParserForSet(int polygonSet) {
    return (polygonSet == 0) ? polygons1 : polygons2!;
  }

  void addDrawPolygon(int polygonSet, int polygonOffset, int zoom, int x, int y) {
    final parser = _polygonParserForSet(polygonSet);
    final polygon = parser.parse(polygonOffset, zoom / 64.0);
    if (polygon != null) {
      final pos = Vector2(x.toDouble(), y.toDouble());
      final hasClone = polygon.drawables.any((el) => el.color == 0x11);
      if (hasClone) {
        _addCommand(DisplayListIntersect.intersect(_displayLists[0], polygon, pos,
            drawHiResImages: _drawHiResImages));
      } else {
        _addCommand(DrawPolygonCommand(polygon, pos));
      }
    }
  }

  void addDrawBitmap(int index) {
    precacheImage(index);
    _addCommand(DrawBitmapCommand(index));
  }
}
