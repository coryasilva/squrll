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