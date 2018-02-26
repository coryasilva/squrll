component extends='testbox.system.BaseSpec' {

  /**
   * Returns some default settings
   */
  function mockSettings(){
    return {
      countUrlParam:   'count'
      ,filterUrlParam: 'filter'
      ,sortUrlParam:   'sort'
      ,limitUrlParam:  'limit'
      ,offsetUrlParam: 'offset'
      ,filterPrepend:  'AND'
      ,sortPrepend:    'ORDER BY'
      ,defaultLimit:   20
      ,allowNoLimit:   false
      ,columnTypes:    {}
      ,listSeparator:  '|'
    };
  }

  /**
   * This will return the actual sql from an intentionally erronous query.
   * `select * from fake_table where a > :a`
   *
   * @sql Sql string 
   * @params Struct of cfqueryparams
   */
  function getActualSql( sql, params ) {
    try {
      queryExecute( sql, params );
    }
    catch (any e ) {
      return e.sql
    }
  }
  
}