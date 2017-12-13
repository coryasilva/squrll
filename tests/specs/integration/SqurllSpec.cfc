component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

  //property name="squrll" inject="Squrll";

  function beforeAll() {
    super.beforeAll();
    //getWireBox().autowire( this );
  }

  function run() {
    describe( "Integration Spec", function() {
      it( "can run integration spec with the module activated", function() {
        expect( getController().getModuleService().isModuleRegistered( "squrll" ) ).toBeTrue();
        var event = execute( event = "Main.index", renderResults = true );
        expect( event.getPrivateCollection().welcomeMessage )
          .toBe( "Welcome to ColdBox!" );
      } );
    } );

    /*
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
        var test = squrll.parse( mockURL );
        expect( test.count ).toBe( ' COUNT(*) OVER() AS _count ' );
        expect( test.filter ).toBe( ' WHERE name ILIKE "cory" ' );
        expect( test.sort ).toBe( ' ORDER BY rank DESC, state ASC NULLS FIRST ' );
        expect( test.range ).toBe( ' LIMIT 20 OFFSET 40 ' );
        expect( test.error ).toBeFalse();
      } );
    } );
    */

  }
}