# Jack Analyzer

This is a project 10 written in [Dart](https://dart.dev) for [nand2tetris](https://www.coursera.org/learn/nand2tetris2) course.

Jack analyzer takes source files or directory with files, splits each of them into tokens
and writes as xml. 

Use `dartdoc` to generate docs.
# Building and running
You need a [Dart SDK](https://dart.dev/get-dart) to build and run JackAnalyzer.
#### Compiling:
Use a Makefile: `make build`

Or `dart2native bin/main.dart -o jack-analyzer`

#### Run:
`<path-to-bin>/jack-analyzer <input file|dir> [output dir]`

Using Dart VM: `dart bin/main.dart <input file|dir> [output dir]`

