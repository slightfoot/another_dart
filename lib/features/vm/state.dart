import 'dart:typed_data';

import 'package:another_dart/features/vm/variables.dart';
import 'package:another_dart/utils/data_buffer.dart';

class VirtualState {
  VirtualState();

  late DataBuffer bytecode;
  final tasks = List<VirtualTask>.filled(64, VirtualTask());
  bool taskYielded = false;
  int taskIndex = 0;

  VirtualTask get currentTask => tasks[taskIndex];

  final vars = Int16List(256);
  int currentPart = -1;
  int nextPart = -1;

  int delay = 0;
  int timestamp = 0;
  bool paused = false;

  int operator [](Var index) => vars[index.value];

  void operator []=(Var index, int value) => vars[index.value] = value;
}

class VirtualTask {
  int state = 0;
  int nextState = 0;
  int offset = -1;
  int nextOffset = -1;
  final List<int> stack = <int>[];
}
