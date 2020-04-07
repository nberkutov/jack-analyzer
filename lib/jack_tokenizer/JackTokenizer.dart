import 'dart:io';

class JackTokenizer {
  static const Tokens = {
    'class': 'keyword',
    'return' : 'keyword',
    'constructor': 'keyword',
    'function': 'keyword',
    'method': 'keyword',
    'field': 'keyword',
    'static': 'keyword',
    'var': 'keyword',
    'int': 'keyword',
    'char': 'keyword',
    'boolean': 'keyword',
    'void': 'keyword',
    'true': 'keyword',
    'false': 'keyword',
    'null': 'keyword',
    'this': 'keyword',
    'let': 'keyword',
    'do': 'keyword',
    'if': 'keyword',
    'else': 'keyword',
    'while': 'keyword',
    '{': 'symbol',
    '}': 'symbol',
    '(': 'symbol',
    ')': 'symbol',
    '[': 'symbol',
    ']': 'symbol',
    '.': 'symbol',
    ',': 'symbol',
    ';': 'symbol',
    '+': 'symbol',
    '-': 'symbol',
    '*': 'symbol',
    '/': 'symbol',
    '&': 'symbol',
    '|': 'symbol',
    '>': 'symbol',
    '<': 'symbol',
    '=': 'symbol',
    '~': 'symbol',
  };

  static const Symbols = {
    '{': '{',
    '}': '}',
    '(': '(',
    ')': ')',
    '[': '[',
    ']': ']',
    '.': '.',
    ',': ',',
    ';': ';',
    '+': '+',
    '-': '-',
    '*': '*',
    '/': '/',
    '&': '&amp;',
    '|': '|',
    '>': '&gt;',
    '<': '&lt;',
    '=': '=',
    '~': '~',
  } ;

  List<String> _alphanum;
  List<String> _symbols;
  String _source;
  String _currentToken;
  String _tokenType;
  String _t;
  int _i; //index of current character of the _source

  ///If token is symbol, returns symbol representation,
  ///else returns null.
  String get symbol => Symbols[_currentToken];
  ///Current token
  String get token => _tokenType == 'symbol' ? symbol: _currentToken;

  ///Returns String with a type of current token.
  String get tokenType => _tokenType;

  ///Gets a source file and reads as string.
  JackTokenizer(File inputFile) {
    _t = '';
    _alphanum = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'.split('');
    _symbols = '()[]{}|&+-=*/;<>.,~'.split('');
    try {
      _source = inputFile
          .readAsStringSync()
          .replaceAll(RegExp(r'(//.*)|(/\*[\s\S]*?\*/)'), ''); //Replacing comments
      _currentToken = '';
      _i = 0;
    } catch (e) {
      print(e);
    }
  }

  String _getType(String token) {
    var type = Tokens[token];
    if (type == null) {
      var n = int.tryParse(token);
      if (n == null) {
        type = 'identifier';
      } else {
        type = 'integerConstant';
      }
    }
    return type ?? 'identifier';
  }

  ///Returns true if source code has more tokens.
  bool hasMoreTokens() {
    return _i < _source.length;
  }

  ///Abstraction of input reading.
  String _read() {
    return _source[_i++];
  }

  ///Advance to the next token.
  void advance() {
    _currentToken = '';
    while (_i < _source.length) {
      var c = _read();
      if (c == '"') {
        c = _read();
        while (c != '"') {
          _t += c;
          c = _read();
        } 
        _currentToken = _t;
        _t = '';
        _tokenType = 'stringConstant';
        break;
      }
      if (_alphanum.contains(c.toUpperCase())) {
        while (_alphanum.contains(c.toUpperCase())) {
          _t += c;
          c = _read();
        }
        _currentToken = _t;
        _t = '';
        _i--;
        _tokenType = _getType(_currentToken);
        break;
      } 
      if (_symbols.contains(c)) {
        _currentToken = c;
        _t = '';
        _tokenType = _getType(_currentToken);
        break;
      } 
      if (c == ' ') {
        continue;
      }
    }
  }
}

///Get a string wrapped into a tag.
String getXmlString(final String text, final String node) {
  return '<$node> $text </$node>\n';
}
