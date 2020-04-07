import 'dart:io' show Directory, File, FileSystemEntity;
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:JackAnalyzer/compilation_engine/CompilationEngine.dart';

///Creates a CompilationEngine object and
///processes a single source file
Future processFile(final File file, {String outputDir}) async {
  var ce = CompilationEngine(file, outputDir: outputDir);
  try {
    await ce.compileClass();
  } catch (e) {
    print(e);
  }
}

Future main(List<String> arguments) async {
  try {
    var inputPath = arguments[0];
    String outputDir;
    if (arguments.length > 1 &&
        await FileSystemEntity.isDirectory(arguments[1])) {
      outputDir = arguments[1];
    }

    if (await FileSystemEntity.isDirectory(inputPath)) {
      var dir = Directory(inputPath);
      await for (FileSystemEntity f in dir.list()) {
        if (f is File && path.extension(f.path) == '.jack') {
          await processFile(f, outputDir: outputDir);
        }
      }
    } else if (await FileSystemEntity.isFile(inputPath)) {
      await processFile(File(inputPath), outputDir: outputDir);
    }
  } on RangeError {
    print(
        'Usage: analyzer <input file|directory> [output directory]');
  }

}
