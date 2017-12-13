component {

  property name='settings' inject='coldbox:modulesettings:squrll' getter='false' setter='false';

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

  public struct function filter( required struct tree ) {
    var result = {
      'sql': ''
      ,'queryParams': {}
      ,'error': false
      ,'errorMessages': []
    };
    var sqlPrepend = settings.filterIncludeWhere ? 'WHERE ': '';
    if ( tree.type == 'LogicalExpression' ) {
      result.append( handleLogicalExpression( tree ) );
      result.sql = sqlPrepend & result.sql;
    }
    else if ( tree.type == 'BinaryExpression' ) {
      result.append( handleLogicalExpression( tree ) );
      result.sql = sqlPrepend & result.sql;
    }
    else {
      result.error = true;
      result.errorMessages.append( '#settings.filterUrlParam#: Invalid tree' );
    }

    return result;
  }

  private struct function handleLogicalExpression( required struct leaf ) {
    var sql = '';
    var params = {};
    var result = {};
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

    return { 'sql': sql, 'queryParams': params };
  }

  private struct function handleBinaryExpression(
    required struct leaf
    ,required struct params
    ,struct whiteList
    ,struct blackList
  ) {
    var sql = '';
    var param = {};
    if ( leaf.left.type == 'Identifier' ) {
      sql &= leaf.left.name & ' ';
    }
    if ( leaf.keyExists( 'operator' ) && variables.operators.keyExists( leaf.operator ) ) {
      sql &= variables.operators[ leaf.operator ] & ' ';
    }
    if ( leaf.right.type == 'Literal' ) {
      // create param
      // check whitelist for param type
      // else infer type param
      //

      sql &= leaf.right.raw & ' ';
    }
    return { 'sql': sql, 'param': param };
  }

  public string function range( required numeric offset, numeric limit ) {
    if ( arguments.keyExists( 'limit' ) ) {
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
    var sql = settings.sortIncludeOrderBy ? ' ORDER BY': ' ';
    var columnCount = columns.len();

    columns.each( function ( expression, index ) {
      var column = sortColumn( expression, ignoreWhiteList, ignoreBlackList, whiteList, blackList );
      result.error = column.error ? column.error : result.error;
      result.errorMessages.append( column.errorMessages, true );
      sql &= column.sql;
      sql &= index < columnCount ? ',' : '';
    } );

    if ( !result.error ) { result.sql = sql & ' '; }

    return result;
  }

  private struct function sortColumn(
    required string expression
    ,required boolean ignoreWhiteList
    ,required boolean ignoreBlackList
    ,required struct whiteList
    ,required struct blackList
  ) {
    var result = {
      'sql': ''
      ,'error': false
      ,'errorMessages': []
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
      result.errorMessages.append( '#settings.sortUrlParam#: Empty list!' );
    }

    // Sort Column
    if ( refind( '[^\w\.,]+', parts[ 1 ] ) ) {
      result.error = true;
      result.errorMessages.append( '#settings.sortUrlParam#: Column "#parts[ 1 ]#" contains illegal characters.' );
    }
    else if (
      ( ignoreWhiteList || whiteList.keyExists( parts[ 1 ] ) ) &&
      ( ignoreBlackList || ( !blackList.keyExists( parts[ 1 ] ) || whiteList.keyExists( parts[ 1 ] ) ) )
    ) {
      result.sql &= ' #parts[ 1 ]#';
    }
    else {
      result.error = true;
      result.errorMessages.append( '#settings.sortUrlParam#: Column "#parts[ 1 ]#" does not exist or is not allowed here.' );
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
      result.errorMessages.append( '#settings.sortUrlParam#: Invalid direction "#parts[ 2 ]#"' );
    }

    // Null handling
    if ( length > 2 ) {
      if ( nulls.keyExists( parts[ 3 ] ) ) {
        result.sql &= ' #nulls[ parts[ 3 ] ]#';
      }
      else {
        result.error = true;
        result.errorMessages.append( '#settings.sortUrlParam#: Invalid modifier "#parts[ 3 ]#"' );
      }
    }

    // 4th+ params
    if ( parts.len() > 3 ) {
      result.error = true;
      result.errorMessages.append( '#settings.sortUrlParam#: Column "#expression#" has too many parameter.' );
    }

    return result;
  }

}