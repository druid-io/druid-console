$ = require 'jquery'
d3 = require '../../bower_components/d3/d3.js'
require '../../bower_components/zeroclipboard/ZeroClipboard.min.js'

require '../../bower_components/angular/angular.min.js'
require '../../bower_components/angular-ui-router/release/angular-ui-router.min.js'
require '../../bower_components/angular-sanitize/angular-sanitize.min.js'
require '../../bower_components/angular-local-storage/dist/angular-local-storage.min.js'
require '../../bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js'
require '../../bower_components/ng-clip/dest/ng-clip.min.js'
require '../../bower_components/ng-csv/build/ng-csv.min.js'

app = angular.module 'druid', [
  'ngClipboard'
  'ngCsv'
  'ui.bootstrap'
  'ui.router'
  'LocalStorageModule'
]

require('./factories')
require('./directives')
require('./controllers')
require('./filters')

app.config ($stateProvider, $urlRouterProvider) ->

  $stateProvider
    .state('cluster', {
      url: '/'
      templateUrl: '/pages/cluster.html'
      controller: 'ClusterCtrl'
    })
    .state('dataSources', {
      url: '/datasources'
      templateUrl: '/pages/data-sources.html'
      controller: 'DataSourcesCtrl'
    })
    .state('dataSource', {
      url: '/datasources/:id'
      templateUrl: '/pages/data-source.html'
      controller: 'DataSourceCtrl'
    })
    .state('tier', {
      url: '/tiers/:id'
      templateUrl: '/pages/tier.html'
      controller: 'TierCtrl'
    })
    .state('indexing-service', {
      url: '/indexing-service'
      templateUrl: '/pages/indexing-service.html'
      controller: 'IndexingServiceCtrl'
    })


  $urlRouterProvider.otherwise('/')

module.exports = app
