import 'dart:ui' as ui;

import 'package:another_dart/utils/load_image.dart';
import 'package:flutter/widgets.dart';

typedef FontBuilder = Widget Function(BuildContext context, ui.Image font);

@immutable
class FontLoader extends StatefulWidget {
  const FontLoader({
    super.key,
    required this.builder,
  });

  final FontBuilder builder;

  @override
  State<FontLoader> createState() => _FontLoaderState();
}

class _FontLoaderState extends State<FontLoader> {
  late Future<ui.Image> _fontFuture;

  @override
  void initState() {
    super.initState();
    _fontFuture = loadImageAsset('assets/images/font.png');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fontFuture,
      builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox();
        } else if (snapshot.hasError) {
          return ErrorWidget(snapshot.error!);
        }
        return widget.builder(context, snapshot.requireData);
      },
    );
  }
}
