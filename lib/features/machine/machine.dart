import 'dart:ui' as ui;

import 'package:another_dart/features/renderer/display_list.dart';
import 'package:another_dart/features/machine/font_loader.dart';
import 'package:another_dart/features/renderer/display_paint.dart';
import 'package:another_dart/features/viewer/palette_preview.dart';
import 'package:another_dart/features/vm/machine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide FontLoader;

final _partNames = <String>[
  'Intro',
  'Arrival',
  'Jail',
  'City',
  'Arena',
  'Baths',
  'End',
];

@immutable
class MachineWidget extends StatefulWidget {
  const MachineWidget({super.key});

  @override
  State<MachineWidget> createState() => _MachineWidgetState();
}

class _MachineWidgetState extends State<MachineWidget> {
  final _displayList0 = ValueNotifier(DisplayList());
  final _displayList1 = ValueNotifier(DisplayList());
  final _displayList2 = ValueNotifier(DisplayList());
  final _displayList3 = ValueNotifier(DisplayList());
  late VirtualMachine _machine;

  var _debugMode = false;
  var _showBorder = false;
  var _drawHiResImages = false;

  late final _shortcuts = <ShortcutActivator, VoidCallback>{
    LogicalKeySet(LogicalKeyboardKey.keyD): _onDebugPressed,
    LogicalKeySet(LogicalKeyboardKey.keyB): _onShowBorderPressed,
    LogicalKeySet(LogicalKeyboardKey.keyH): _onDrawHiResPressed,
    LogicalKeySet(LogicalKeyboardKey.keyM): _onMutePressed,
    LogicalKeySet(LogicalKeyboardKey.keyP): _onPausePressed,
    for (int i = 0; i < 8; i++)
      LogicalKeySet(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)): () =>
          _onPartPressed(i),
  };

  @override
  void initState() {
    super.initState();
    _machine = VirtualMachine((VirtualRenderer renderer) {
      final displayLists = renderer.displayLists;
      _displayList0.value = displayLists[0].clone();
      _displayList1.value = displayLists[1].clone();
      _displayList2.value = displayLists[2].clone();
      _displayList3.value = displayLists[3].clone();
    });
    _machine.start();
  }

  void _onDebugPressed() {
    setState(() => _debugMode = !_debugMode);
  }

  void _onShowBorderPressed() {
    setState(() => _showBorder = !_showBorder);
  }

  void _onDrawHiResPressed() {
    setState(() => _drawHiResImages = !_drawHiResImages);
    _machine.renderer.drawHiResImages = _drawHiResImages;
  }

  void _onPausePressed() {
    setState(() => _machine.paused = !_machine.paused);
  }

  void _onMutePressed() {
    setState(() => _machine.sound.muted = !_machine.sound.muted);
  }

  void _onPartPressed(int partIndex) {
    _machine.reset();
    _machine.restart(partIndex);
  }

  @override
  void dispose() {
    _machine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      descendantsAreFocusable: false,
      onKey: (FocusNode node, RawKeyEvent event) {
        var result = KeyEventResult.ignored;
        for (final activator in _shortcuts.keys) {
          if (activator.accepts(event, RawKeyboard.instance)) {
            _shortcuts[activator]!.call();
            result = KeyEventResult.handled;
          }
        }
        return result;
      },
      child: FontLoader(
        builder: (BuildContext context, ui.Image font) {
          if (!_debugMode) {
            return DisplayFrame(
              displayListNotifier: _displayList1,
              font: font,
              showBorder: _showBorder,
              drawHiResImages: _drawHiResImages,
            );
          } else {
            return Column(
              children: [
                Material(
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(2.0),
                          child: Row(
                            children: [
                              for (int i = 0; i < 7; i++) //
                                Padding(
                                  padding: const EdgeInsets.only(right: 3.0),
                                  child: OutlinedButton(
                                    onPressed: () => _onPartPressed(i),
                                    child: Text(_partNames[i]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      DebugOptionButton(
                        onPressed: _onDebugPressed,
                        selected: _debugMode,
                        icon: Icons.developer_mode,
                      ),
                      DebugOptionButton(
                        onPressed: _onDrawHiResPressed,
                        selected: _drawHiResImages,
                        icon: Icons.image,
                      ),
                      DebugOptionButton(
                        onPressed: _onShowBorderPressed,
                        selected: _showBorder,
                        icon: Icons.border_all,
                      ),
                      DebugOptionButton(
                        onPressed: _onMutePressed,
                        selected: _machine.sound.muted,
                        icon: _machine.sound.muted ? Icons.volume_off : Icons.volume_up,
                      ),
                      DebugOptionButton(
                        onPressed: _onPausePressed,
                        selected: _machine.paused,
                        icon: Icons.pause,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _DebugDisplayFrame(
                        index: 0,
                        displayListNotifier: _displayList0,
                        font: font,
                        debugMode: _debugMode,
                        showBorder: _showBorder,
                        drawHiResImages: _drawHiResImages,
                      ),
                      _DebugDisplayFrame(
                        index: 1,
                        displayListNotifier: _displayList1,
                        font: font,
                        debugMode: _debugMode,
                        showBorder: _showBorder,
                        drawHiResImages: _drawHiResImages,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _DebugDisplayFrame(
                        index: 2,
                        displayListNotifier: _displayList2,
                        font: font,
                        debugMode: _debugMode,
                        showBorder: _showBorder,
                        drawHiResImages: _drawHiResImages,
                      ),
                      _DebugDisplayFrame(
                        index: 3,
                        displayListNotifier: _displayList3,
                        font: font,
                        debugMode: _debugMode,
                        showBorder: _showBorder,
                        drawHiResImages: _drawHiResImages,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

@immutable
class DebugOptionButton extends StatelessWidget {
  const DebugOptionButton({
    super.key,
    required this.onPressed,
    required this.selected,
    required this.icon,
  });

  final VoidCallback onPressed;
  final bool selected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: selected ? theme.colorScheme.surfaceTint : Colors.white60),
    );
  }
}

@immutable
class DisplayFrame extends StatelessWidget {
  const DisplayFrame({
    super.key,
    required this.displayListNotifier,
    required this.font,
    this.showBorder = false,
    this.drawHiResImages = false,
  });

  final ValueNotifier<DisplayList> displayListNotifier;
  final ui.Image font;
  final bool showBorder;
  final bool drawHiResImages;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: displayListNotifier,
      builder: (BuildContext context, DisplayList value, Widget? child) {
        return DisplayListPaint(
          displayList: value,
          font: font,
          showBorder: showBorder,
          drawHiResImages: drawHiResImages,
        );
      },
    );
  }
}

@immutable
class _DebugDisplayFrame extends StatelessWidget {
  const _DebugDisplayFrame({
    required this.index,
    required this.displayListNotifier,
    required this.font,
    required this.debugMode,
    required this.showBorder,
    required this.drawHiResImages,
  });

  final int index;
  final ValueNotifier<DisplayList> displayListNotifier;
  final ui.Image font;
  final bool debugMode;
  final bool showBorder;
  final bool drawHiResImages;

  Color _lookupColor() {
    return [Colors.blue, Colors.green, Colors.red, Colors.purple][index];
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: displayListNotifier,
        builder: (BuildContext context, DisplayList value, Widget? child) {
          final color = _lookupColor();
          final palette = value.palette;
          final name = (const ['Draw', 'Display', 'Background 1', 'Background 2 / Effects'])[index];
          return Material(
            color: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2.0, 2.0, 2.0, 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Buffer $index ($name)'),
                      if (palette != null) //
                        PalettePreview(
                          palette: palette,
                          height: 24.0,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: DisplayListPaint(
                      displayList: value,
                      font: font,
                      showBorder: showBorder,
                      drawHiResImages: drawHiResImages,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
