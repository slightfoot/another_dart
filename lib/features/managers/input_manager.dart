import 'package:collection/collection.dart';
import 'package:flutter/services.dart'
    show
        LogicalKeyboardKey,
        RawKeyDownEvent,
        RawKeyEvent,
        RawKeyUpEvent,
        RawKeyboard;
import 'package:flutter/widgets.dart';

enum InputKey {
  up(LogicalKeyboardKey.arrowUp),
  down(LogicalKeyboardKey.arrowDown),
  left(LogicalKeyboardKey.arrowLeft),
  right(LogicalKeyboardKey.arrowRight),
  action(LogicalKeyboardKey.space);

  const InputKey(this.logicalKey);

  final LogicalKeyboardKey logicalKey;
}

class InputManager {
  InputManager();

  final _keyboard = <InputKey, bool>{};

  bool isKeyPressed(InputKey key) => _keyboard[key] ?? false;

  bool onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // print('onKeyDn: ${event.logicalKey}');
      return _setKeyState(event.logicalKey, true);
    }

    if (event is RawKeyUpEvent) {
      // print('onKeyUp: ${event.logicalKey}');
      return _setKeyState(event.logicalKey, false);
    }

    return false;
  }

  bool _setKeyState(LogicalKeyboardKey key, bool state) {
    final inputKey =
        InputKey.values.firstWhereOrNull((el) => el.logicalKey == key);
    if (inputKey != null) {
      _keyboard[inputKey] = state;
      return true;
    }
    return false;
  }
}
