component extends='testbox.system.BaseSpec' {

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

  function getActualSql( sql, params ) {
    try {
      queryExecute( sql, params );
    }
    catch (any e ) {
      return e.sql
    }
  }
  
}