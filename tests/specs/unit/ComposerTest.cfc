component extends='tests.base' {

  function beforeAll() {
    // Create target mock object
    mock = prepareMock( createObject( 'component', 'models.Composer' ) );
    mockValidator = prepareMock( createObject( 'component', 'models.Validator' ) );
    mockValidator.init();

    mock.$property( 'settings', 'variables', mockSettings() );
    mock.$property( 'Validator', 'variables', mockValidator );
    mock.init();
  }

  function run() {

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
          mock.sort(
            ['state.asc', 'name', 'created_date.dsc.nullslast', 'blah.desc.nullsfirst' ]
           ,{ 'state':true, 'name':true, 'created_date':true, 'blah':true } ).sql
        ).toBe( ' ORDER BY state ASC, name ASC, created_date DESC NULLS LAST, blah DESC NULLS FIRST ' );
      } );
      it( 'can catch invalid direction', function () {
        expect( mock.sort( [ 'state.random' ], { 'state':true } ).error ).toBeTrue();
      } );
      it( 'can catch invalid modifier', function () {
        expect( mock.sort( [ 'state.asc.nullsmiddle' ], { 'state':true } ).error ).toBeTrue();
      } );
    } );

    describe( 'Composer Utils', function () {
      it( 'can create unique keys', function () {
        expect( mock.uniqueKey( 'blah', { 'blah': true } ) ).toBe( 'blah_1' );
        expect( mock.uniqueKey( 'blah', { 'blah': true, 'blah_1': true } ) ).toBe( 'blah_1_1' );
      } );
    } );

  }

}