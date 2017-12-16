component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

  function beforeAll() {
    super.beforeAll();
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

  }
}