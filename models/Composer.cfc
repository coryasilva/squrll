component {

  property name='settings' inject='coldbox:modulesettings:squrll' getter='false' setter='false';
  property name='Validator' inject='Validator';

  variables.operators = {
    'or':      'OR'
    ,'and':    'AND'
    ,'eq':     '='
    ,'neq':    '<>'
    ,'is':     'IS'
    ,'nis':    'IS NOT'
    ,'in':     'IN'
    ,'nin':    'NOT IN'
    ,'like':   'LIKE'
    ,'nlike':  'NOT LIKE'
    ,'ilike':  'ILIKE'
    ,'nilike': 'NOT ILIKE'
    ,'lt':     '<'
    ,'gt':     '>'
    ,'lte':    '<='
    ,'gte':    '>='
  };

  public Composer function init() {
    return this;
  }

  public struct function filter( required struct tree, required struct columnTypes ) {
    var result = {
      'sql':            ''
      ,'queryParams':   {}
      ,'error':         false
      ,'errorMessages': []
    };

    // Append global columntypes ( global overrides )
    columnTypes.append( settings.columnTypes, true );

    if ( tree.type == 'LogicalExpression' ) {
      result.append( handleLogicalExpression( tree, {}, columnTypes ) );
      result.sql = ' #settings.filterPrepend# #result.sql#';
    }
    else if ( tree.type == 'BinaryExpression' ) {
      result.append( handleBinaryExpression( tree, {}, columnTypes ) );
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
    ,required struct columnTypes
  ) {
    var result = {
      'sql':            ''
      ,'queryParams':   queryParams
      ,'error':         false
      ,'errorMessages': []
    };
    var temp = {};

    if ( leaf.left.type == 'LogicalExpression' ) {
      temp = handleLogicalExpression( leaf.left, queryParams, columnTypes )
      result.sql &= '( ' & temp.sql & ') ';
    }

    if ( leaf.left.type == 'BinaryExpression' ) {
      temp = handleBinaryExpression( leaf.left, queryParams, columnTypes );
      result.sql &= temp.sql;
    }

    if ( leaf.operator == 'and' ) {
      result.sql &= 'AND ';
    }

    if ( leaf.operator == 'or' ) {
      result.sql &= 'OR ';
    }

    if ( leaf.right.type == 'BinaryExpression' ) {
      temp = handleBinaryExpression( leaf.right, queryParams, columnTypes );
      result.sql &= temp.sql;
    }

    if ( leaf.right.type == 'LogicalExpression' ) {
      temp = '( ' & handleLogicalExpression( leaf.right, queryParams, columnTypes ) & ') ';
      result.sql &= temp.sql;
    }

    result.queryParams.append( temp.queryParams );
    result.errorMessages.append( temp.errorMessages, true );
    result.error = temp.error ? temp.error : result.error;

    return result;
  }

  private struct function handleBinaryExpression(
    required struct leaf
    ,required struct queryParams
    ,required struct columnTypes
  ) {
    var result = {
      'sql':            ''
      ,'queryParams':   queryParams
      ,'error':         false
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
      if ( !columnTypes.keyExists( leaf.left.name ) ) {
        result.error = true;
        result.errorMessages.append( '#settings.filterUrlParam#: Column "#leaf.left.name#" does not exist or is not allowed here.' );
      }
    }

    // TODO: Handle left Literal?
    if ( leaf.left.type == 'Literal' ) {
      result.error = true;
      result.errorMessages.append( '#settings.filterUrlParam#: Binary Expression with left side Literal has not been implemented' );
    }

    if ( leaf.keyExists( 'operator' ) && variables.operators.keyExists( leaf.operator ) ) {
      result.sql &= variables.operators[ leaf.operator ] & ' ';
    }

    if ( leaf.right.type == 'Literal' ) {
      var paramName = uniqueKey( 'squrll_' & leaf.left.name, result.queryParams );
      var paramConfig = {};
      var isNull = Validator._isNull( leaf.right.value );
      var cfSqlType = '';

      // Build query parameter config struct
      if ( isSimpleValue( columnTypes[ leaf.left.name ] ) ) {
        cfSqlType = columnTypes[ leaf.left.name ];
      }
      else if ( isStruct( columnTypes[ leaf.left.name ] ) && structKeyExists( columnTypes[ leaf.left.name ], 'cfsqltype' ) ) {
        paramConfig.append( columnTypes[ leaf.left.name ] );
        cfSqlType = columnTypes[ leaf.left.name ].cfSqlType
      }
      else {
        throw( 'ColumnType values must be a string or a struct containing a cfsqltype key', 'squrll' );
      }

      paramConfig[ 'cfsqltype' ] = transformCfSqlType( cfSqlType );

      if ( isNull ) {
        paramConfig[ 'null' ] = true;
      }
      else {
        paramConfig[ 'value' ] = leaf.right.value;
      }

      if ( !Validator.isValid( cfSqlType, leaf.right.value ) && !isNull ) {
        result.error = true;
        result.errorMessages.append( '#settings.filterUrlParam#: Invalid type supplied for column #paramName#, #leaf.right.value#' );
      }

      result.queryParams.append( { '#paramName#': paramConfig } );
      result.sql &= ':#paramName# ';
    }

    // TODO: Handle right Identifier?
    if ( leaf.right.type == 'Identifier' ) {
      result.error = true;
      result.errorMessages.append( '#settings.filterUrlParam#: Binary Expression with right side Identifier has not been implemented' );
    }

    return result;
  }

  public string function transformCfSqlType( required string type ) {
    var test = replace( type, 'cf_sql_', '' );
    if ( test == 'boolean' ) {
      return 'cf_sql_varchar';
    }
    return type;
  }

  public string function uniqueKey( required string key, required struct map ) {
    if ( map.keyExists( key ) ) {
      return uniqueKey( key & '_1', map );
    }
    return key;
  }

  public string function range( required numeric offset, numeric limit ) {
    if ( arguments.keyExists( 'limit' ) ) {
      return ' LIMIT #limit# OFFSET #offset# ';
    }
    return ' LIMIT ALL OFFSET #offset# ';
  }

  public struct function sort( required array columns, required struct columnTypes ) {
    var result = {
      'sql':            ''
      ,'error':         false
      ,'errorMessages': []
    };
    var sql = ' #settings.sortPrepend#';
    var columnCount = columns.len();

    // Append global columntypes ( global overrides )
    columnTypes.append( settings.columnTypes, true );

    columns.each( function ( expression, index ) {
      var column = sortColumn( expression, columnTypes );
      result.error = column.error ? column.error : result.error;
      result.errorMessages.append( column.errorMessages, true );
      sql &= column.sql;
      sql &= index < columnCount ? ',' : '';
    } );

    if ( !result.error ) { result.sql = sql & ' '; }

    return result;
  }

  private struct function sortColumn( required string expression, required struct columnTypes ) {
    var result = {
      'sql':            ''
      ,'error':         false
      ,'errorMessages': []
    };
    var sorts = {
      'asc':   'ASC'
      ,'dsc':  'DESC'
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

    else if ( columnTypes.keyExists( parts[ 1 ] ) ) {
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