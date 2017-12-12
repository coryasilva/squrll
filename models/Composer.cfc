component {

  variables.operators = {
    'or': 'OR'
    ,'and': 'AND'
    ,'eq': '='
    ,'neq': '<>'
    ,'is': 'IS'
    ,'nis': 'IS NOT'
    ,'in': 'IN'
    ,'nin': 'NOT IN'
    ,'like': 'LIKE'
    ,'nlike': 'NOT LIKE'
    ,'ilike': 'ILIKE'
    ,'nilike': 'NOT ILIKE'
    ,'lt': '<'
    ,'gt': '>'
    ,'lte': '<='
    ,'gte': '>='
  };

  public Composer function init() {
    return this;
  }

  public string function filter( required struct tree ) {
    if ( tree.type == 'LogicalExpression' ) {
      return ' WHERE ' & handleLogicalExpression( tree );
    }
    if ( tree.type == 'BinaryExpression' ) {
      return ' WHERE ' & handleBinaryExpression( tree );
    }
    return '';
  }

  private string function handleLogicalExpression( leaf ) {
    var sql = '';

    if ( leaf.type == 'LogicalExpression' ) {

      if ( leaf.left.type == 'LogicalExpression' ) {
        sql &= '( ' & handleLogicalExpression( leaf.left ) & ') ';
      }

      if ( leaf.left.type == 'BinaryExpression' ) {
        sql &= handleBinaryExpression( leaf.left );
      }

      if ( leaf.operator == 'and' ) {
        sql &= 'AND ';
      }

      if ( leaf.operator == 'or' ) {
        sql &= 'OR ';
      }

      if ( leaf.right.type == 'BinaryExpression' ) {
        sql &= handleBinaryExpression( leaf.right );
      }

      if ( leaf.right.type == 'LogicalExpression' ) {
        sql &= '( ' & handleLogicalExpression( leaf.right ) & ') ';
      }

    }

    return sql;
  }

  private string function handleBinaryExpression( leaf ) {
    var sql = '';
    if ( leaf.left.type == 'Identifier' ) {
      sql &= leaf.left.name & ' ';
    }
    if ( leaf.keyExists( 'operator' ) && variables.operators.keyExists( leaf.operator ) ) {
      sql &= variables.operators[leaf.operator] & ' ';
    }
    if ( leaf.right.type == 'Literal' ) {
      sql &= leaf.right.raw & ' ';
    }
    return sql;
  }

  public string function range( required numeric offset, numeric limit ) {
    if ( arguments.keyExists( limit ) ) {
      return ' LIMIT #limit# OFFSET #offset# ';
    }
    return ' LIMIT ALL OFFSET #offset# ';
  }

  public struct function sort( required array columns, struct whiteList={}, struct blackList={} ) {
    var result = {
      'sql': ''
      ,'error': false
      ,'errorMessages': []
    };
    var ignoreWhiteList = whiteList.isEmpty();
    var ignoreBlackList = blackList.isEmpty();
    var sql = '';

    if ( columns.len() > 0 ) {
      sql = ' ORDER BY';
    }

    columns.each( function ( expression ) {
      var column = sortColumn( expression, ignoreWhiteList, ignoreBlackList, whiteList, blackList );
      result.error = column.error ? column.error : result.error;
      result.errorMessages.append( column.errorMessages, true );
      sql &= column.sort;
      sql &= ',';
    } );

    // clean trailing comma
    sql = right( sql, 1 ) == ',' ? left( sql, len( sql ) - 1 ) : sql;

    if ( !result.error ) { result.sql = sql; }

    return result;
  }

  private string function sortColumn(
    required string expression
    ,required boolean ignoreWhiteList
    ,required boolean ignoreBlackList
    ,required struct whiteList
    ,required struct blackList
  ) {
    var result = {
      'sql': ''
      ,'error': false
      ,'errorMessage': ''
    };
    var sorts = {
      'asc': 'ASC'
      ,'dsc': 'DESC'
      ,'desc': 'DESC'
    };
    var nulls = {
      'nullsfirst': 'NULLS FIRST'
      ,'nullslast': 'NULLS LAST'
    };
    var parts = listToArray( expression, '.' );
    var length = parts.len();
    // Empty Item (edge case)
    if ( length < 1 ) {
      result.error = true;
      result.errorMessages.append( 'Empty sort column!' );
    }

    // Sort Column
    if ( refind( '[^\w\.,]+', parts[ 1 ] ) ) {
      result.error = true;
      result.errorMessages.append( 'Column "#parts[ 1 ]#" contains illegal characters.' );
    }
    else if (
      ( !ignoreWhiteList && whiteList.keyExists( parts[ 1 ] ) ) ||
      ( !ignoreBlackList && !blackList.keyExists( parts[ 1 ] ) )
    ) {
      result.sql &= ' #parts[ 1 ]#';
    }
    else {
      result.error = true;
      result.errorMessages.append( 'Column "#parts[ 1 ]#" does not exist or is not allowed here.' );
    }

    // Sort direction
    if ( length == 1 ) {
      parts.append( 'asc' );
    }
    if ( sorts.keyExists( parts[ 2 ] ) ) {
      result.sql &= ' #sorts[ parts[ 2 ] ]#';
    }
    else {
      result.error = true;
      result.errorMessages.append( 'Invalid sort direction: "#parts[ 2 ]#"' );
    }

    // Null handling
    if ( length > 2 ) {
      if ( nulls.keyExists( parts[ 3 ] ) ) {
        result.sql &= ' #nulls[ parts[ 3 ] ]#';
      }
      else {
        result.error = true;
        result.errorMessages.append( 'Invalid sort modifier: "#parts[ 3 ]#"' );
      }
    }

    // 4th+ params
    if ( parts.len() > 3 ) {
      result.error = true;
      result.errorMessages.append( 'Sort column "#expression#" has too many parameter.' );
    }

    return result;
  }

}