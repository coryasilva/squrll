component extends="testbox.system.BaseSpec" {

  function beforeAll() {
    // Create target mock object
    mock = prepareMock( createObject( 'component', 'models.Validator' ) );
    mock.init();
  }

  function run() {

    describe( 'Validator', function () {
      it( 'can check cf sql types for validity', function () {
        expect( mock.isValid( 'smallint', '32767' ) ).toBeTrue();
        expect( mock.isValid( 'integer', '2147483647' ) ).toBeTrue();
        expect( mock.isValid( 'int', '2147483647' ) ).toBeTrue();
        expect( mock.isValid( 'bigint', '9223372036854775807' ) ).toBeTrue();
        expect( mock.isValid( 'numeric', '9223372036854775807.9223372036854775807' ) ).toBeTrue();
        expect( mock.isValid( 'decimal', '9223372036854775807.9223372036854775807' ) ).toBeTrue();
        expect( mock.isValid( 'money', '92233720368547758.07' ) ).toBeTrue();
        expect( mock.isValid( 'money4', '21474836.47' ) ).toBeTrue();
        expect( mock.isValid( 'float', '12.345678' ) ).toBeTrue();
        expect( mock.isValid( 'double', '12.345678' ) ).toBeTrue();
        expect( mock.isValid( 'real', '12.345678' ) ).toBeTrue();
        expect( mock.isValid( 'date', '2016-02-29' ) ).toBeTrue();
        expect( mock.isValid( 'time', '08:30:00' ) ).toBeTrue();
        expect( mock.isValid( 'timestamp', '2016-02-29T08:30:00.001Z' ) ).toBeTrue();
        expect( mock.isValid( 'bit', '01010' ) ).toBeTrue();
        expect( mock.isValid( 'char', 'Hello World!' ) ).toBeTrue();
        expect( mock.isValid( 'varchar', 'What''s up?' ) ).toBeTrue();
        expect( mock.isValid( 'nvarchar', 'You are "##1"' ) ).toBeTrue();
        expect( mock.isValid( 'longvarchar', 'blah' ) ).toBeTrue();
        expect( mock.isValid( 'longnvarchar', 'blah' ) ).toBeTrue();
        expect( function () { mock.isValid( 'refcursor', '' ); } ).toThrow( regex='not implemented' );
        expect( function () { mock.isValid( 'blob', '' ); } ).toThrow( regex='not implemented' );
        expect( function () { mock.isValid( 'clob', '' ); } ).toThrow( regex='not implemented' );
        expect( function () { mock.isValid( 'idstamp', '' ); } ).toThrow( regex='not implemented' );
        expect( function () { mock.isValid( 'tinyint', '' ); } ).toThrow( regex='not implemented' );
      } );

      it( 'can validate String', function () {
        expect( mock._isString( 'blah' ) ).toBeTrue();
        expect( mock._isString( '2017-02-29' ) ).toBeTrue();
        expect( mock._isString( '2016' ) ).toBeTrue();
        expect( mock._isString( 'false' ) ).toBeTrue();
        expect( mock._isString( 'true' ) ).toBeTrue();
        expect( mock._isString( 'null' ) ).toBeTrue();
        expect( function () { mock._isString( {} ); } ).toThrow();
        expect( function () { mock._isString( [] ); } ).toThrow();
      } );

      it( 'can validate Numeric', function () {
        expect( mock._isNumeric( '1.02' ) ).toBeTrue();
        expect( mock._isNumeric( '0.01' ) ).toBeTrue();
        expect( mock._isNumeric( '1e-10' ) ).toBeFalse();
        expect( mock._isNumeric( '20,000,123' ) ).toBeFalse();
      } );

      it( 'can validate Small Int', function () {
        expect( mock._isSmallInt( '-32768' ) ).toBeTrue();
        expect( mock._isSmallInt( '-32769' ) ).toBeFalse();
        expect( mock._isSmallInt( '32767' ) ).toBeTrue();
        expect( mock._isSmallInt( '32768' ) ).toBeFalse();
        expect( mock._isSmallInt( '100.1' ) ).toBeFalse();
      } );

      it( 'can validate Integer', function () {
        expect( mock._isInteger( '-2147483648' ) ).toBeTrue();
        expect( mock._isInteger( '-2147483649' ) ).toBeFalse();
        expect( mock._isInteger( '2147483647' ) ).toBeTrue();
        expect( mock._isInteger( '2147483648' ) ).toBeFalse();
        expect( mock._isInteger( '100.1' ) ).toBeFalse();
      } );

      it( 'can validate Big Int', function () {
        // This one gets hairy as it overflows coldfusions prevents the number from overflowing
        expect( mock._isBigInt( '-9223372036854775808' ) ).toBeTrue();
        // expect( mock._isBigInt( '-9223372036854775809' ) ).toBeFalse();
        expect( mock._isBigInt( '-92233720368547758090' ) ).toBeFalse();
        expect( mock._isBigInt( '9223372036854775807' ) ).toBeTrue();
        // expect( mock._isBigInt( '9223372036854775808' ) ).toBeFalse();
        expect( mock._isBigInt( '92233720368547758080' ) ).toBeFalse();
        expect( mock._isBigInt( '100.1' ) ).toBeFalse();
      } );

      it( 'can validate Money (4 bit)', function () {
        expect( mock._isMoney4( '-21474836.48' ) ).toBeTrue();
        expect( mock._isMoney4( '-21474836.49' ) ).toBeFalse();
        expect( mock._isMoney4( '21474836.47' ) ).toBeTrue();
        expect( mock._isMoney4( '21474836.48' ) ).toBeFalse();
        expect( mock._isMoney4( '100.255' ) ).toBeFalse();
      } );

      it( 'can validate Money', function () {
        expect( mock._isMoney( '-92233720368547758.08' ) ).toBeTrue();
        // expect( mock._isMoney( '-92233720368547758.09' ) ).toBeFalse();
        expect( mock._isMoney( '-922337203685477580.09' ) ).toBeFalse();
        expect( mock._isMoney( '92233720368547758.07' ) ).toBeTrue();
        // expect( mock._isMoney( '92233720368547758.08' ) ).toBeFalse();
        expect( mock._isMoney( '922337203685477580.08' ) ).toBeFalse();
        expect( mock._isMoney( '100.255' ) ).toBeFalse();
      } );

      it( 'can validate Bit', function () {
        expect( mock._isBit( '0' ) ).toBeTrue();
        expect( mock._isBit( '1' ) ).toBeTrue();
        expect( mock._isBit( '10101' ) ).toBeTrue();
        expect( mock._isBit( 'a101' ) ).toBeFalse();
        expect( mock._isBit( '012' ) ).toBeFalse();
      } );

      it( 'can validate Boolean', function () {
        expect( mock._isBoolean( 'true' ) ).toBeTrue();
        expect( mock._isBoolean( 'True' ) ).toBeTrue();
        expect( mock._isBoolean( 'TRUE' ) ).toBeTrue();
        expect( mock._isBoolean( 'false' ) ).toBeTrue();
        expect( mock._isBoolean( 'False' ) ).toBeTrue();
        expect( mock._isBoolean( 'FALSE' ) ).toBeTrue();
        expect( mock._isBoolean( '' ) ).toBeFalse();
        expect( mock._isBoolean( '1' ) ).toBeFalse();
        expect( mock._isBoolean( 'Yes' ) ).toBeFalse();
        expect( mock._isBoolean( 'On' ) ).toBeFalse();
      } );

      it( 'can validate null', function () {
        expect( mock._isNull( 'null' ) ).toBeTrue();
        expect( mock._isNull( 'Null' ) ).toBeTrue();
        expect( mock._isNull( 'NULL' ) ).toBeTrue();
        expect( mock._isNull( '' ) ).toBeFalse();
      } );

      it( 'can validate an ISO Date', function () {
        expect( mock._isDate( '2016-02-29' ) ).toBeTrue(); // leap year
        expect( mock._isDate( '2017-02-29' ) ).toBeFalse();
        expect( mock._isDate( '2016-13-29' ) ).toBeFalse();
        expect( mock._isDate( '2016-12-31' ) ).toBeTrue();
      } );

      it( 'can validate ISO Date Time', function () {
        expect( mock._isDateTime( '2018-01-01T00:00:01.111' ) ).toBeTrue();
        expect( mock._isDateTime( '2018-01-01T00:00:01' ) ).toBeTrue();
        expect( mock._isDateTime( '2018-01-01T08:30' ) ).toBeTrue();
        expect( mock._isDateTime( '2018-01-01T00:00:00Z' ) ).toBeTrue();
        expect( mock._isDateTime( '2018-01-01T00:00:00Z12' ) ).toBeTrue();
        expect( mock._isDateTime( '2018-01-01T00:00:00Z12:00' ) ).toBeTrue();
        expect( mock._isDateTime( '2018-01-01T00:00:00Z-12' ) ).toBeTrue();
        expect( mock._isDateTime( '2018-01-01T00:00:00Z-12:00' ) ).toBeTrue();
        expect( mock._isDateTime( '2018-01-01T00:00:00Z-12' ) ).toBeTrue();
        expect( mock._isDateTime( '2018-01-01T00:00:00Z-12:00' ) ).toBeTrue();
      } );

      it( 'can validate ISO Date Time Offset', function () {
        expect( mock._isDateTimeOffset( '2018-01-01T00:00:00Z' ) ).toBeTrue();
        expect( mock._isDateTimeOffset( '2018-01-01T00:00:00Z12' ) ).toBeTrue();
        expect( mock._isDateTimeOffset( '2018-01-01T00:00:00Z12:00' ) ).toBeTrue();
        expect( mock._isDateTimeOffset( '2018-01-01T00:00:00Z-12' ) ).toBeTrue();
        expect( mock._isDateTimeOffset( '2018-01-01T00:00:00Z-12:00' ) ).toBeTrue();
        expect( mock._isDateTimeOffset( '2018-01-01T00:00:00Z-12' ) ).toBeTrue();
        expect( mock._isDateTimeOffset( '2018-01-01T00:00:00Z-12:00' ) ).toBeTrue();
      } );

    } );

  }

}