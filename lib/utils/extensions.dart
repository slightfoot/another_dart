extension HexFormat on int {
  String toHexString(int bitLength) => '0x${toRadixString(16).padLeft(bitLength ~/ 4, '0')}';

  String toByteString() => toHexString(8);

  String toWordString() => toHexString(16);
}
