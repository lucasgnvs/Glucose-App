import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

final LogFilter _filter = ProductionFilter();
final LogPrinter _printer = SimplePrinter(printTime: true);
late final LogOutput _output;
const String _fileName = 'eg.log';

Logger? _log;

Logger get log => _log!;

Future<void> logInit() async {
  if (kReleaseMode) {
    Directory dir = await getApplicationDocumentsDirectory();
    File file = File(join(dir.path, _fileName));
    _output = FileOutput(file: file);
  } else {
    _output = ConsoleOutput();
  }
  _log = Logger(
    filter: _filter,
    printer: _printer,
    output: _output,
  );
}
