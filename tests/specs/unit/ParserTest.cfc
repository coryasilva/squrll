component extends='coldbox.system.testing.BaseModelTest' model='models.Parser' {

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

      it( 'can parse', function () {
        //var expression = '(a gte .1 and (b neq 0 or c in "a,b,c" or d in "-1,2,3") or e like "_blah_") and f lt -5';
        //expression = '(a gte .3 and b lt 2) and c lt 1';
        var expression = 'a gte .3 and b lt 2';
        expect( model.parse( expression ) ).toBeStruct();
      } );

    } );
  }
}