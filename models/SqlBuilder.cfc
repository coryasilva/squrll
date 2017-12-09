component {

  operatorMap = {
    'or': 'OR'
    ,'and': 'AND'
    ,'eq': '='
    ,'neq': '<>'
    ,'is': 'IS'
    ,'nis': 'IS NOT'
    ,'in': 'IN'
    ,'nin': 'NOT IN'
    ,'like': 'LIKE'
    ,'nlike': 'NOT LIKE'
    ,'lt': '<'
    ,'gt': '>'
    ,'lte': '<='
    ,'gte': '>='
  };

  public SqlBuilder function init() {
    return this;
  }

  public string function sqlize( tree ) {
    var sql = '';
    if ( tree.type == 'LogicalExpression' ) {
      return handleLogicalExpression( tree );
    }
    return '';
  }


  private struct function handleLogicalExpression( leaf ) {
    var sql = sql || ''
    if ( leaf.type == 'LogicalExpression' ) {

      if ( leaf.left.type == 'LogicalExpression' ) {
        sql &= handleLogicalExpression( leaf.left );
      }

      if ( leaf.left.type == 'BinaryExpression' ) {
        // TODO: Do not need leading space at top level.
        sql &= ' (';
        sql &= handleBinaryExpression( leaf.left );
      }

      if ( leaf.operator == 'and' ) {
        sql &= 'AND';
      }

      if ( leaf.operator == 'or' ) {
        sql &= 'OR';
      }

      if ( leaf.right.type == 'BinaryExpression' ) {
        sql &= handleBinaryExpression( leaf.right );
        if ( leaf.left.type == 'BinaryExpression'  && leaf.right.type == 'BinaryExpression' ) {
          // noop
        }
        else {
          // TODO: This is wrong if at the top level.
          // TODO: May not need trailing space.
          sql &= ') ';
        }
      }

      if ( leaf.right.type == 'LogicalExpression' ) {
        sql &= handleLogicalExpression( leaf.right );
      }

    }

    return sql;
  }

  private struct function handleBinaryExpression( leaf ) {
    var sql = '';
    if ( leaf.left.type == 'Identifier' ) {
      sql &= ' ' & leaf.left.name;
    }
    if ( leaf.operator && operatorMap[ leaf.operator ] ) {
      sql &= ' ' & operatorMap[leaf.operator] & ' ';
    }
    if ( leaf.right.type == 'Literal' ) {
      sql &= leaf.right.raw & ' ';
    }
    return sql;
  }

// TODO: Build Parameter Array
}