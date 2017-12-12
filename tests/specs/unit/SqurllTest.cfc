component extends='coldbox.system.testing.BaseModelTest' model='models.Squrll' {

  function beforeAll() {
    // setup the model
    super.setup();
    // init the model object
    model.init();
  }

  function run() {
    describe( 'Squrll service', function () {
      it( 'can fail', function () {
        expect( function () { model.blah(); } ).toThrow();
      } );

    } );
  }
}