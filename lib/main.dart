import 'dart:io';

import 'package:another_dart/features/renderer/display_paint.dart';
import 'package:flutter/material.dart';
import 'package:another_dart/app/app.dart';

void main(List<String> args) {
  final showViewer = args.contains('--viewer');
  precacheHiresImages();
  runApp(AnotherWorldApp(showViewer: showViewer));
}
