component {

  variables.operators = {
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
    ,'ilike': 'ILIKE'
    ,'nilike': 'NOT ILIKE'
    ,'lt': '<'
    ,'gt': '>'
    ,'lte': '<='
    ,'gte': '>='
  };

  public Composer function init() {
    return this;
  }

  public string function compose( required struct tree ) {
    if ( tree.type == 'LogicalExpression' ) {
      return ' WHERE ' & handleLogicalExpression( tree );
    }
    if ( tree.type == 'BinaryExpression' ) {
      return ' WHERE ' & handleBinaryExpression( tree );
    }
    return '';
  }

  private string function handleLogicalExpression( leaf ) {
    var sql = '';

    if ( leaf.type == 'LogicalExpression' ) {

      if ( leaf.left.type == 'LogicalExpression' ) {
        sql &= '( ' & handleLogicalExpression( leaf.left ) & ') ';
      }

      if ( leaf.left.type == 'BinaryExpression' ) {
        sql &= handleBinaryExpression( leaf.left );
      }

      if ( leaf.operator == 'and' ) {
        sql &= 'AND ';
      }

      if ( leaf.operator == 'or' ) {
        sql &= 'OR ';
      }

      if ( leaf.right.type == 'BinaryExpression' ) {
        sql &= handleBinaryExpression( leaf.right );
      }

      if ( leaf.right.type == 'LogicalExpression' ) {
        sql &= '( ' & handleLogicalExpression( leaf.right ) & ') ';
      }

    }

    return sql;
  }

  private string function handleBinaryExpression( leaf ) {
    var sql = '';
    if ( leaf.left.type == 'Identifier' ) {
      sql &= leaf.left.name & ' ';
    }
    if ( leaf.keyExists( 'operator' ) && variables.operators.keyExists( leaf.operator ) ) {
      sql &= variables.operators[leaf.operator] & ' ';
    }
    if ( leaf.right.type == 'Literal' ) {
      sql &= leaf.right.raw & ' ';
    }
    return sql;
  }

// TODO: Build Parameter Array
}