import 'package:flutter/material.dart';
import 'package:another_dart/app/app.dart';

void main(List<String> args) {
  final showViewer = args.contains('--viewer');
  runApp(AnotherWorldApp(showViewer: showViewer));
}
