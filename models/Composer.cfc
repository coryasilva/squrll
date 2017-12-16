component {

  property name='settings' inject='coldbox:modulesettings:squrll' getter='false' setter='false';

  variables.sqlTypes = {
    'bigint': 'bigint'
    ,'bit': 'bit'
    ,'char': 'char'
    ,'blob': 'blob'
    ,'clob': 'clob'
    ,'date': 'date'
    ,'decimal': 'decimal'
    ,'double': 'double'
    ,'float': 'float'
    ,'idstamp': 'idstamp'
    ,'int': 'integer'
    ,'integer': 'integer'
    ,'longvarchar': 'longvarchar'
    ,'longnvarchar': 'longnvarchar'
    ,'money': 'money'
    ,'money4': 'money4'
    ,'numeric': 'numeric'
    ,'real': 'real'
    ,'refcursor': 'refcursor'
    ,'smallint': 'smallint'
    ,'time': 'time'
    ,'timestamp': 'timestamp'
    ,'tinyint': 'tinyint'
    ,'varchar': 'varchar'
    ,'nvarchar': 'nvarchar'
  };

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

  public struct function filter( required struct tree, struct whiteList={}, struct blackList={} ) {
    var result = {
      'sql': ''
      ,'queryParams': {}
      ,'error': false
      ,'errorMessages': []
    };
    if ( tree.type == 'LogicalExpression' ) {
      result.append( handleLogicalExpression( tree, {}, whiteList, blackList ) );
      result.sql = ' #settings.filterPrepend# #result.sql#';
    }
    else if ( tree.type == 'BinaryExpression' ) {
      result.append( handleBinaryExpression( tree, {}, whiteList, blackList ) );
      result.sql = ' #settings.filterPrepend# #result.sql#';
    }
    else {
      result.error = true;
      result.errorMessages.append( '#settings.filterUrlParam#: Invalid tree' );
    }

    if ( result.error ) { result.sql = ''; }

    return result;
  }

  private struct function handleLogicalExpression(
    required struct leaf
    ,required struct queryParams
    ,required struct whiteList
    ,required struct blackList
  ) {
    var result = {
      'sql': ''
      ,'queryParams': queryParams
      ,'error': false
      ,'errorMessages': []
    };
    var temp = {};

    if ( leaf.left.type == 'LogicalExpression' ) {
      temp = handleLogicalExpression( leaf.left, queryParams, whiteList, blackList )
      result.sql &= '( ' & temp.sql & ') ';
    }

    if ( leaf.left.type == 'BinaryExpression' ) {
      temp = handleBinaryExpression( leaf.left, queryParams, whiteList, blackList  );
      result.sql &= temp.sql;
    }

    if ( leaf.operator == 'and' ) {
      result.sql &= 'AND ';
    }

    if ( leaf.operator == 'or' ) {
      result.sql &= 'OR ';
    }

    if ( leaf.right.type == 'BinaryExpression' ) {
      temp = handleBinaryExpression( leaf.right, queryParams, whiteList, blackList  );
      result.sql &= temp.sql;
    }

    if ( leaf.right.type == 'LogicalExpression' ) {
      temp = '( ' & handleLogicalExpression( leaf.right, queryParams, whiteList, blackList ) & ') ';
      result.sql &= temp.sql;
    }

    //result.queryParams.append( temp.queryParams );
    //result.errorMessages.append( temp.errorMessages, true );
    //result.error = temp.error ? temp.error : result.error;

    return result;
  }

  private struct function handleBinaryExpression(
    required struct leaf
    ,required struct queryParams
    ,required struct whiteList
    ,required struct blackList
  ) {
    var result = {
      'sql': ''
      ,'queryParams': queryParams
      ,'error': false
      ,'errorMessages': []
    };

    // 1 = 1 is not allowed
    if ( leaf.left.type == 'Literal' && leaf.right.type == 'Literal' ) {
      result.error = true;
      result.errorMessages.append( '#settings.filterUrlParam#: Binary expression cannot contain two literals' );
      return result;
    }

    // column1 = column2 is allowed but not column1 = column1
    if ( leaf.left.type == 'Identifier' && leaf.right.type == 'Identifier' && leaf.left.name == leaf.right.name ) {
      result.error = true;
      result.errorMessages.append( '#settings.filterUrlParam#: Binary expression cannot contain two literals' );
      return result;
    }

    if ( leaf.left.type == 'Identifier' ) {
      result.sql &= leaf.left.name & ' ';
      if ( !columnAllowed( leaf.left.name, whiteList, blackList ) ) {
        result.error = true;
        result.errorMessages.append( '#settings.filterUrlParam#: Column "#leaf.left.name#" does not exist or is not allowed here.' );
      }
    }

    // TODO: Handle left Literal

    if ( leaf.keyExists( 'operator' ) && variables.operators.keyExists( leaf.operator ) ) {
      result.sql &= variables.operators[ leaf.operator ] & ' ';
    }

    // TODO: Handle right Identifier

    if ( leaf.right.type == 'Literal' ) {
      result.sql &= leaf.right.raw & ' ';

      // TODO: create param; check whitelist for param type else infer type param
      // TODO: dedupe queryParamName or simply use a counter??
      // TODO: Handle Null
      //'cf_sql_'
      //'sql_'
      // null: true, list:true, separator: ','
      // var sqlType = whiteList.keyExists( leaf.left.name ) ? whiteList[ leaf.left.name ] : '';
    }
    return result;
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
    var sql = ' #settings.sortPrepend#';
    var columnCount = columns.len();

    columns.each( function ( expression, index ) {
      var column = sortColumn( expression, whiteList, blackList );
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
    if ( refind( '[^\w\.]+', parts[ 1 ] ) != 0 ) {
      result.error = true;
      result.errorMessages.append( '#settings.sortUrlParam#: Column "#parts[ 1 ]#" contains illegal characters.' );
    }
    else if ( columnAllowed( parts[ 1 ], whiteList, blackList ) ) {
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

  private boolean function columnAllowed(
    required string column
    ,required struct whiteList
    ,required struct blackList
  ) {
    return ( ( whiteList.isEmpty() && settings.ignoreEmptyWhiteList ) || whiteList.keyExists( column ) ) &&
      ( blackList.isEmpty() || ( !blackList.keyExists( column ) || whiteList.keyExists( column ) ) );
  }

}