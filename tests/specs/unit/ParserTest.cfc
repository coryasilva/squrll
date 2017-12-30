component extends="testbox.system.BaseSpec" {

  function beforeAll() {
    // Create target mock object
    mock = prepareMock( createObject( 'component', 'models.Parser' ) );
    mock.init();
    // Create mock settings
    var settings = {
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
    mock.$property( 'settings', 'variables', settings );

  }
  function run() {
    //expression = '(a gte .1 and (b neq 0 or c in "a,b,c" or d in "-1,2,3") or e like "_blah_") and f lt -5';
    //expression = '(a gte .3 and b lt 2) and c lt 1';

    describe( 'Parser Error Handling', function () {

      it( 'can error on invalid operators', function () {
        var test = mock.parse( 'a gtew .3 and b lt 2' );
        expect( test.error ).toBeTrue();
      } );

      it( 'can error on variable names that start with number', function () {
        var test = mock.parse( '1a gte 1' );
        expect( test.error ).toBeTrue();
      } );

      it( 'can error on empty expression', function () {
        var test = mock.parse( '' );
        expect( test.error ).toBeTrue();
      } );

    } );
  }
}