import 'package:path/path.dart' as path;
import 'package:JackAnalyzer/jack_tokenizer/JackTokenizer.dart';
import 'dart:io';
import 'dart:async';

class CompilationEngine {
  static const op = ['+', '-', '*', '/', '&amp;', '&gt;', '&lt;', '=', '|'];

  final File _file;
  File _outputFile;
  JackTokenizer _tokenizer;
  int _indents;  //current indent level
  String _xml; //result xml string

  CompilationEngine(this._file, {String outputDir}) {
    _xml = '';
    _tokenizer = JackTokenizer(_file);
    _indents = 0;
    var outputFileName = path.join(
        outputDir ?? '', path.basenameWithoutExtension(_file.path) + '.xml');
    _outputFile = File(outputFileName);
    if (!_outputFile.existsSync()) _outputFile.create();
  }

  ///Compiles a complete class
  Future compileClass() async {
    _nestNode('class');
    _tokenizer.advance();
    if (_tokenizer.token != 'class') throw 'Syntax Error!';
    _addToken(); //class

    _tokenizer.advance();
    if (_tokenizer.tokenType != 'identifier') throw 'Illegal Class Name.';
    _addToken(); //Main
    _tokenizer.advance();
    if (_tokenizer.token != '{') {
      throw 'A class declaration must have body even it is empty.';
    }
    _addToken(); // {

    while (_tokenizer.hasMoreTokens()) {
      switch (_tokenizer.token) {
        case 'static':
          compileClassVarDec();
          break;
        case 'field':
          compileClassVarDec();
          break;
        case 'function':
          compileSubroutineDec();
          break;
        case 'method':
          compileSubroutineDec();
          break;
        case 'constructor':
          compileSubroutineDec();
          break;
      }
      _tokenizer.advance();
    }
    _xml += '\t' * _indents + getXmlString('}', 'symbol');
    _closeNested('class');
    await _outputFile.writeAsString(_xml);
  }

  ///Compiles a static variable declaration or a field declaration
  void compileClassVarDec() {
    _nestNode('classVarDec');
    _addNextToken(); // static | field
    //if (_tokenizer.tokenType != 'keyword') throw 'Illegal type: ${_tokenizer.token}\n In file: ${_file.path}';
    _addNextToken(); // type
    while (_tokenizer.token != ';') {
      _addNextToken(); //varName or ,
    }
    _addToken();
    _closeNested('classVarDec');
  }

  ///Compiles a complete method, function or constructor
  void compileSubroutineDec() {
    _nestNode('subroutineDec');
    _addNextToken(); //function, method or constructor
    _addNextToken(); // type
    _addNextToken(); // name
    _addNextToken(); // (
    compileParameterList(); //params
    _addNextToken(); // )
    compileSubroutineBody();
    _closeNested('subroutineDec');
  }

  ///Starting from current token, current token
  ///becomes the last of this block.
  ///Compiles (possibly empty) parameter list
  ///Does not handle the enclosing "()"
  void compileParameterList() {
    _nestNode('parameterList');
    while (_tokenizer.token != ')') {
      _addNextToken();
    }
    _closeNested('parameterList');
  }

  ///Compiles subroutine body
  void compileSubroutineBody() {
    _nestNode('subroutineBody');
    _addNextToken(); // {
    while (_tokenizer.token == 'var') {
      compileVarDec();
      _tokenizer.advance();
    }
    compileStatements();
    _addToken();
    _closeNested('subroutineBody');
  }

  ///Compiles variables declarations
  void compileVarDec() {
    _nestNode('varDec');
    _addNextToken(); // var
    _addNextToken(); // type
    while (_tokenizer.token != ';') {
      _addNextToken(); //varName or ,
    }
    _addToken(); // ;
    _closeNested('varDec');
  }

  ///Compiles statements
  void compileStatements() {
    _nestNode('statements');
    while (true) {
      if (_tokenizer.token == 'let') {
        compileLet();
      }
      if (_tokenizer.token == 'if') {
        compileIf();
        continue; //TODO ifStatement advances current token
      }
      if (_tokenizer.token == 'while') {
        compileWhile();
        continue; //TODO whileStatement advances current token
      }
      if (_tokenizer.token == 'do') {
        compileDo();
      }
      if (_tokenizer.token == 'return') {
        compileReturn();
      }
      if (_tokenizer.token == '}') {
        break;
      }
      _tokenizer.advance();
    }
    _closeNested('statements');
  }

  ///Compiles letStatement
  void compileLet() {
    _nestNode('letStatement');
    _addNextToken(); // let
    _addNextToken(); // varName
    if (_tokenizer.token == '[') {
      _addNextToken(); // [
      compileExpression();
      _addNextToken(); // ]
    }
    _addNextToken(); // =
    compileExpression();
    _addToken(); // ;
    _closeNested('letStatement');
  }

  ///Compiles ifStatement.
  ///Advances current token.
  void compileIf() {
    _nestNode('ifStatement');
    _addNextToken(); // if
    _addNextToken(); // (
    compileExpression();
    _addNextToken(); // )
    _addNextToken(); // {
    compileStatements();
    _addNextToken(); // }
    if (_tokenizer.token == 'else') {
      _addNextToken(); // else
      _addNextToken(); // {
      compileStatements();
      _addNextToken(); // }
    }
    _closeNested('ifStatement');
  }

  ///Compiles whileStatement
  void compileWhile() {
    _nestNode('whileStatement');
    _addNextToken(); // while
    _addNextToken(); // (
    compileExpression();
    _addNextToken(); // )
    _addNextToken(); // {
    compileStatements();
    _addNextToken(); // }
    _closeNested('whileStatement');
  }

  ///Compiles doStatement
  void compileDo() {
    _nestNode('doStatement');
    _addNextToken(); // do
    _addNextToken(); //name
    if (_tokenizer.token == '.') {
      _addNextToken(); // .
      _addNextToken(); // name
    }
    _addNextToken(); // (
    compileExpressionList();
    _addNextToken(); // )
    _addToken(); // ;
    _closeNested('doStatement');
  }

  ///Compiles return statement
  void compileReturn() {
    _nestNode('returnStatement');
    _addNextToken(); // return
    if (_tokenizer.token == ';') {
      _addToken(); // ;
      _closeNested('returnStatement');
      return;
    }
    compileExpression();
    _addToken(); // ;
    _closeNested('returnStatement');
  }

  ///Compiles an expression
  void compileExpression() {
    _nestNode('expression');
    compileTerm();
    while (op.contains(_tokenizer.token)) {
      _addNextToken();
      compileTerm();
    }
    _closeNested('expression');
  }

  ///Compiles a term.
  ///Advances the current token after execution;
  void compileTerm() {
    _nestNode('term');
    var isConstOrName = _tokenizer.tokenType == 'integerConstant' ||
        _tokenizer.tokenType == 'stringConstant' ||
        _tokenizer.tokenType == 'identifier' ||
        _tokenizer.tokenType == 'keyword';
    if (isConstOrName) {
      _addNextToken();
      if (_tokenizer.token == '[') {
        _addNextToken(); // [
        compileExpression();
        _addNextToken(); // ]
      }
      if (_tokenizer.token == '(') {
        _addNextToken(); // (
        compileExpressionList();
        _addNextToken(); // )
      }
      if (_tokenizer.token == '.') {
        _addNextToken(); // .
        if (_tokenizer.tokenType == 'identifier') {
          _addNextToken();
          if (_tokenizer.token == '(') {
            _addNextToken(); // (
            compileExpressionList();
            _addNextToken(); // )
          } else {
            throw 'Wrong subroutine call.';
          }
        }
      }
    } else if (_tokenizer.token == '(') {
      _addNextToken(); // (
      compileExpression();
      _addNextToken(); //)
    } else if (_tokenizer.token == '-' || _tokenizer.token == '~') {
      _addNextToken();
      compileTerm();
    }
    _closeNested('term');
  }

  ///Starting from current token, current token
  ///becomes the last of this block.
  void compileExpressionList() {
    _nestNode('expressionList');
    if (_tokenizer.token != ')') compileExpression();
    while (_tokenizer.token == ',') {
      _addNextToken();
      compileExpression();
    }
    _closeNested('expressionList');
  }

  ///Makes all next nodes it's children, increases tabs for them
  void _nestNode(String nodeName) {
    _xml += '\t' * _indents + '<$nodeName>\n';
    _indents++;
  }

  ///Closes parent node
  void _closeNested(String nodeName) {
    _indents--;
    _xml += '\t' * _indents + '</$nodeName>\n';
  }

  ///Adds a current token without going to the next
  void _addToken() {
    _xml += '\t' * _indents + getXmlString(_tokenizer.token, _tokenizer.tokenType);
  }

  ///Adds token, goes to the next
  void _addNextToken() {
    _xml += '\t' * _indents + getXmlString(_tokenizer.token, _tokenizer.tokenType);
    _tokenizer.advance();
  }

  @override
  String toString() => _xml;
}
