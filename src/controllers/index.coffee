app = angular.module 'druid'

app.controller 'ClusterCtrl', require('./cluster.coffee')
app.controller 'DataSourceCtrl', require('./dataSource.coffee')
app.controller 'DataSourcesCtrl', require('./dataSources.coffee')
app.controller 'TierCtrl', require('./tier.coffee')
app.controller 'HistoricalNodeCtrl', require('./historicalNode.coffee')
app.controller 'DataSourceEnableCtrl', require('./dataSourceEnable.coffee')
app.controller 'DataSourceDisableCtrl', require('./dataSourceDisable.coffee')
app.controller 'RuleEditorCtrl', require('./ruleEditor.coffee')
app.controller 'ClusterConfigCtrl', require('./clusterConfig.coffee')
