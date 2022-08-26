import 'package:another_dart/features/vm/renderer.dart';
import 'package:another_dart/features/vm/machine.dart';
import 'package:another_dart/features/vm/state.dart';
import 'package:another_dart/features/vm/variables.dart';

const _bitmapList = [18, 19, 67, 68, 69, 70, 71, 72, 73, 83, 144, 145];

class VirtualInstructions {
  late VirtualMachine _machine;

  set machine(VirtualMachine value) {
    _machine = value;
  }

  VirtualRenderer get renderer => _machine.renderer;

  VirtualState get state => _machine.state;

  int readU8() => state.bytecode.readByte();

  int readS8() => state.bytecode.readByte().toSigned(8);

  int readU16() => state.bytecode.readWord();

  int readS16() => state.bytecode.readWord().toSigned(16);

  set pc(int value) => state.bytecode.offset = value;

  int get pc => state.bytecode.offset;

  /// 0x00: set variable to immediate | ex. v1 = 123;
  void movI() {
    final num = readU8();
    final imm = readS16();
    state.vars[num] = imm;
  }

  /// 0x01: set variable to variable | ex. v1 = v3;
  void mov() {
    final dst = readU8();
    final src = readU8();
    state.vars[dst] = state.vars[src];
  }

  /// 0x02: add variable to variable | ex. v1 += v3;
  void add() {
    final dst = readU8();
    final src = readU8();
    state.vars[dst] += state.vars[src];
  }

  /// 0x03: add immediate to variable | ex. v1 += 123;
  void addI() {
    final num = readU8();
    final imm = readS16();
    state.vars[num] += imm;
  }

  /// 0x04: call function | ex. call -> [addr]
  void call() {
    final addr = readU16();
    state.tasks[state.taskNum].stack.add(pc);
    pc = addr;
  }

  /// 0x05: return from function | ex. ret
  void ret() {
    pc = state.tasks[state.taskNum].stack.removeLast();
  }

  /// 0x06: yield task | ex. yield
  void yield() {
    state.taskPaused = true;
  }

  /// 0x07: jump to another address | ex. jump -> [addr]
  void jump() {
    pc = readU16();
  }

  /// 0x08: setup new task | ex. setVec 12 -> [addr]
  void setVec() {
    final num = readU8();
    final addr = readU16();
    state.tasks[num].nextOffset = addr;
  }

  /// 0x09: jump if not zero | ex. jnz v1 -> [addr]
  void jumpNotZero() {
    final num = readU8();
    final addr = readU16();
    state.vars[num]--;
    if (state.vars[num] != 0) {
      pc = addr;
    }
  }

  /// 0x0A: jump conditional | ex. jc (v1 != v2) -> [addr]
  void jumpConditional() {
    final op = readU8();
    final a = state.vars[readU8()];
    late final int b;
    if ((op & 0x80) != 0) {
      b = state.vars[readU8()];
    } else if ((op & 0x40) != 0) {
      b = readS16();
    } else {
      b = readU8();
    }
    final addr = readU16();
    if (_performConditional(op, a, b)) {
      pc = addr;
    }
  }

  static bool _performConditional(int op, int a, int b) {
    switch (op & 7) {
      case 0: // jz
        return (a == b);
      case 1: // jnz
        return (a != b);
      case 2: // jg
        return (a > b);
      case 3: // jge
        return (a >= b);
      case 4: // jl
        return (a < b);
      case 5: // jle
        return (a <= b);
      default:
        throw 'invalid conditional: $op';
    }
  }

  /// 0x0B: set palette | ex. setPal 10
  void setPalette() {
    final index = readU16() >> 8;
    renderer.setPalette(index);
  }

  /// 0x0C: reset task | ex. resetVec([start_addr] ~ [end_addr], 1)
  void resetTask() {
    final start = readU8();
    final end = readU8() & 0x3f;
    final taskState = readU8();
    if (taskState == 2) {
      for (int i = start; i <= end; i++) {
        state.tasks[i].nextOffset = -2;
      }
    } else {
      assert(taskState == 0 || taskState == 1);
      for (int i = start; i <= end; i++) {
        state.tasks[i].nextState = taskState;
      }
    }
  }

  /// 0x0D: select page | ex. selectPage(1);
  void selectPage() {
    final pageOperand = readS8();
    renderer.selectPage(pageOperand);
  }

  /// 0x0E: fill page | ex. fillPage(2 <- color);
  void fillPage() {
    final pageOperand = readS8();
    final color = readU8();
    renderer.fillPage(pageOperand, color);
  }

  /// 0x0F: copy page | ex. copyPage(1 -> 2 Δ varScrollY);
  void copyPage() {
    final srcOperand = readS8();
    final destOperand = readS8();
    renderer.copyPage(srcOperand, destOperand, state[Var.scrollY]);
  }

  /// 0x10: update frame buffer | ex. updateFrameBuffer(1);
  void updateFrameBuffer() {
    final pageOperand = readS8();
    final ms = state[Var.pauseSlices] * 1000 ~/ 50;
    state.delay += ms;
    state[Var.vSync] = 0;
    renderer.swapBuffers(pageOperand);
  }

  /// 0x11: kill task | ex. killTask(12);
  void killTask() {
    state.taskPaused = true;
    pc = -1;
  }

  /// 0x12: draw string | ex. drawString(id, x, y, color);
  void drawString() {
    final index = readU16();
    final x = readU8();
    final y = readU8();
    final color = readU8();
    renderer.drawString(index, x, y, color);
  }

  /// 0x13: Subtract variable from variable | ex. v3 -= v4;
  void sub() {
    final dst = readU8();
    final src = readU8();
    state.vars[dst] -= state.vars[src];
  }

  /// 0x14: Logical And of variable and immediate value | ex. v3 &= 4;
  void and() {
    final num = readU8();
    final imm = readU16();
    state.vars[num] = (state.vars[num] & imm).toSigned(16);
  }

  /// 0x15: Logical Or of variable and immediate value | ex. v6 |= 8;
  void or() {
    final num = readU8();
    final imm = readU16();
    state.vars[num] = (state.vars[num] | imm).toSigned(16);
  }

  /// 0x16: Shift Left variable by immediate bits | ex. v8 <<= 2;
  void shl() {
    final num = readU8();
    final imm = readU16() & 0x0f;
    state.vars[num] = (state.vars[num] << imm).toSigned(16);
  }

  /// 0x17: Shift Right variable by immediate bits | ex. v9 >>= 4;
  void shr() {
    final num = readU8();
    final imm = readU16() & 0x0f;
    state.vars[num] = (state.vars[num] >> imm).toSigned(16);
  }

  /// 0x18: Play sound | ex. playSound(index, frequency, volume, channel);
  void playSound() {
    final index = readU16();
    final freq = readU8();
    final volume = readU8();
    final channel = readU8();
    //print('playSound($index, $freq, $volume, $channel)');
    _machine.sound.playSound(index, freq, volume, channel);
  }

  /// 0x19: Load resource | ex. loadResource(index);
  void loadResource() {
    final index = readU16();
    if (_bitmapList.contains(index)) {
      if (index >= 3000) {
        throw 'load new bitmap resource: $index';
      } else {
        print('drawBitmap($index)');
        renderer.drawBitmap(index);
      }
    } else {
      _machine.loadResource(index);
    }
  }

  /// 0x1A: Play music | ex. playMusic(index, period, position);
  void playMusic() {
    final index = readU16();
    final delay = readU16();
    final position = readU8();
    //print('playMusic($index, $delay, $position)');
    _machine.sound.playMusic(index, delay, position);
  }

  /// 0x4x: Draw Poly Sprite | ex. drawPolySprite(...)
  void drawPolySprite(int opcode) {
    final offset = (readU16() << 1) & 0xfffe;
    int x = readU8();
    if ((opcode & 0x20) == 0) {
      if ((opcode & 0x10) == 0) {
        x = (x << 8) | readU8();
      } else {
        x = state.vars[x];
      }
    } else {
      if ((opcode & 0x10) != 0) {
        x += 256;
      }
    }
    int y = readU8();
    if ((opcode & 8) == 0) {
      if ((opcode & 4) == 0) {
        y = (y << 8) | readU8();
      } else {
        y = state.vars[y];
      }
    }
    int polygonSet = 0;
    int zoom = 64;
    if ((opcode & 2) == 0) {
      if ((opcode & 1) != 0) {
        zoom = state.vars[readU8()];
      }
    } else {
      if ((opcode & 1) != 0) {
        polygonSet = 1;
      } else {
        zoom = readU8();
      }
    }
    renderer.drawPolygon(polygonSet, offset, 0xff, zoom, x, y);
  }

  /// 0x8x: Draw Poly Background | ex. drawPolyBackground(...)
  void drawPolyBackground(int opcode) {
    final offset = (((opcode << 8) | readU8()) << 1) & 0xfffe;
    int x = readU8();
    int y = readU8();
    int h = y - 199;
    if (h > 0) {
      y = 199;
      x += h;
    }
    renderer.drawPolygon(0, offset, 0xff, 64, x, y);
  }
}
