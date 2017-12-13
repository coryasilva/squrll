component extends="testbox.system.BaseSpec" {

  function beforeAll() {
    // Create target mock object
    mock = prepareMock( createObject( 'component', 'models.Squrll' ) );

    // Create mock settings
    var settings = {
      countUrlParam:       'count'
      ,filterUrlParam:     'filter'
      ,sortUrlParam:       'sort'
      ,limitUrlParam:      'limit'
      ,offsetUrlParam:     'offset'
      ,filterIncludeWhere: true
      ,sortIncludeOrderBy: true
      ,defaultLimit:       20
      ,allowNoLimit:       false
      ,columnWhiteList:    {}
      ,columnBlackList:    {}
    };
    mock.$property( 'settings', 'variables', settings );
    mock.init();
  }

  function run() {

    describe( 'Squrll', function () {
      var mockURL = {
        'count': 'true'
        ,'filter':'name ilike "cory"'
        ,'sort': 'rank.desc,state.asc.nullsfirst'
        ,'offset': '40'
        ,'limit': '20'
        ,'extra': 'blah'
      };
      it( 'can parse a URL struct', function () {
        var test = mock.parse( mockURL );
        expect( test.count ).toBe( ' COUNT(*) OVER() AS _count ' );
        expect( test.filter ).toBe( ' WHERE name ILIKE "cory" ' );
        expect( test.sort ).toBe( ' ORDER BY rank DESC, state ASC NULLS FIRST ' );
        expect( test.range ).toBe( ' LIMIT 20 OFFSET 40 ' );
        expect( test.error ).toBeFalse();
      } );

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
    } );

  }
}