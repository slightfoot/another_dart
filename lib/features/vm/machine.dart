import 'dart:math';

import 'package:another_dart/features/polygon/parser.dart';
import 'package:another_dart/features/renderer/palette.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart' show rootBundle;
import 'package:another_dart/features/managers/input_manager.dart';
import 'package:another_dart/features/vm/variables.dart';
import 'package:another_dart/utils/data_buffer.dart';
import 'package:another_dart/features/vm/renderer.dart';
import 'package:another_dart/features/vm/instructions.dart';
import 'package:another_dart/features/vm/state.dart';

typedef VirtualInstruction = void Function();

class VirtualMachine {
  VirtualMachine(UpdateDisplayFn updateDisplay) {
    renderer = VirtualRenderer(updateDisplay);
    generateOpcodeLookup();
    ins.machine = this;
    reset();
  }

  late final VirtualRenderer renderer;
  final state = VirtualState();
  final input = InputManager();
  final ins = VirtualInstructions();
  late final Map<int, VirtualInstruction> opcodes;

  bool _paused = false;
  Ticker? _ticker;

  void generateOpcodeLookup() {
    opcodes = <int, VirtualInstruction>{
      0x00: ins.movI,
      0x01: ins.mov,
      0x02: ins.add,
      0x03: ins.addI,
      0x04: ins.call,
      0x05: ins.ret,
      0x06: ins.yield,
      0x07: ins.jump,
      0x08: ins.setVec,
      0x09: ins.jumpNotZero,
      0x0A: ins.jumpConditional,
      0x0B: ins.setPalette,
      0x0C: ins.resetTask,
      0x0D: ins.selectPage,
      0x0E: ins.fillPage,
      0x0F: ins.copyPage,
      0x10: ins.updateFrameBuffer,
      0x11: ins.killTask,
      0x12: ins.drawString,
      0x13: ins.sub,
      0x14: ins.and,
      0x15: ins.or,
      0x16: ins.shl,
      0x17: ins.shr,
      0x18: ins.playSound,
      0x19: ins.loadResource,
      0x1A: ins.playMusic,
    };
  }

  void start() {
    if (_ticker != null) {
      return;
    }
    late final Ticker ticker;
    ticker = Ticker((_) => tick());
    ticker.start();
    _ticker = ticker;
    input.start();
  }

  void stop() {
    input.stop();
    if (_ticker != null) {
      _ticker!.stop();
      _ticker = null;
    }
  }

  void reset() {
    renderer.reset();
    state.vars.fillRange(0, 256, 0);
    state.vars[0x54] = 0x81;
    state[Var.randomSeed] = Random().nextInt(0xffff);
    // set by original game
    state.vars[0xbc] = 0x10;
    state.vars[0xc6] = 0x80;
    state.vars[0xf2] = 4000; // 6000 DOS // 4000 for Amiga bytecode
    // set by original engine
    state.vars[0xdc] = 33;
    // set when entering a part
    state.vars[0xe4] = 0x14;
    state.nextPart = state.currentPart = 1; // starting part
    state.timestamp = DateTime.now().millisecondsSinceEpoch;
  }

  void loadResource(int resourceIndex) {
    // print('load_resource($resourceIndex)');
    if (resourceIndex >= 16000) {
      state.nextPart = resourceIndex - 16000; // zero index
    }
  }

  Future<void> tick() async {
    final current = DateTime.now().millisecondsSinceEpoch;
    state.delay -= current - state.timestamp;
    while (state.delay <= 0) {
      if (!await runTasks()) {
        _ticker!.stop();
        _ticker = null;
        return;
      }
    }
    state.timestamp = current;
  }

  Future<bool> runTasks() async {
    if (input.isKeyPressed(InputKey.pause)) {
      _paused = !_paused;
    }
    if (_paused) {
      state.delay = 20;
      return true;
    }
    if (state.nextPart != -1) {
      await restart(state.nextPart);
      state.nextPart = -1;
    }
    int activeTasks = 0;
    for (int i = 0; i < state.tasks.length; ++i) {
      state.tasks[i].state = state.tasks[i].nextState;
      final int offset = state.tasks[i].nextOffset;
      if (offset != -1) {
        state.tasks[i].offset = (offset == -2) ? -1 : offset;
        state.tasks[i].nextOffset = -1;
      }
      if (state.tasks[i].state == 0 && state.tasks[i].offset != -1) {
        activeTasks++;
      }
    }
    if (activeTasks == 0) {
      return false;
    }
    handleInput();
    for (int i = 0; i < state.tasks.length; ++i) {
      if (state.tasks[i].state == 0) {
        final int offset = state.tasks[i].offset;
        if (offset == -1) {
          continue;
        }
        state.bytecode.offset = offset;
        state.tasks[i].stack.length = 0;
        state.taskNum = i;
        state.taskPaused = false;
        executeTask(i);
        state.tasks[i].offset = state.bytecode.offset;
      }
    }
    return true;
  }

  void executeTask(int taskIndex) {
    while (!state.taskPaused) {
      final int addr = state.bytecode.offset;
      final opcode = state.bytecode.readByte();
      //print('task ${taskIndex.toString().padLeft(2)}: ${addr.toRadixString(16).padLeft(4, '0')}| ${opcode.toRadixString(16).padLeft(2, '0')}');
      if ((opcode & 0x80) != 0) {
        ins.drawPolyBackground(opcode);
      } else if ((opcode & 0x40) != 0) {
        ins.drawPolySprite(opcode);
      } else {
        opcodes[opcode]!();
      }
    }
  }

  Future<void> restart(int part) async {
    renderer.text ??= (await rootBundle.loadString('assets/EN.txt')).split('\n');
    if (part == 0) {
      // protection
      renderer.palettes = await Palette.load(assetPath(20));
      state.bytecode = await load(21);
      renderer.polygons1 = PolygonParser(await load(22));
      renderer.polygons2 = null;
    } else if (part == 1) {
      // Intro
      renderer.palettes = await Palette.load(assetPath(23));
      state.bytecode = await load(24);
      renderer.polygons1 = PolygonParser(await load(25));
      renderer.polygons2 = null;
    } else if (part == 2) {
      // Arrival
      renderer.palettes = await Palette.load(assetPath(26));
      state.bytecode = await load(27);
      renderer.polygons1 = PolygonParser(await load(28));
      renderer.polygons2 = PolygonParser(await load(17));
    } else if (part == 3) {
      // Jail
      renderer.palettes = await Palette.load(assetPath(29));
      state.bytecode = await load(30);
      renderer.polygons1 = PolygonParser(await load(31));
      renderer.polygons2 = PolygonParser(await load(17));
    } else if (part == 4) {
      //City
      renderer.palettes = await Palette.load(assetPath(32));
      state.bytecode = await load(33);
      renderer.polygons1 = PolygonParser(await load(34));
      renderer.polygons2 = PolygonParser(await load(17));
    } else if (part == 5) {
      // Arena
      renderer.palettes = await Palette.load(assetPath(35));
      state.bytecode = await load(36);
      renderer.polygons1 = PolygonParser(await load(37));
      renderer.polygons2 = PolygonParser(await load(17));
    } else if (part == 6) {
      // Baths
      renderer.palettes = await Palette.load(assetPath(38));
      state.bytecode = await load(39);
      renderer.polygons1 = PolygonParser(await load(40));
      renderer.polygons2 = PolygonParser(await load(17));
    } else if (part == 7) {
      // End
      renderer.palettes = await Palette.load(assetPath(41));
      state.bytecode = await load(42);
      renderer.polygons1 = PolygonParser(await load(43));
      renderer.polygons2 = PolygonParser(await load(17));
    } else if (part == 8) {
      // password screen
      renderer.palettes = await Palette.load(assetPath(125));
      state.bytecode = await load(126);
      renderer.polygons1 = PolygonParser(await load(127));
      renderer.polygons2 = null;
    }

    // set when entering a part
    state.vars[0xE4] = 0x14;

    for (int i = 0; i < state.tasks.length; ++i) {
      state.tasks[i] = VirtualTask();
    }
    state.tasks[0].offset = 0;
    state.currentPart = part;
  }

  String assetPath(int resourceIndex) {
    return 'assets/file${resourceIndex.toString().padLeft(3, '0')}.dat';
  }

  Future<DataBuffer> load(int resourceIndex) async {
    return DataBuffer(await rootBundle.load(assetPath(resourceIndex)));
  }

  void handleInput() {
    int mask = 0;
    if (input.isKeyPressed(InputKey.right)) {
      state[Var.heroPosLeftRight] = 1;
      mask |= 0x01;
    } else if (input.isKeyPressed(InputKey.left)) {
      state[Var.heroPosLeftRight] = -1;
      mask |= 0x02;
    } else {
      state[Var.heroPosLeftRight] = 0;
    }
    if (input.isKeyPressed(InputKey.down)) {
      state[Var.heroPosUpDown] = state[Var.heroPosJumpDown] = 1;
      mask |= 0x04;
    } else if (input.isKeyPressed(InputKey.up)) {
      state[Var.heroPosUpDown] = state[Var.heroPosJumpDown] = -1;
      mask |= 0x08;
    } else {
      state[Var.heroPosUpDown] = state[Var.heroPosJumpDown] = 0;
    }
    state[Var.heroPosMask] = mask;
    if (input.isKeyPressed(InputKey.action)) {
      state[Var.heroAction] = 1;
      mask |= 0x80;
    } else {
      state[Var.heroAction] = 0;
    }
    state[Var.heroActionPosMask] = mask;
  }
}
