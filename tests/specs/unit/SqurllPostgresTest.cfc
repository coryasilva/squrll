component extends='tests.base' {

  function beforeAll() {
    var mockSettings = mockSettings();
    mockSettings.columnTypes = { 'created_date': 'cf_sql_timestamp' };
    
    // Create target mock object
    mockValidator = prepareMock( createObject( 'component', 'models.Validator' ) );
    mockValidator.init();

    mockComposer = prepareMock( createObject( 'component', 'models.Composer' ) );
    mockComposer.$property( 'settings', 'variables', mockSettings );
    mockComposer.$property( 'Validator', 'variables', mockValidator );
    mockComposer.init();

    mockParser = prepareMock( createObject( 'component', 'models.Parser' ) );
    mockParser.$property( 'settings', 'variables', mockSettings );

    mockWirebox = createStub().$( 'getInstance', mockParser.init() );

    mock = prepareMock( createObject( 'component', 'models.Squrll' ) );
    mock.$property( 'settings', 'variables', mockSettings );
    mock.$property( 'wirebox', 'variables', mockWirebox );
    mock.$property( 'Composer', 'variables', mockComposer );

    mock.init();
  }

  function run() {

    describe( 'Squrll', function () {

      it( 'can work with a real world example', function () {
        // Model
        var documentSchema = {
          'title': 'cf_sql_varchar'
          ,'likes': 'cf_sql_bigint'
          ,'category': { cfsqltype: 'cf_sql_varchar', name: 'category_display_name' }
         };

        // Controller
        var mockURL = {
          'count': 'true'
          ,'filter': 'likes gt 1 and title ilike "Xer%"'
          ,'sort': 'category.desc'
        };
        var squrll = mock.parse( mockURL, documentSchema );

        // Service
        var sql = 'SELECT * ';
        sql &= len(squrll.count) > 0 ? ', #squrll.count#' : '';
        sql &= 'FROM enduser_document WHERE tenant_id = :tenant_id';
        sql &= squrll.filter;
        sql &= squrll.sort;
        sql &= squrll.range;
  
        var queryParams = { tenant_id: { cfsqltype: 'bigint', value: 1 } };
        queryParams.append(squrll.queryParams);

        var result = queryExecute(sql, queryParams);

        result.each( function( row ) {
          expect( row.likes > 1 ).toBeTrue();
          expect( findNoCase( 'Xer', row.title ) > 0 ).toBeTrue();
          expect( row.keyExists( '_count' ) ).toBeTrue();
        } )
      } );
      
      /*
      it( 'ACTUAL SQL TEST', function () {
        var sql = getActualSql(
          'select * from fake_table where a IN (:a)'
          ,{
            a: {value: '1,a|2|3|4', list:true, separator:'|', cfsqltype:'varchar'}
          }
        )
        writeDump(sql);
      } );
      */

    } );

  }
}