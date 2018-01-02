# <img src="logo.png" height="48px" /> Squrll

_Squrll safely creates SQL clauses from URL parameters_

[![Master Branch Build Status](https://img.shields.io/travis/coryasilva/squrll/master.svg?style=flat-square&label=master)](https://travis-ci.org/coryasilva/squrll)

## Example

**Step 1: URL Input**: _(Not URL encoded for human readability)_

`GET https://domain.tld/api/v1/resource?filter=title like "_Manager_" and active eq true&sort=name.dsc.nullsfirst&limit=20&offset=40&count=true`

**Step 2: Squrll**:

```java
var columnTypes = {
  'title': 'cf_sql_varchar'
  ,'active': 'cf_sql_boolean'
  ,'name': 'varchar'
};
var result = Squrll.parse( URL, columnTypes );
// result equals
{
   'count': ' COUNT(*) OVER() AS _count '
  ,'filter': ' AND title LIKE :squrll_title AND active = :squrll_active '
  ,'queryParams': {
    'squrll_title': { 'cfsqltype': 'cf_sql_varchar', 'value': '_Manager_' }
    ,'squrll_active':  { 'cfsqltype': 'cf_sql_varchar', 'value': 'true' }
  }
  ,'sort': ' ORDER BY name DESC NULLS FIRST '
  ,'range': ' LIMIT 20 OFFSET 40 '
  ,'error': false
  ,'errorMessages': []
}
```

**Step 3: Build Your Query**

```java
function getStuff( tenantID, squrll ) {
  var sql = '
      SELECT id, name, value
      FROM stuff
      WHERE tenant_id = :tenantID
  ';
  sql &= squrll.filter;
  sql &= squrll.sort;
  sql &= squrll.range;

  var params = {
    tenantID: { value: arguments.tenantID, cfsqltype: 'cf_sql_integer' }
  };
  params.append( squrll.queryParams );

  return queryExecute( sql, params );
}
```

---

## Documentation

### Purpose

Instead of coding specific filter behaviors and sorting flags we can instead use a repeatable, configurable, and standard way to define filters, sorts, and paging.  This project is intended to work with legacy projects but could be used for new projects as well.

### SQL Dialects

_Currently this package only supports Postgres, pull requests welcome for other dialects_

### URL Parameters

_SQL clauses are built from URL strings assigned to specific URL parameters._

| URL Param | SQL Clause | Example | Method |
| --- | --- | --- | --- |
| filter | WHERE | `?sort=name.dsc.nullsfirst` | `Squrll.parseFilter()` |
| sort | ORDER BY | `?filter=title like "_Manager_"` | `Squrll.parseSort()` |
| limit | LIMIT | `?limit=15` | `Squrll.parseRange()` |
| offset | OFFSET | `?offset=30` | `Squrll.parseRange()` |
| count | -NA- | `?count=true` | `Squrll.parseCount()` |

*NOTE: The parameter names are configurable*

### Filtering

_The filter expression is comprised of Logical and Binary expressions with a familiar syntax to build SQL WHERE clauses._

_ex:_ `rank gte 90 and ( status in "active,disabled,inactive" or edge_case eg true )`

| URL Operators | SQL Operator | Expression Type |
| --- | --- | --- |
| or | OR | Logical |
| and | AND | Logical |
| eq | = | Binary |
| neq | <> | Binary |
| is | IS | Binary |
| nis | IS NOT | Binary |
| in | IN | Binary |
| nin | NOT IN | Binary |
| like | LIKE | Binary |
| nlike | NOT LIKE | Binary |
| ilike | ILIKE | Binary |
| nilike | NOT ILIKE | Binary |
| lt | < | Binary |
| gt | > | Binary |
| lte | <= | Binary |
| gte | >= | Binary |

#### Filter Notes

- Nested parenthesis/expressions are supported, _ex:_ ` a eq 1 and ( b gte 1 or c gte 1 )`
- Evaluated expressions are NOT allowed, _ex:_ `column1 eq column2 + 3`

### Sorting

_A comma separated list of column expressions._

_ex:_ `state.asc,name,created_date.dsc.nullslast`

**Column Expressions** are `.` delimited strings, the "Column Name" is required while the direction and modifier are optional.

| Column Name | Directions | Modifiers |
| --- | --- | --- |
| `[\w]+` | **asc**, desc, _dsc_  | nullsfirst, nullslast |

_NOTE: The default direction is_ `asc`_, and_ `dsc` _is an alias for_ `desc`.

### Paging

_Two URL parameters control the pagination._

- `?limit=20&offset=40` - Will return 20 rows offset by 40 rows
- `?offset=40` - Will return the `defaultLimit` offset by 40 rows or all rows if `allowNoLimit` is `true`
- `?limit=40` - Will return the first 40 rows

### Count

_Boolean URL param will allow the client to request the total count._

Currently this only builds a partial SQL column select statement but does not suggest how to format the response. Currently that is out of scope for this project.

### Module Configs

```java
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
};
```

### Column Types Struct

_Column types are passed into each filter and sort function call and inherit from the "Module Configs".  If there is a conflict the model configs win._

```java
// Example
columnTypes = {
  'name': 'cf_sql_varchar'
  ,'active': { 'type': 'cf_sql_varchar' }
};
```

Struct keys must be the column names while the values are either a `'cf_sql_type'` or a struct with the following allowed keys:

| Key | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `type` | _string_ | true | _none_ |  [see cfqueryparam](https://cfdocs.org/cfqueryparam) |
| `maxLenth` | _numeric_ | false | _none_ | [see cfqueryparam](https://cfdocs.org/cfqueryparam) |
| `scale` | _numeric_ | false | _none_ | Applies to `cf_sql_numeric` and `cf_sql_decimal` |
| `list` | _boolean_ | false | _none_ | |
| `separator` | _string_ | false | `','` |  Must be one of the following: `, ; | :` |

### Data Types

#### Numeric

_Numbers are validated by sql type bounds in hopes to help prevent database exceptions and instead inform the user with an error message.  See the ValidatorTests.cfc for examples._

#### Date/Time Formats

_A subset of the ISO 8601 standard has been employed. (TL'DR Dashes and colons are required)_

- `YYYY-MM-DD`
- `YYYY-MM-DDTHH:MM`
- `YYYY-MM-DDTHH:MM:SS`
- `YYYY-MM-DDTHH:MM:SS.SSS`
- `YYYY-MM-DDTHH:MMZ`
- `YYYY-MM-DDTHH:MMZ12`
- `YYYY-MM-DDTHH:MMZ+12`
- `YYYY-MM-DDTHH:MMZ-12`
- `YYYY-MM-DDTHH:MMZ12:30`

### SQL Injection

This package mitigates SQL injection by parsing the URL into an abstract syntax tree.  Each token is validated upon parsing and the strict language syntax inherently eliminates the threat for SQL injection.  The filter composer also creates `cfqueryparam`'s and qualifies each value against its `cfsqltype` to further limit the attack base.

Also a struct of columns, acting as a whitelist, is required for both filtering and sorting.  Each column must include a `cf_sql_type` in order for the filtering to work. (Sorting only requires that the column exists in the struct).

If you have any concerns that are not covered by the tests let's add them!

---

## Inspiration - stolen ideas and logic :)

- [**OData** _- Simplifying data sharing across disparate applications in enterprise, Cloud, and mobile devices_](http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part2-url-conventions.html)
- [**PostgREST** _- serve a restful API from any postgres database_](https://postgrest.com/en/v4.3/)
- [**jsep** _- tiny javascript expression parser_](http://jsep.from.so/)

---

## TODO

### High Priority

- Test order of operations
- Allow sets/arrays/lists
  - `LIKE ANY`
  - `NOT LIKE ANY`
  - `ILIKE ANY`
  - `NOT ILIKE ANY`
  - `ANY`
  - `NOT ANY`
  - `ALL`

### Low Priority

- Have Travis CI actually run some queries against postgres
- Consider allowing some operators to be disabled: `settings.disabledOperators: {}`
- Consider using cb-validator to further confine literals