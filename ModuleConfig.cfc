component {

  this.name = "squrll";
  this.author = "Cory Silva";
  this.webUrl = "https://github.com/coryasilva/squrll";

  function configure() {
    settings = {
      countUrlParam:   'count'    // Name of the URL parameter
      ,filterUrlParam: 'filter'   // Name of the URL parameter
      ,sortUrlParam:   'sort'     // Name of the URL parameter
      ,limitUrlParam:  'limit'    // Name of the URL parameter
      ,offsetUrlParam: 'offset'   // Name of the URL parameter
      ,filterPrepend:  'AND'      // Include `AND` or `WHERE` in the filter sql clause
      ,sortPrepend:    'ORDER BY' // Include `ORDER BY` in the sort sql clause
      ,defaultLimit:   20         // Default record limit when not defined, ignored if allowNoLimit is true
      ,allowNoLimit:   false      // Allow unlimited rows to be returned
      ,columnTypes:    {}         // Allow and type these columns on all requests `{ columnName: 'cf_sql_type' }`
      ,listSeparator:  '|'        // Default list separator
    };
  }
}