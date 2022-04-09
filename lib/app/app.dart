import 'package:another_dart/features/renderer/display_list.dart';
import 'package:another_dart/features/renderer/display_widget.dart';
import 'package:flutter/material.dart';
import 'package:another_dart/features/viewer/polygon_viewer.dart';
import 'package:another_dart/features/vm/machine.dart';

class AnotherApp extends StatelessWidget {
  const AnotherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      //home: const PolygonViewer(),
      home: const MachineWidget(),
    );
  }
}

@immutable
class MachineWidget extends StatefulWidget {
  const MachineWidget({super.key});

  @override
  State<MachineWidget> createState() => _MachineWidgetState();
}

class _MachineWidgetState extends State<MachineWidget> {
  final _displayList = ValueNotifier(DisplayList());
  late VirtualMachine _machine;

  @override
  void initState() {
    super.initState();
    _machine = VirtualMachine((DisplayList displayList) {
      _displayList.value = displayList;
    });
    _machine.start();
  }

  @override
  void dispose() {
    _machine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DisplayWidget(displayListNotifier: _displayList);
  }
}
