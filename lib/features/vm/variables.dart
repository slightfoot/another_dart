enum Var {
  randomSeed(0x3c),
  lastKeyChat(0xda),
  heroPosUpDown(0xe5),
  musMark(0xf4),
  vSync(0xf7),
  scrollY(0xf9),
  heroAction(0xfa),
  heroPosJumpDown(0xfb),
  heroPosLeftRight(0xfc),
  heroPosMask(0xfd),
  heroActionPosMask(0xfe),
  pauseSlices(0xff);

  const Var(this.value);

  final int value;
}
