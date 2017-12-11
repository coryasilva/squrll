component accessors='false' {

  property name="settings" inject="coldbox:modulesettings:squrll" getter="false" setter="false";

  public Squrll function init() {
    return this;
  }

  // TODO:
  public struct function getSql( required struct urlParams, struct opts={} ) {
    var params = matchParamNames( urlParams );
    var options = defaultOptions( opts );

    var result = {
      'count': getCountSql( params.count ).count
      ,'filter': false
      ,'sort': false
      ,'range': false
      ,'error': false
      ,'errorMessages': []
    };

    return result
  }

  // TODO:
  public struct function getFilterSql( required string filter ) {
    var result = {
      'filter': false
      ,'error': false
      ,'errorMessages': []
    };
    return result
  }

  // TODO:
  public struct function getSortSql( required string sort ) {
    var result = {
      'sort': false
      ,'error': false
      ,'errorMessages': []
    };
    return result
  }

  public struct function getRangeSql( string limit='', string offset='', boolean allowNoLimit=false ) {
    var result = {
      'range': ''
      ,'error': false
      ,'errorMessages': []
    };

    // Early return if no limit and offset was supplied
    if ( arguments.limit == '' && arguments.offset == '' ) {
      return result;
    }

    // Offset
    var _offset = 0;
    if ( arguments.offset != '' && reMatch('[0-9]+', arguments.offset ) ) {
      _offset = LSParseNumber( arguments.offset );
    }
    else {
      result.error = true;
      result.errorMessages.append( '#settings.offsetUrlParam# must be a postive integer' );
    }

    // Limit
    var _limit = settings.defaultLimit;
    if ( arguments.limit != '' && reMatch('[0-9]+', arguments.limit ) ) {
      _limit = LSParseNumber( arguments.limit );
    }
    else {
      result.error = true;
      result.errorMessages.append( '#settings.limitUrlParam# must be a postive integer' );
    }

    // If no limit allowed and offset was defined
    if ( allowNoLimt && !result.error && arguments.limit == '' && arguments.offset != '' ) {
      result.range = composeRange( _offset );
    }
    else {
      result.range = composeRange( _offset, _limit );
    }

    return result;
  }

  public struct function getCountSql( required string value ) {
    var count = false;

    if ( len( value ) >= 1 && value != '0' && value != 'n' && value != 'false' ) {
      count = true;
    }

    return {
      'count': count
      ,'error': false
      ,'errorMessages': []
    };
  }

  private struct function defaultOptions( required struct options ) {
    var defaults = {
      'allowNoLimit': false
    };
    return defaults;
  }

  private struct function matchParamNames( required struct params ) {
    var defaults = {};
    defaults[ settings.countUrlParam ] = '';
    defaults[ settings.filterUrlParam ] = '';
    defaults[ settings.sortUrlParam ] = '';
    defaults[ settings.limitUrlParam ] = '';
    defaults[ settings.offsetUrlParam ] = '';

    defaults.append( params );

    var matchedParams = {
      'count': params[ settings.countUrlParam ]
      ,'filter': params[ settings.filterUrlParam ]
      ,'sort': params[ settings.sortUrlParam ]
      ,'limit': params[ settings.limitUrlParam ]
      ,'offset': params[ settings.offsetUrlParam ]
    };

    return matchedParams;
  }

  private string function composeRange( required numeric offset, numeric limit ) {
    if ( arguments.keyExists( limit ) ) {
      return ' LIMIT #limit# OFFSET #offset# ';
    }
    return ' LIMIT ALL OFFSET #offset# ';
  }

  private string function composeSort( required array columns ) {
    var sql = ' ORDER BY ';
    sql &= columns.each( parseSortColumn );
    return sql;
  }

  private string function parseSortColumn( required string column ) {
    var sql = '';
    return sql;
  }

}