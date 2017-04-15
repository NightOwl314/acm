LANGUAGES.cpp = {
  defaultMode: {
    lexems: [UNDERSCORE_IDENT_RE],
    illegal: '</',
    contains: ['comment', 'string', 'hex_number', 'number', 'preprocessor', 'character'],
    keywords: {
     'keyword': {
         'false': 1, 'while': 1, 'private': 1,  'catch': 1, 'export': 1, 'virtual': 1, 'operator': 2, 
         'sizeof': 2, 'dynamic_cast': 2, 'typedef': 2, 'const_cast': 2,  'struct': 1, 'for': 1, 'static_cast': 2, 
         'union': 1, 'namespace': 1, 'throw': 1, 'protected': 1, 'template': 1, 'if': 1, 'public': 1, 'friend': 2, 
         'do': 1, 'return': 1, 'goto': 1, 'else': 1, 'break': 1, 'new': 1, 'extern': 1, 'using': 1, 'true': 1, 
         'class': 1, 'asm': 1, 'case': 1, 'typeid': 1, 'reinterpret_cast': 2, 'default': 1, 'explicit': 1,  
         'typename': 1, 'try': 1, 'this': 1, 'switch': 1, 'continue': 1, 'inline': 1, 'delete': 1, 
         '__cdecl': 1, '__pascal': 1, '__stdcall': 1, '__fastcall': 1, '__declspec': 1, '__export': 1, 
         '__import': 1, '__thread': 1, '__try': 1, '__except': 1, '__finally': 1
       },
     'type' : {
         'int': 1, 'float': 1, 'char': 1, 'const': 1, 'short': 1, 'signed': 1, 'wchar_t': 1, 'long': 1, 'bool': 1, 'void': 2, 'enum': 1, 'static': 1, 'auto': 1, 'unsigned': 1, 'volatile': 2, 'mutable': 1, 'double': 1, 'register': 1, '__int8': 1, '__int16': 1,  '__int32': 1,  '__int64': 1
       }
     }
  },
  modes: [
    {
      className: 'character',
      begin: '\'', end: '\'',
      illegal: '[^\\\\][^\']',
      contains: ['escape']
    },
    {
      className: 'preprocessor',
      begin: '#', end: '$'
    },
    {
      className: 'hex_number',
      begin: '\\b(0x[A-Fa-f0-9]+)', end: '^'
    },
    C_NUMBER_MODE,
    C_LINE_COMMENT_MODE,
    C_BLOCK_COMMENT_MODE,
    QUOTE_STRING_MODE,
    BACKSLASH_ESCAPE
  ]
};//cpp