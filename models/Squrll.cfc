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
    var range = parseRange( params.offset, params.limit, options.allowNoLimit );

    var result = {
      'count': count.sql
      ,'filter': filter.sql
      ,'queryParams': filter.queryParams
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

    return result;
  }

  public struct function parseCount( string value='' ) {
    var result = {
      'sql': ''
      ,'error': false
      ,'errorMessages': []
    };

    if ( value == 'true' ) {
      result.sql = ' COUNT(*) OVER() AS _count ';
    }

    return result;
  }

  public struct function parseFilter( string expression='' ) {
    var result = {
      'sql': ''
      ,'queryParams': {}
      ,'error': false
      ,'errorMessages': []
    };

    if ( expression == '' ) { return result; }

    var Parser = wirebox.getInstance( 'Parser' );
    var parserResult = Parser.parse( expression );

    if ( parserResult.error ) {
      result.error = parserResult.error;
      result.errorMessages = parserResult.errorMessages
      return result;
    }
    result = Composer.filter( parserResult.tree );

    return result;
  }

  public struct function parseSort( string expression='' ) {
    var result = {
      'sql': ''
      ,'error': false
      ,'errorMessages': []
    };
    if ( expression == '' ) { return result; }
    return Composer.sort( listToArray( expression, ',' ) );
  }

  public struct function parseRange( string offset='', string limit='', boolean allowNoLimit=false ) {
    var result = {
      'sql': ''
      ,'error': false
      ,'errorMessages': []
    };

    // Early return if no limit and offset was supplied
    if ( arguments.offset == '' && arguments.limit == '' ) {
      return result;
    }

    // Offset
    var _offset = 0;
    if ( arguments.offset != '' && refind('[^0-9]', arguments.offset ) == 0 ) {
      _offset = LSParseNumber( arguments.offset );
    }
    else {
      result.error = true;
      result.errorMessages.append( '#settings.offsetUrlParam# must be a postive integer' );
    }

    // Limit
    var _limit = settings.defaultLimit;
    if ( arguments.limit != '' && refind('[^0-9]', arguments.limit ) == 0 ) {
      _limit = LSParseNumber( arguments.limit );
    }
    else {
      result.error = true;
      result.errorMessages.append( '#settings.limitUrlParam# must be a postive integer' );
    }

    // If no limit allowed and offset was defined
    if ( allowNoLimit && !result.error && arguments.offset != '' && arguments.limit == '' ) {
      result.sql = Composer.range( _offset );
    }
    else {
      result.sql = Composer.range( _offset, _limit );
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
      'count':   defaults[ settings.countUrlParam ]
      ,'filter': defaults[ settings.filterUrlParam ]
      ,'sort':   defaults[ settings.sortUrlParam ]
      ,'limit':  defaults[ settings.limitUrlParam ]
      ,'offset': defaults[ settings.offsetUrlParam ]
    };

    return matchedParams;
  }

}