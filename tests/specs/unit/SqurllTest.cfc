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
      ,columnTypes:    {}
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
           'name':'cf_sql_varchar'
           ,'title': 'cf_sql_varchar'
           ,'active': 'cf_sql_boolean'
          }
        );
        expect( test.count ).toBe( ' COUNT(*) OVER() AS _count ' );
        expect( test.filter ).toBe( ' AND title LIKE :squrll_title AND active = :squrll_active ' );
        expect( test.queryParams ).toBe( {
          'squrll_title': { 'cfsqltype': 'cf_sql_varchar' }
          ,'squrll_active':  { 'cfsqltype': 'cf_sql_varchar' }
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
           'name':'cf_sql_varchar'
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

    } );
  }
}