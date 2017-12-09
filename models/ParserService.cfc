/**
 * @hint I build an abstract syntax tree form a string
 */
component accessors='false' {
  property string sqlDialect;

  // Constructor
  public ParserService function init( string dbType='psql' ) {
    variables.sqlDialect = dbType;
    return this;
  }

  public any function parseFilter( required string expression ) {

  }

  public any function parseRange( required string expression ) {

  }

  public any function parseSort( required string expression ) {

  }

  public any function parseCount( required string expression ) {

  }

  public string function getFilterSql( required string expression ) {

  }

  public string function getSortSql( required string expression ) {

  }

  public string function getRangeSql( required string expression ) {

  }

  public string function getCountSql( required string expression ) {

  }
}