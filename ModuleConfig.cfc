component {

  this.name = "squrll";
  this.author = "Cory Silva";
  this.webUrl = "https://github.com/coryasilva/squrll";

  function configure() {
    settings = {
      countUrlParam: 'count'
      ,filterUrlParam: 'filter'
      ,sortUrlParam: 'sort'
      ,limitUrlParam: 'limit'
      ,offsetUrlParam: 'offset'
      ,defaultLimit: 20
      ,operatorInclude: {}
      ,operatorExclude: {}
      ,columnWhiteList: {}
      ,columnBlackList: {}
    };
  }
}