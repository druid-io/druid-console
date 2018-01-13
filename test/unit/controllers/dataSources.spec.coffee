dataSourcesController = require '../../../src/client/controllers/dataSources.coffee'

describe 'dataSourcesCtrl', () ->
  scope = undefined
  fakeEnv = undefined
  fakeCoordinator = undefined
  fakeCluster = undefined
  fakeDataSources = undefined
  fakeTierNames = undefined

  beforeEach inject ($controller, $rootScope, $q) ->
    fakeEnv = 'testEnv'
    fakeCluster =
      tiers: []
      dataExtents: {}
    fakeDataSources = []
    fakeRules = {}
    fakeTierNames = ['_default_tier', 'another_tier']

    scope = $rootScope.$new()

    historical =
      env: fakeEnv
      getNodes: ->
        then: (cb) -> cb fakeCluster
      getDataSources: ->
        then: (cb) -> cb fakeDataSources
      getLoadStatus: (d) =>
        deferred = $q.defer()
        deferred.resolve()
        return deferred.promise
      getAllRules: (d) =>
        deferred = $q.defer()
        deferred.resolve()
        return deferred.promise
      getTierNames: (d) ->
        then: (cb) -> cb fakeTierNames


    ctrl = $controller(dataSourcesController, {
      $scope: scope
      $historical: historical
      $q
    })

  it 'should set env', () ->
    expect(scope.env).toBe(fakeEnv)

  it 'should set dataSources', () ->
    expect(scope.dataSources).toBe(fakeDataSources)


  it 'should set tierNames', () ->
    expect(scope.tierNames).toBe(fakeTierNames)

