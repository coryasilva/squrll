/**
 * NOTE: All of the gobbles below will modify `index` as we move along
 */
component assessors='false' {
  /**
   * The string expression that we are parsing
   */
  property string expression;
  /**
   * The character number we are currently at while `length` is a constant
   */
  property numeric index;

  /**
   * The expression length
   */
  property numeric length;

  /* Constants */
  variables.IDENTIFIER      = 'Identifier';
  variables.LITERAL         = 'Literal';
  variables.BINARY_EXP      = 'BinaryExpression';
  variables.LOGICAL_EXP     = 'LogicalExpression';
  variables.PERIOD_CODE     = 46; // '.'
  variables.DQUOTE_CODE     = 34; // double quotes
  variables.OPAREN_CODE     = 40; // (
  variables.CPAREN_CODE     = 41; // )

  /**
   * Operator map for the binary operations with their values set to their
   * corresponding binary precedence for quick reference:
   * see [Order of operations](http://en.wikipedia.org/wiki/Order_of_operations#Programming_language)
   */
  variables.operators = {
    'or':     1
    ,'and':   2
    ,'eq':    3
    ,'neq':   3
    ,'is':    3
    ,'nis':   3
    ,'in':    3
    ,'nin':   3
    ,'like':  3
    ,'nlike': 3
    ,'lt':    4
    ,'nlt':   4
    ,'gt':    4
    ,'ngt':   4
    ,'lte':   4
    ,'nlte':  4
    ,'gte':   4
    ,'ngte':  4
  };

  /**
   * The values to return for the various literals we may encounter
   */
  variables.literals = {
    'true':  true
    ,'false': false
    ,'null':  'null'
  };

  public Parser function init() {
    variables.maxBinaryOperationLength = getMaxKeyLen( variables.operators );
    return this;
  }

  public struct function parse( required string expression ) {
    variables.expression = arguments.expression;
    variables.index = 1;
    variables.length = len( arguments.expression );

    // If empty expression early return
    if ( len( variables.expression ) == 0 ) {
      return {
        'error': true
        ,'errorMessage': 'Empty expression'
      };
    }

    try {
      var node = gobbleExpression();
      // If no expression
      if ( node.type != variables.BINARY_EXP && node.type != variables.LOGICAL_EXP ) {
        node.error = true;
        node[ 'errorMessage' ] = 'Not an expression';
      }
      return node;
    }
    catch ( Squrll error ) {
      return {
        'error': true
        ,'errorMessage': error.message
      }
    }
  }

  private any function throwError( message, index ) {
    var error = message & ' at character ' & index;
    throw( error, 'Squrll' );
  }

  /**
   *  Get return the longest key length of any object
   */
  private numeric function getMaxKeyLen( obj ) {
    var maxLen = 0;
    obj.each( function ( key, value ) {
      maxLen = max( maxLen, len( key ) );
    } );
    return maxLen;
  }

  /**
   *  Returns the precedence of a binary operator or `0` if it isn't a binary operator
   */
  private numeric function binaryPrecedence( operatorValue ) {
    return variables.operators.keyExists( operatorValue ) ? variables.operators[ operatorValue ] : 0;
  }

  /**
   *  Utility funciton, note that `a and b` and `a |or b` are *logical* expressions, not binary expressions
   */
  private struct function createBinaryExpression( operator, left, right ) {
    var type = ( operator == 'or' || operator == 'and' ) ? variables.LOGICAL_EXP : variables.BINARY_EXP;
    return {
      'type': type
      ,'operator': operator
      ,'left': left
      ,'right': right
      ,'error': false
    };
  }

  private boolean function isDecimalDigit( ch ) {
    // `ch` is a character code
    return ( ch == 45 ) || ( ch >= 48 && ch <= 57 ); // 0...9
  }

  private boolean function isIdentifierStart( ch ) {
    // `ch` is a character code
    return ( ch == 95 ) || // `_`
      ( ch >= 65 && ch <= 90 ) || // A...Z
      ( ch >= 97 && ch <= 122 ) || // a...z
      ( ch >= 128 && !structKeyExists( variables.operators, chr( ch ) ) ); // any non-ASCII that is not an operator
  }

  private boolean function isIdentifierPart( ch ) {
    // `ch` is a character code
    return ( ch == 95 ) || ( ch == 44 ) || // `_` and `,`
      ( ch >= 65 && ch <= 90 ) || // A...Z
      ( ch >= 97 && ch <= 122 ) || // a...z
      ( ch >= 48 && ch <= 57 ) || // 0...9
      ( ch >= 128 && !structKeyExists( variables.operators, chr( ch ) ) ); // any non-ASCII that is not an operator
  }

  private string function exprI( required numeric index ) {
    return mid( variables.expression, index, 1);
  }

  private numeric function exprICode( required numeric index ) {
    return asc( exprI( index ) );
  }

  /**
   *  Push `index` up to the next non-space character
   */
  private void function gobbleSpaces() {
    var ch = exprICode( index );
    // space or tab
    while (ch == 32 || ch == 9 || ch == 10 || ch == 13) {
      ch = exprICode( ++index );
    }
  }

  /**
   *  The main parsing function. Much of this code is dedicated to ternary expressions
   */
  private struct function gobbleExpression( ) {
    var test = gobbleBinaryExpression();
    gobbleSpaces();
    return test;
  }

  /**
   *  Search for the operation portion of the string (e.g. `eq`)
   * Start by taking the longest possible binary operations (4 characters: `eq`, `neq`, `like`)
   * and move down from 4 to 3 to 2 character until a matching binary operation is found
   * then, return that binary operation
   */
  private any function gobbleBinaryOp() {
    gobbleSpaces();
    var toCheck = mid( variables.expression, index, maxBinaryOperationLength );
    var tcLen = len( toCheck );
    while ( tcLen > 0 ) {
      if ( structKeyExists( variables.operators, toCheck ) ) {
        index += tcLen;
        return toCheck;
      }
      toCheck = mid( toCheck, 1, --tcLen );
    }
    return '';
  }

  /**
   *  This function is responsible for gobbling an individual expression,
   * e.g. `1`, `1+2`, `a+(b*2)-Math.sqrt(2)`
   */
  private any function gobbleBinaryExpression() {
    var node = '';

    // First, try to get the leftmost thing
    // Then, check to see if there's a binary operator operating on that leftmost thing
    var left = gobbleToken();
    var binaryOperator = gobbleBinaryOp();
    // If there wasn't a binary operator, just return the leftmost node
    if ( binaryOperator == '' ) {
      return left;
    }

    // Otherwise, we need to start a stack to properly place the binary operations in their
    // precedence structure
    var binaryOperatorInfo = {
      'value': binaryOperator
      ,'prec': binaryPrecedence( binaryOperator )
    };

    var right = gobbleToken();
    if ( right.error ) {
      throwError( 'Expected expression after ' & binaryOperator, index );
    }
    var stack = [ left, binaryOperatorInfo, right ];

    // Properly deal with precedence using [recursive descent](http://www.engr.mun.ca/~theo/Misc/exp_parsing.htm)
    while ( (binaryOperator = gobbleBinaryOp()) != ''  ) {
      var prec = binaryPrecedence( binaryOperator );
      if ( prec == 0 ) {
        break;
      }
      binaryOperatorInfo = {
        'value': binaryOperator
        ,'prec': prec
      };

      // Reduce: make a binary expression from the three topmost entries.
      while ( ( stack.len() > 2 ) && ( prec <= stack[ stack.len() - 1 ].prec ) ) {

        right = stack[ stack.len() ];
        stack.deleteAt( stack.len() );

        binaryOperator = stack[ stack.len() ].value;
        stack.deleteAt( stack.len() );

        left = stack[ stack.len() ];
        stack.deleteAt( stack.len() );

        node = createBinaryExpression( binaryOperator, left, right );
        stack.append( node );

      }

      node = gobbleToken();
      if ( node.error ) {
        throwError( 'Expected expression after ' & binaryOperator, index );
      }
      stack.append( binaryOperatorInfo );
      stack.append( node );
    }

    var i = stack.len();
    node = stack[ i ];
    while ( i > 2 ) {
      node = createBinaryExpression( stack[ i - 1 ].value, stack[ i - 2 ], node );
      i -= 2;
    }
    return node;
  }

  /**
   *  An individual part of a binary expression:
   * e.g. `foo.bar(baz)`, `1`, `"abc"`, `(a % 2)` (because it's in parenthesis)
   */
  private any function gobbleToken() {
    var ch;

    gobbleSpaces();
    ch = exprICode( index );

    if ( isDecimalDigit( ch ) || ch == variables.PERIOD_CODE ) {
      // Char code 46 is a dot `.` which can start off a numeric literal
      return gobbleNumericLiteral();
    }
    else if ( ch == variables.DQUOTE_CODE ) {
      // double quotes
      return gobbleStringLiteral();
    }
    else {
      if ( isIdentifierStart( ch ) || ch == variables.OPAREN_CODE ) { // open parenthesis
        // `foo`
        return gobbleVariable();
      }
    }

    return { 'error': true };
  }

  /**
   *  Parse simple numeric literals: `12`, `3.4`, `.5`. Do this by using a string to
   * keep track of everything in the numeric literal and then calling `parseFloat` on that string
   */
  private struct function gobbleNumericLiteral() {
    var number = '';
    var ch = '';
    var chCode = 0;

    while ( isDecimalDigit( exprICode( index ) ) ) {
      number &= exprI( index++ );
    }

    if ( exprICode( index ) == variables.PERIOD_CODE ) { // can start with a decimal marker
      number &= exprI( index++ );

      while ( isDecimalDigit( exprICode( index ) ) ) {
        number &= exprI( index++ );
      }
    }

    ch = exprI( index );
    if ( ch == 'e' || ch == 'E' ) { // exponent marker
      number &= exprI( index++ );
      ch = exprI( index );
      if ( ch == '+' || ch == '-' ) { // exponent sign
        number &= exprI( index++ );
      }
      while ( isDecimalDigit( exprICode( index ) ) ) { //exponent itself
        number &= exprI( index++ );
      }
      if ( !isDecimalDigit( exprICode( index ) ) ) {
        throwError( 'Expected exponent (' & number & exprI( index ) & ')', index );
      }
    }

    chCode = exprICode( index );
    // Check to make sure this isn't a variable name that start with a number (123abc)
    if ( isIdentifierStart( chCode ) ) {
      throwError( 'Variable names cannot start with a number (' &
        number & exprI( index ) & ')', index );
    }
    else if ( chCode == variables.PERIOD_CODE ) {
      throwError( 'Unexpected period', index );
    }

    return {
      'type': variables.LITERAL
      ,'value': LSParseNumber( number )
      ,'raw': number
      ,'error': false
    };
  }

  /**
   *  Parses a string literal, staring with single or double quotes with basic support for escape codes
   * e.g. `"hello world"`
   */
  private struct function gobbleStringLiteral() {
    var str = '';
    var quote = exprI( index++ );
    var closed = false;
    var ch = '';

    while ( index <= length ) {
      ch = exprI( index++ );
      if ( ch == quote ) {
        closed = true;
        break;
      }
      else {
        str &= ch;
      }
    }

    if ( !closed ) {
      throwError( 'Unclosed quote after "' & str & '"', index );
    }

    return {
      'type': variables.LITERAL
      ,'value': str
      ,'raw': quote & str & quote
      ,'error': false
    };
  }

  /**
  *  Gobbles only identifiers
  * e.g.: `foo`, `_value`, `x1`
  * Also, this function checks if that identifier is a literal:
  * (e.g. `true`, `false`, `null`)
  */

  private struct function gobbleIdentifier() {
    var ch = exprICode( index );
    var start = index;
    var identifier = '';

    if ( isIdentifierStart( ch ) ) {
      index++;
    }
    else {
      throwError( 'Unexpected ' & exprI( index ), index );
    }

    while ( index <= length ) {
      ch = exprICode( index );
      if ( isIdentifierPart( ch ) ) {
        index++;
      }
      else {
        break;
      }
    }

    identifier = mid( variables.expression, start, index - start );

    if ( structKeyExists( variables.literals, identifier ) ) {
      return {
        'type': variables.LITERAL
        ,'value': variables.literals[ identifier ]
        ,'raw': identifier
        ,'error': false
      };
    }
    else {
      return {
        'type': variables.IDENTIFIER
        ,'name': identifier
        ,'error': false
      };
    }
  }

  /**
   * Gobble a non-literal variable name. This variable name may include properties
   * e.g. `foo`
   * It also gobbles function calls:
   * e.g. `(obj gte 1)`
   */
  private struct function gobbleVariable() {
    var node = '';
    var ch_i = exprICode( index );
    if ( ch_i == variables.OPAREN_CODE ) {
      node = gobbleGroup();
    }
    else {
      node = gobbleIdentifier();
    }
    gobbleSpaces();
    ch_i = exprICode( index );
    return node;
  }

  /**
   * Responsible for parsing a group of things within parentheses `()`
   * This function assumes that it needs to gobble the opening parenthesis
   * and then tries to gobble everything within that parenthesis, assuming
   * that the next thing it should see is the close parenthesis. If not,
   * then the expression probably doesn't have a `)`
   */
  private struct function gobbleGroup() {
    index++;
    var node = gobbleExpression();
    gobbleSpaces();
    if ( exprICode( index ) == variables.CPAREN_CODE ) {
      index++;
      return node;
    }
    else {
      throwError( 'Unclosed (', index );
    }
  }

}