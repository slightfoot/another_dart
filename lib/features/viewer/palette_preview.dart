import 'package:another_dart/features/renderer/palette.dart';
import 'package:flutter/material.dart';

@immutable
class PalettePreview extends StatelessWidget {
  const PalettePreview({
    super.key,
    required this.palette,
    this.height = kMinInteractiveDimension,
  });

  final Palette palette;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < 8; i++) //
              _PaletteColor(color: palette.colors[i], height: height / 2),
          ],
        ),
        Row(
          children: [
            for (int i = 8; i < 16; i++) //
              _PaletteColor(color: palette.colors[i], height: height / 2),
          ],
        ),
      ],
    );
  }
}

@immutable
class _PaletteColor extends StatelessWidget {
  const _PaletteColor({
    required this.color,
    required this.height,
  });

  final int color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(color),
      child: SizedBox.square(dimension: height),
    );
  }
}
