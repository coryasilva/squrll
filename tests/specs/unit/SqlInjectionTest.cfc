component extends='tests.base' {

  function beforeAll() {
    var mockSettings = mockSettings();
    mockSettings.columnTypes = { 'created_date': 'cf_sql_timestamp' };
    
    // Create target mock object
    mockValidator = prepareMock( createObject( 'component', 'models.Validator' ) );
    mockValidator.init();

    mockComposer = prepareMock( createObject( 'component', 'models.Composer' ) );
    mockComposer.$property( 'settings', 'variables', mockSettings );
    mockComposer.$property( 'Validator', 'variables', mockValidator );
    mockComposer.init();

    mockParser = prepareMock( createObject( 'component', 'models.Parser' ) );
    mockParser.$property( 'settings', 'variables', mockSettings );

    mockWirebox = createStub().$( 'getInstance', mockParser.init() );

    mock = prepareMock( createObject( 'component', 'models.Squrll' ) );
    mock.$property( 'settings', 'variables', mockSettings );
    mock.$property( 'wirebox', 'variables', mockWirebox );
    mock.$property( 'Composer', 'variables', mockComposer );

    mock.init();
  }

  function run() {

    describe( 'SQL comment mitigation', function () {
      var columns = { 'username': 'varchar' };
      var expectation = ' AND username = :squrll_username ';

      it( 'can mitigate SQL injection /*', function () {
        var badValue = '1'' or ''1'' = ''1''))/*';
        var mockURL = { 'filter': 'username eq "1'' or ''1'' = ''1''))/*"' };
        var test = mock.parse( mockURL, columns );
        expect( test.filter ).toBe( expectation );
        expect( test.queryParams.squrll_username.value ).toBe( badValue );
      } );

      it( 'can mitigate SQL injection --', function () {
        var badValue = '1'' or ''1'' = ''1''--';
        var mockURL= { 'filter': 'username eq "1'' or ''1'' = ''1''--"' };
        var test = mock.parse( mockURL, columns );
        expect( test.filter ).toBe( expectation );
        expect( test.queryParams.squrll_username.value ).toBe( badValue );
      } );

    } );

    describe( 'SQL 1=1 mitigation', function () {
      /* When prefixing the filter clause with AND this does not really matter
         but should still not be allowed. */
      var columns = { 'username': 'varchar' };

      it( 'can mitigate SQL injection 1=1', function () {
        var mockURL = { 'filter': '1 eq 1' };
        var test = mock.parse( mockURL, columns );
        expect( test.error ).toBeTrue();
        expect( test.filter ).toBe( '' );
      } );

      it( 'can mitigate SQL injection "a" = "a"', function () {
        var mockURL = { 'filter': '"a" eq "a"' };
        var test = mock.parse( mockURL, columns );
        expect( test.error ).toBeTrue();
        expect( test.filter ).toBe( '' );
      } );

      it( 'can mitigate SQL injection column = column', function () {
        var mockURL = { 'filter': 'column eq column' };
        var test = mock.parse( mockURL, columns );
        expect( test.error ).toBeTrue();
        expect( test.filter ).toBe( '' );
      } );

      it( 'can mitigate SQL injection ABC=A', function () {
        var mockURL = { 'filter': '"ABC" gt "A"' };
        var test = mock.parse( mockURL, columns );
        expect( test.error ).toBeTrue();
        expect( test.filter ).toBe( '' );
      } );

      it( 'can mitigate SQL injection 2>1', function () {
        var mockURL = { 'filter': '2 gt 1' };
        var test = mock.parse( mockURL, columns );
        expect( test.error ).toBeTrue();
        expect( test.filter ).toBe( '' );
      } );

    } );
  }
}