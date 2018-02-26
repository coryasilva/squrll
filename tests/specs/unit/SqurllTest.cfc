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

      it( 'will not fail on empty struct', function () {
        var test =  mock.parse( {} );
        expect( test.error ).toBeFalse();
        expect( test.count ).toBe( '' );
        expect( test.filter ).toBe( '' );
        expect( test.sort ).toBe( '' );
        expect( test.range ).toBe( '' );
        expect( test.errorMessages ).toBeArray();
        expect( test.queryParams ).toBeStruct();
      } );

      it( 'can verify the example', function () {
        var mockURL = {
          'count': 'true'
          ,'filter':'title like "_Manager_" and active eq true'
          ,'sort': 'name.dsc.nullsfirst'
          ,'offset': '40'
          ,'limit': '20'
        };
        var test = mock.parse(
          mockURL
          ,{
           'name': 'cf_sql_varchar'
           ,'title': 'cf_sql_varchar'
           ,'active': 'cf_sql_boolean'
          }
        );
        expect( test.count ).toBe( ' COUNT(*) OVER() AS _count ' );
        expect( test.filter ).toBe( ' AND title LIKE :squrll_title AND active = TRUE ' );
        expect( test.queryParams ).toBe( {
          'squrll_title': { 'cfsqltype': 'cf_sql_varchar', 'value': '_Manager_' }
        } );
        expect( test.sort ).toBe( ' ORDER BY name DESC NULLS FIRST ' );
        expect( test.range ).toBe( ' LIMIT 20 OFFSET 40 ' );
        expect( test.error ).toBeFalse();
      } );

      it( 'can parse a URL struct with extra data', function () {
        var mockURL = {
          'count': 'true'
          ,'filter':'name ilike "cory"'
          ,'sort': 'rank.desc,state.asc.nullsfirst'
          ,'offset': '40'
          ,'limit': '20'
          ,'extra': 'blah'
        };
        var test = mock.parse(
          mockURL
          ,{
           'name': 'cf_sql_varchar'
           ,'rank': 'cf_sql_integer'
           ,'state': 'cf_sql_varchar'
          }
        );
        expect( test.count ).toBe( ' COUNT(*) OVER() AS _count ' );
        expect( test.filter ).toBe( ' AND name ILIKE :squrll_name ' );
        expect( test.sort ).toBe( ' ORDER BY rank DESC, state ASC NULLS FIRST ' );
        expect( test.range ).toBe( ' LIMIT 20 OFFSET 40 ' );
        expect( test.error ).toBeFalse();
      } );

      it( 'can use global columnTypes', function () {
        var mockURL = {
          'filter': 'created_date gte "2014-06-01T00:00:00Z"'
          ,'sort': 'created_date.desc'
        };
        var test = mock.parse( mockURL, {} );
        expect( test.filter ).toBe( ' AND created_date >= :squrll_created_date ' );
        expect( test.sort ).toBe( ' ORDER BY created_date DESC ' );
        expect( test.error ).toBeFalse();
      } );

      it( 'can use columnType struct values', function () {
        var mockURL = { 'filter': 'active neq true' };
        var test = mock.parse( mockURL, { 'active': { 'cfsqltype': 'boolean' } } );
        expect( test.filter ).toBe( ' AND active <> TRUE ' );
        expect( test.error ).toBeFalse();
      } );

      it( 'can use name key from struct values', function () {
        var mockURL = { 'filter': 'active neq true' };
        var test = mock.parse( mockURL, { 'active': { 'cfsqltype': 'boolean', 'name': 'is_active' } } );
        expect( test.filter ).toBe( ' AND is_active <> TRUE ' );
        expect( test.error ).toBeFalse();
      } );

      it( 'can properly order `or` & `and`', function () {
        var mockURL = {
          'filter': 'a eq 1 and b eq 2 or c eq 3 and d eq 4 or e eq 5 or f eq 6'
        };
        var test = mock.parse( mockURL, { a: 'integer', b: 'integer', c: 'integer', d: 'integer', e: 'integer', f: 'integer' } );
        expect( test.filter ).toBe( ' AND ( ( ( a = :squrll_a AND b = :squrll_b ) OR ( c = :squrll_c AND d = :squrll_d ) ) OR e = :squrll_e ) OR f = :squrll_f ' );
        expect( test.error ).toBeFalse();
      } );

      it( 'can properly order `or` & `and` with nested parenthesis', function () {
        var mockURL = {
          'filter': 'a eq 1 and ( b eq 2 or ( c eq 3 and d eq 4 ) or e eq 5 ) or f eq 6'
        };
        var test = mock.parse( mockURL, { a: 'integer', b: 'integer', c: 'integer', d: 'integer', e: 'integer', f: 'integer' } );
        expect( test.filter ).toBe( ' AND ( a = :squrll_a AND ( ( b = :squrll_b OR ( c = :squrll_c AND d = :squrll_d ) ) OR e = :squrll_e ) ) OR f = :squrll_f ' );
        expect( test.error ).toBeFalse();
      } );

      it( 'can handle IS [NOT] NULL', function () {
        var mockURL = { 'filter': 'a is null and b nis null' };
        var test = mock.parse( mockURL, { a: 'integer', b: 'integer' } );
        expect( test.filter ).toBe( ' AND a IS :squrll_a AND b IS NOT :squrll_b ' );
        expect( test.queryParams ).toBe( { 'squrll_a': { 'cfsqltype': 'integer', 'null': true }, 'squrll_b': { 'cfsqltype': 'integer', 'null': true } } );
      } );
      
      it( 'can handle IS [NOT] TRUE', function () {
        var mockURL = { 'filter': 'a is true and b nis false' };
        var test = mock.parse( mockURL, { a: 'boolean', b: 'boolean' } );
        expect( test.filter ).toBe( ' AND a IS TRUE AND b IS NOT FALSE ' );
      } );

    } );

    describe( 'Squrll Live Postgres', function () {

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
        } );
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