component extends="testbox.system.BaseSpec" {

  function beforeAll() {
    var mockSettings = {
      countUrlParam:   'count'
      ,filterUrlParam: 'filter'
      ,sortUrlParam:   'sort'
      ,limitUrlParam:  'limit'
      ,offsetUrlParam: 'offset'
      ,filterPrepend:  'AND'
      ,sortPrepend:    'ORDER BY'
      ,defaultLimit:   20
      ,allowNoLimit:   false
      ,columnTypes:    { 'created_date': 'cf_sql_timestamp' }
    };
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

    describe( 'Squrll', function () {

      it( 'will not fail on empty struct', function () {
        var test =  mock.parse( {} );
        expect( test.error ).toBeFalse();
        expect( test.count ).toBe( '' );
        expect( test.filter ).toBe( '' );
        expect( test.sort ).toBe( '' );
        expect( test.range ).toBe( '' );
        expect( test.errorMessages ).toBeArray();
        expect( test.queryParams ).toBeStruct();
      } );

      it( 'can verify the example', function () {
        var mockURL = {
          'count': 'true'
          ,'filter':'title like "_Manager_" and active eq true'
          ,'sort': 'name.dsc.nullsfirst'
          ,'offset': '40'
          ,'limit': '20'
        };
        var test = mock.parse(
          mockURL
          ,{
           'name': 'cf_sql_varchar'
           ,'title': 'cf_sql_varchar'
           ,'active': 'cf_sql_boolean'
          }
        );
        expect( test.count ).toBe( ' COUNT(*) OVER() AS _count ' );
        expect( test.filter ).toBe( ' AND title LIKE :squrll_title AND active = :squrll_active ' );
        expect( test.queryParams ).toBe( {
          'squrll_title': { 'cfsqltype': 'cf_sql_varchar', 'value': '_Manager_' }
          ,'squrll_active':  { 'cfsqltype': 'cf_sql_varchar', 'value': 'true' }
        } );
        expect( test.sort ).toBe( ' ORDER BY name DESC NULLS FIRST ' );
        expect( test.range ).toBe( ' LIMIT 20 OFFSET 40 ' );
        expect( test.error ).toBeFalse();
      } );

      it( 'can parse a URL struct with extra data', function () {
        var mockURL = {
          'count': 'true'
          ,'filter':'name ilike "cory"'
          ,'sort': 'rank.desc,state.asc.nullsfirst'
          ,'offset': '40'
          ,'limit': '20'
          ,'extra': 'blah'
        };
        var test = mock.parse(
          mockURL
          ,{
           'name': 'cf_sql_varchar'
           ,'rank': 'cf_sql_integer'
           ,'state': 'cf_sql_varchar'
          }
        );
        expect( test.count ).toBe( ' COUNT(*) OVER() AS _count ' );
        expect( test.filter ).toBe( ' AND name ILIKE :squrll_name ' );
        expect( test.sort ).toBe( ' ORDER BY rank DESC, state ASC NULLS FIRST ' );
        expect( test.range ).toBe( ' LIMIT 20 OFFSET 40 ' );
        expect( test.error ).toBeFalse();
      } );

      it( 'can use global columnTypes', function () {
        var mockURL = {
          'filter': 'created_date gte "2014-06-01T00:00:00Z"'
          ,'sort': 'created_date.desc'
        };
        var test = mock.parse( mockURL, {} );
        expect( test.filter ).toBe( ' AND created_date >= :squrll_created_date ' );
        expect( test.sort ).toBe( ' ORDER BY created_date DESC ' );
        expect( test.error ).toBeFalse();
      } );

    } );

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
      var columns = { 'username': 'varchar' };
      /* Alternative Expression of 'or 1 = 1'
        'SQLi' = 'SQL'+'i'
        'SQLi' > 'S'
        20 > 1
        2 between 3 and 1
        'SQLi' = N'SQLi'
        1 and 1 = 1
        1 || 1 = 1
        1 && 1 = 1
      */
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

    } );
  }
}