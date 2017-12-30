component {

  public Validator function init() {
    return this;
  }

  public boolean function isValid( required string cfsqltype, required string value ) {
    var map = {
       'smallint':     '_isSmallInt'
      ,'integer':      '_isInteger'
      ,'int':          '_isInteger'
      ,'bigint':       '_isBigInt'
      ,'numeric':      '_isNumeric'
      ,'decimal':      '_isNumeric'
      ,'money':        '_isMoney'
      ,'money4':       '_isMoney4'
      ,'float':        '_isNumeric' // not ideal
      ,'double':       '_isNumeric' // not ideal
      ,'real':         '_isNumeric' // not ideal
      ,'date':         '_isDate'
      ,'time':         '_isTime'
      ,'timestamp':    '_isDateTime'
      ,'bit':          '_isBit'
      ,'char':         '_isString'
      ,'varchar':      '_isString'
      ,'nvarchar':     '_isString'
      ,'longvarchar':  '_isString'
      ,'longnvarchar': '_isString'
      ,'refcursor':    '' // Not Implemented
      ,'blob':         '' // Not Implemented
      ,'clob':         '' // Not Implemented
      ,'idstamp':      '' // Not Implemented
      ,'tinyint':      '' // Not Implemented
      ,'boolean':      '_isBoolean' // Not part of cfml spec but useful with postgres
    };
    var type = replace( cfsqltype, 'cf_sql_', '' );
    var method = map[ type ]

    if ( !map.keyExists( type ) ) {
      throw( 'Column type invalid', 'Squrll' );
    }
    if ( method == '' ) {
      throw( 'Column type not implemented: #type#', 'Squrll' );
    }

    return this[ method ]( value );
  }

  public boolean function _isString( required string value ) {
    return isSimpleValue( value );
  }

  public boolean function _isNumeric( required string value ) {
    return isNumeric( value );
  }

  public boolean function _isSmallInt( required string value ) {
    if ( !isNumeric( value ) ) { return false; }
    var number = lsParseNumber( value );
    return number % 1 == 0 && number >= -32768 && number <= 32767;
  }

  public boolean function _isInteger( required string value ) {
    if ( !isNumeric( value ) ) { return false; }
    var number = lsParseNumber( value );
    return number % 1 == 0 && number >= -2147483648 && number <= 2147483647;
  }

  public boolean function _isBigInt( required string value ) {
    if ( !isNumeric( value ) ) { return false; }
    var number = lsParseNumber( value );
    return number % 1 == 0 && number >= -9223372036854775808 && number <= 9223372036854775807;
  }

  public boolean function _isMoney4( required string value ) {
    if ( !isNumeric( value ) ) { return false; }
    var number = lsParseNumber( value );
    var decimalIndex = find( '.', value );
    return ( decimalIndex == len( value ) - 2 ) && number >= -21474836.48 && number <= 21474836.47;
  }

  public boolean function _isMoney( required string value ) {
    if ( !isNumeric( value ) ) { return false; }
    var number = lsParseNumber( value );
    var decimalIndex = find( '.', value );
    return ( decimalIndex == len( value ) - 2 ) && number >= -92233720368547758.08 && number <= 92233720368547758.07;
  }

  public boolean function _isBit( required string value ) {
    return reFind( '[^01]', value ) == 0;
  }

  public boolean function _isBoolean( required string value ) {
    value = '_' & value;
    var bools = [ '_t','_true','_y','_yes','_on','_1','_f','_false','_n','_no','_off','_0' ];
    return bools.findNoCase( value ) != 0;
  }

  public boolean function _isNull( required string value ) {
    return value == 'null';
  }

  public boolean function _isDate( required string value ) {
    var regex = '^(\d{4}-\d\d-\d\d)$';
    var regexTest = reFind( regex, value ) == 1;
    return regexTest && isValid( 'date', value );
  }

  public boolean function _isDateTime( required string value ) {
    var regex = '^(\d{4}-\d\d-\d\d)T(\d\d:\d\d:\d\d(.\d{3})?|\d\d:\d\d)$';
    var regexTest = reFind( regex, value ) == 1;
    return _isDateTimeOffset( value ) || ( regexTest && isValid( 'date', value ) );
  }

  public boolean function _isDateTimeOffset( required string value ) {
    var regex = '^(\d{4}-\d\d-\d\d)T(\d\d:\d\d:\d\d(.\d{3})?|\d\d:\d\d)Z([+-]?[01]\d:[0-5]\d|[+-]?[01]\d)?$';
    var regexTest = reFind( regex, value ) == 1;
    var datePart = mid( value, 1, find( 'Z', value ) - 1 );
    return regexTest && isValid( 'date', datePart );
  }

  public boolean function _isTime( required string value ) {
    var regex = '^(\d\d:\d\d:\d\d(.\d{3})?|\d\d:\d\d)$';
    var regexTest = reFind( regex, value ) == 1;
    return _isTimeOffset( value ) || ( regexTest && isValid( 'date', value ) );
  }

  public boolean function _isTimeOffset( required string value ) {
    var regex = '^(\d\d:\d\d:\d\d(.\d{3})?|\d\d:\d\d)Z([+-]?[01]\d:[0-5]\d|[+-]?[01]\d)?$';
    var regexTest = reFind( regex, value ) == 1;
    var datePart = mid( value, 1, find( 'Z', value ) - 1 );
    return regexTest && isValid( 'date', datePart );
  }

}