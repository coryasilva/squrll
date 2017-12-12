# Squrll

_Squrll safely creates SQL clauses from a URL parameters_

[![Master Branch Build Status](https://img.shields.io/travis/coryasilva/squrrl/master.svg?style=flat-square&label=master)](https://travis-ci.org/coryasilva/squrrl)

Instead of coding specific filter behaviors and sorting flags we can instead use a repeatable, configurable, and standard way to define filters, sorts, and paging.  This project was originally intended to work with legacy projects but could be used for new projects as well.

**CURRENTLY BUILT FOR POSTGRES** _(though, easily extendable)_

## Example

**URL Input**: _(Not URL encoded for human readibility)_

`GET https://domain.tld/api/v1/resource?filter=title like "_Manager_" and active eq true&sort=name.dsc.nullsfirst&limit=20&offset=40&count=true`

**Squrll Output**:

```java
Squrll.parse( URL );
{
   'count |  COUNT(*) OVER() AS _count '
  ,'filter |  WHERE (title LIKE "_Manager_" AND active = TRUE) '
  ,'sort |  ORDER BY name DESC NULLS FIRST '
  ,'range |  LIMIT 20 OFFSET 40 '
  ,'error': false
  ,'errorMessages': []
}
```

## URL Parameters

_SQL clauses are built from URL strings assigned to specific URL parameters._

| URL Param | SQL Clause | Example | Method |
| --- | --- | --- | --- |
| filter | WHERE | `?sort=name.dsc.nullsfirst` | `Squrll.parseFilter()` |
| sort | ORDER BY | `?filter=title like "_Manager_"` | `Squrll.parseSort()` |
| limit | LIMIT | `?limit=15` | `Squrll.parseRange()` |
| offset | OFFSET | `?offset=30` | `Squrll.parseRange()` |
| count | -NA- | `?count=true` | `Squrll.parseCount()` |

*NOTE: The parameter names are configurable*

## Sorting

_A comma seperated list of column expressions._

_ex:_ `state.asc,name,created_date.dsc.nullslast`

**Column Expressions**

Column expressions are `.` delimited strings, the "Column Name" is required while the direction and modifier is optional.

| Column Name | Directions | Modifiers |
| --- | --- | --- |
| `[\w]+` | asc,dsc,desc | nullsfirst, nullslast |

*NOTE: The default direction is* `asc`

## Filtering

_The filter expression is comprised of Logical and Binary expressions with a familar syntax to build SQL WHERE clauses._

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

*NOTE: Supports nested paranthesis/expressions*

## Module Configs

```java
settings = {
  countUrlParam:       'count'  // Name of the URL parameter
  ,filterUrlParam:     'filter' // Name of the URL parameter
  ,sortUrlParam:       'sort'   // Name of the URL parameter
  ,limitUrlParam:      'limit'  // Name of the URL parameter
  ,offsetUrlParam:     'offset' // Name of the URL parameter
  ,filterIncludeWhere: true     // Include `WHERE` in the filter sql clause
  ,sortIncludeOrderBy: true     // Include `ORDER BY` in the sort sql clause
  ,defaultLimit:       20       // Default record limit when not defined, ignored if allowNoLimit is true
  ,allowNoLimit:       false    // Allow unlimited rows to be returned
  ,columnWhiteList:    {}       // Only allow these columns on all requests
  ,columnBlackList:    {}       // Do not allow these columns on all requests
};
```

## SQL Injection

This package mitigates SQL injection by parsing the URL into an abstract syntax tree.  Each token is validated upon parsing and the strict language syntax inherently eliminates the threat for SQL injection.  The filter composer also creates `cfqueryparam`'s to further limit the attack base.

Other options like "Column White/Black Lists" further secure the SQL that is generated.

If you have any concerns that are not covered by the tests let's add them!

## Inspired By

- [**OData** _- Simplifying data sharing across disparate applications in enterprise, Cloud, and mobile devices_](http://docs.oasis-open.org/odata/odata/v4.0/odata-v4.0-part2-url-conventions.html)
- [**PostgREST** _- serve a restful API from any postgres database_](https://postgrest.com/en/v4.3/)
- [**jsep** _- tiny javascript expression parser_](http://jsep.from.so/)

## TODO

**High Priority**
- columnWhiteList: {}
- columnBlackList: {}
- Build Query Parameter struct for filter sql
- Standardize date format
  - DateValue eq 2012-12-03
  - DateTimeOffsetValue eq 2012-12-03T07:16:23Z
- verfiy example output

**Low Priority**
- Add LIKE ANY
- Add NOT LIKE ANY
- Add ILIKE ANY
- Add NOT ILIKE ANY
- Add ANY
- Add NOT ANY
- add open api parameter and return documentation
- operatorInclude: {}
- operatorExclude: {}