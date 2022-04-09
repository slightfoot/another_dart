import 'dart:typed_data';

class DataBuffer {
  DataBuffer(this.data);

  final ByteData data;
  int offset = 0;

  int get length => data.lengthInBytes;

  int peekByte() {
    return data.getUint8(offset);
  }

  int readByte() {
    final value = data.getUint8(offset);
    offset++;
    return value;
  }

  int readWord() {
    final value = data.getUint16(offset);
    offset += 2;
    return value;
  }
}
