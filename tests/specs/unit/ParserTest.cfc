component extends='tests.base' {

  function beforeAll() {
    // Create target mock object
    mock = prepareMock( createObject( 'component', 'models.Parser' ) );
    mock.init();
    mock.$property( 'settings', 'variables', mockSettings() );
  }
  function run() {

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