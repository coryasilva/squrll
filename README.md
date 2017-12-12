# Squrll

_Squrll safely creates SQL clauses from a URL parameters_

[![Master Branch Build Status](https://img.shields.io/travis/coryasilva/urlsql/master.svg?style=flat-square&label=master)](https://travis-ci.org/coryasilva/urlsql)

## Usage

TODO: Expand on example and explain use case
_ex:_ `GET https://domain.tld/api/v1/resource?filter=&sort=&limit=&offset=`

## Module Configs

TODO:

- Param url params in module config
- exclude operators
- include operators
- identifier global blacklist (result in blah does not exist)
- identifier global whitelist

## Clauses

_SQL clauses are built from URL strings assigned to specific URL parameters._

| URL Param | SQL Clause | Example |
| --- | --- | --- |
| `filter` | `WHERE` | `?sort=` |
| `sort` | `ORDER BY` | `?filter=` |
| `limit` | `LIMIT` | `?limit=15` |
| `offset` | `OFFSET` | `?offset=30` |
| `count` | -NA- | `?count=true` |

## SQL Injection

Address SQL Injection Concerns

## Inspired By

TODO: add links

- oData
- postgrest
- pegjs

## TODO

TODO: columnWhiteList: {}
TODO: columnBlackList: {}

TODO: add open api parameter and return documentation
TODO: prepend all error messages with url param
TODO: Build Query Parameter struct for filter sql

TODO: operatorInclude: {}
TODO: operatorExclude: {}
TODO: Add LIKE ANY
TODO: Add NOT LIKE ANY
TODO: Add ILIKE ANY
TODO: Add NOT ILIKE ANY
TODO: Add ANY
TODO: Add NOT ANY
