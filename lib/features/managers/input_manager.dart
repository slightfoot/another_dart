import 'package:collection/collection.dart';
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, RawKeyDownEvent, RawKeyEvent, RawKeyUpEvent, RawKeyboard;

enum InputKey {
  up(LogicalKeyboardKey.arrowUp),
  down(LogicalKeyboardKey.arrowDown),
  left(LogicalKeyboardKey.arrowLeft),
  right(LogicalKeyboardKey.arrowRight),
  action(LogicalKeyboardKey.space),
  pause(LogicalKeyboardKey.shiftLeft);

  const InputKey(this.logicalKey);

  final LogicalKeyboardKey logicalKey;
}

class InputManager {
  InputManager();

  final _keyboard = <InputKey, bool>{};

  bool isKeyPressed(InputKey key) => _keyboard[key] ?? false;

  void start() {
    RawKeyboard.instance.addListener(_onKey);
  }

  void _onKey(RawKeyEvent value) {
    if (value is RawKeyDownEvent) {
      // print('onKeyDn: ${value.logicalKey}');
      _setKeyState(value.logicalKey, true);
    } else if (value is RawKeyUpEvent) {
      // print('onKeyUp: ${value.logicalKey}');
      _setKeyState(value.logicalKey, false);
    }
  }

  void _setKeyState(LogicalKeyboardKey key, bool state) {
    final inputKey = InputKey.values.firstWhereOrNull((el) => el.logicalKey == key);
    if (inputKey != null) {
      _keyboard[inputKey] = state;
    }
  }

  void stop() {
    RawKeyboard.instance.removeListener(_onKey);
  }
}
