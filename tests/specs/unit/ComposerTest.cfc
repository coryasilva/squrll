component extends="testbox.system.BaseSpec" {

      function beforeAll() {
        // Create target mock object
        mock = prepareMock( createObject( 'component', 'models.Composer' ) );
        mock.init();
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

      }
    function run() {

      describe( 'Composer Filter', function () {

      } );

      describe( 'Composer Range', function () {
        it( 'can take a empty limit', function () {
          expect( mock.range( 10 ) ).toBe( ' LIMIT ALL OFFSET 10 ' );
        } );
        it( 'can limit and offset', function () {
          expect( mock.range( 10, 20 ) ).toBe( ' LIMIT 20 OFFSET 10 ' );
        } );
      } );

      describe( 'Composer Sort', function () {
        it( 'can sort by multiple columns', function () {
          expect(
            mock.sort( ['state.asc', 'name', 'created_date.dsc.nullslast', 'blah.desc.nullsfirst' ] ).sql
          ).toBe( ' ORDER BY state ASC, name ASC, created_date DESC NULLS LAST, blah DESC NULLS FIRST ' );
        } );
        it( 'can catch invalid direction', function () {
          expect( mock.sort( [ 'state.random' ] ).error ).toBeTrue();
        } );
        it( 'can catch invalid modifier', function () {
          expect( mock.sort( [ 'state.asc.nullsmiddle' ] ).error ).toBeTrue();
        } );
        it( 'can whiteList columns', function () {
          expect( mock.sort( [ 'state.asc' ], { 'state':true } ).error ).toBeFalse();
          expect( mock.sort( [ 'name.asc' ], { 'state':true } ).error ).toBeTrue();
        } );
          it( 'can blackList columns', function () {
          expect( mock.sort( [ 'state.asc' ], {}, { 'state':true } ).error ).toBeTrue();
          expect( mock.sort( [ 'name.asc' ], {}, { 'state':true } ).error ).toBeFalse();
        } );
        it( 'can let the whiteList previal', function () {
          expect( mock.sort( [ 'state.asc' ], { 'state':true }, { 'state':true } ).error ).toBeFalse();
        } );
      } );

    }
  }