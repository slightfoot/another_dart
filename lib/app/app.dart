import 'package:another_dart/features/machine/machine.dart';
import 'package:flutter/material.dart';
import 'package:another_dart/features/viewer/polygon_viewer.dart';

class AnotherWorldApp extends StatelessWidget {
  const AnotherWorldApp({
    super.key,
    required this.showViewer,
  });

  final bool showViewer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.cyan,
      ),
      home: Builder(
        builder: (BuildContext context) {
          if (showViewer) {
            return const PolygonViewer();
          } else {
            return const MachineWidget();
          }
        },
      ),
    );
  }
}
