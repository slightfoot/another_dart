import 'dart:convert';
import 'dart:io';

final zLibDecoder = ZLibDecoder();

List<int> load(String input, int size) {
  final List<int> data = base64.decode(input);
  if (data.length != size) {
    final List<int> buf = zLibDecoder.convert(data);
    assert(buf.length == size);
    return buf;
  }
  return data;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: data <WGZ directory path>\n');
    return;
  }
  final files = Directory(args[0]).listSync();
  for (final file in files) {
    if (!file.path.toLowerCase().endsWith('.wgz')) {
      continue;
    }
    final outputName = file.uri.pathSegments.last.toLowerCase().replaceFirst('.wgz', '.dat');
    print('${file.path} -> $outputName');
    final outputFile = File('assets/data/$outputName');
    outputFile.createSync(recursive: true);
    final outputStream = outputFile.openWrite();
    await outputStream.addStream(zLibDecoder.bind(File(file.path).openRead()));
    await outputStream.close();
  }
}
