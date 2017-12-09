component extends='coldbox.system.testing.BaseModelTest' model='models.parser' {

  function beforeAll() {
    // setup the model
    super.setup();
    // init the model object
    model.init();
  }

  function run() {
    describe( 'Parser', function () {
      it( 'can fail', function () {
        expect( function () { model.blah(); } ).toThrow();
      } );
    } );
  }
}