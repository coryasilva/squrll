component accessors='false' {

  property name='settings' inject='coldbox:modulesettings:squrll' getter='false' setter='false';
  property name='wirebox' inject='wirebox' getter='false' setter='false';
  property name='Composer' inject='Composer';

  public Squrll function init() {
    return this;
  }

  public struct function parse( required struct urlParams, struct opts={} ) {
    var params = matchParamNames( urlParams );
    var options = defaultOptions( opts );

    var count = parseCount( params.count );
    var filter = parseFilter( params.filter );
    var sort = parseSort( params.sort );
    var range = parseRange( params.limit, params.offset, options.allowNoLimit );

    var result = {
      'count': count.sql
      ,'filter': filter.sql
      ,'sort': sort.sql
      ,'range': range.sql
      ,'error': false
      ,'errorMessages': []
    };

    result.error = count.error ? count.error : result.error;
    result.error = filter.error ? filter.error : result.error;
    result.error = sort.error ? sort.error : result.error;
    result.error = range.error ? range.error : result.error;

    result.errorMessages
      .append( count.errorMessages, true )
      .append( filter.errorMessages, true )
      .append( sort.errorMessages, true )
      .append( range.errorMessages, true );

    return result
  }

  public struct function parseCount( required string value ) {
    var sql = '';

    if ( len( value ) >= 1 && value != '0' && value != 'n' && value != 'false' ) {
      sql = 'COUNT(*) OVER() AS _count';
    }

    return {
      'sql': sql
      ,'error': false
      ,'errorMessages': []
    };
  }

  public struct function parseFilter( required string expression ) {
    var result = {
      'sql': ''
      ,'error': ''
      ,'errorMessages': []
    };
    var Parser = wirebox.getInstance( 'Parser' );
    var parserResult = Parser.parse( expression );

    if ( parserResult.error ) {
      result.error = parserResult.error;
      result.errorMessages = parserResult.errorMessages
      return result;
    }

    return Composer.filter( parserResult.tree );
  }

  public struct function parseSort( required string expression ) {
    return Composer.sort( listToArray( expression, ',' ) );
  }

  public struct function parseRange( string limit='', string offset='', boolean allowNoLimit=false ) {
    var result = {
      'sql': ''
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
      result.range = Composer.range( _offset );
    }
    else {
      result.range = Composer.range( _offset, _limit );
    }

    return result;
  }

  private struct function defaultOptions( required struct options ) {
    var defaults = {
      'allowNoLimit': false
    };
    return defaults;
  }

  private struct function matchParamNames( required struct params ) {
    var defaults = {};
    defaults[ settings.countUrlParam ]  = '';
    defaults[ settings.filterUrlParam ] = '';
    defaults[ settings.sortUrlParam ]   = '';
    defaults[ settings.limitUrlParam ]  = '';
    defaults[ settings.offsetUrlParam ] = '';

    defaults.append( params );

    var matchedParams = {
      'count':   params[ settings.countUrlParam ]
      ,'filter': params[ settings.filterUrlParam ]
      ,'sort':   params[ settings.sortUrlParam ]
      ,'limit':  params[ settings.limitUrlParam ]
      ,'offset': params[ settings.offsetUrlParam ]
    };

    return matchedParams;
  }

}