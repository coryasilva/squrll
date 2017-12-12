component extends='coldbox.system.testing.BaseModelTest' model='models.Composer' {

  function beforeAll() {
    // setup the model
    super.setup();
    // init the model object
    model.init();
  }

  function run() {
    describe( 'Composer', function () {
      it( 'can fail', function () {
        expect( function () { model.blah(); } ).toThrow();
      } );

    } );
  }
}