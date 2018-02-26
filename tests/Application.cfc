component {

  this.name = "ColdBoxTestingSuite" & hash(getCurrentTemplatePath());
  this.sessionManagement  = true;
  this.setClientCookies   = true;
  this.sessionTimeout     = createTimeSpan( 0, 0, 15, 0 );
  this.applicationTimeout = createTimeSpan( 0, 0, 15, 0 );

  testsPath = getDirectoryFromPath( getCurrentTemplatePath() );
  this.mappings[ "/tests" ] = testsPath;
  rootPath = REReplaceNoCase( this.mappings[ "/tests" ], "tests(\\|/)", "" );
  this.mappings[ "/root" ] = rootPath;
  this.mappings[ "/testingModuleRoot" ] = listDeleteAt( rootPath, listLen( rootPath, '\/' ), "\/" );
  this.mappings[ "/app" ] = testsPath & "resources/app";
  this.mappings[ "/coldbox" ] = testsPath & "resources/app/coldbox";
  this.mappings[ "/testbox" ] = rootPath & "/testbox";
  this.datasource = {
    class: 'org.postgresql.Driver'
  , bundleName: 'org.postgresql.jdbc42'
  , bundleVersion: '9.4.1212'
  , connectionString: 'jdbc:postgresql://localhost:5432/postgres'
  , username: 'postgres'
  , password: 'postgres'
  , blob: true
  , clob: true
  , connectionLimit: 3
  };
}
