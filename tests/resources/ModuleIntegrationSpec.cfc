component extends="coldbox.system.testing.BaseTestCase" {

  function beforeAll() {
    super.beforeAll();

    getController().getModuleService()
      .registerAndActivateModule( "squrll", "testingModuleRoot" );
  }

  /**
  * @beforeEach
  */
  function setupIntegrationTest() {
    setup();
  }

}
