clusterController = require '../../../src/client/controllers/cluster.coffee'

describe 'ClusterCtrl', () ->
  scope = undefined
  fakeEnv = undefined
  fakeCoordinator = undefined
  fakeCluster = undefined
  fakeDataSources = undefined
  fakeTasks = undefined
  fakeWorkers = undefined
  fakeScaling = undefined

  beforeEach inject ($controller, $rootScope, $q) ->
    fakeEnv = 'testEnv'
    fakeCoordinator = 'testCoord'
    fakeCluster =
      tiers: []
    fakeDataSources = []
    fakeTasks = {
      running: []
      pending: []
      waiting: []
    }
    fakePendingTasks = []
    fakeWaitingTasks = []
    fakeWorkers = {
      workers:[]
      dataSources:[]
      slots:[]
    }
    fakeScaling = []

    scope = $rootScope.$new()

    historical =
      env: fakeEnv
      getNodes: ->
        then: (cb) -> cb fakeCluster
      getDataSources: ->
        then: (cb) -> cb fakeDataSources
      getLoadStatus: ->
        then: (cb) -> return
      getLoadQueue: ->
        then: (cb) -> return

    indexing =
      getAllTasks: ->
        then: (cb) -> cb fakeTasks
      getWorkers: ->
        then: (cb) -> cb fakeWorkers
      getScaling: ->
        then: (cb) -> cb fakeScaling

    ctrl = $controller(clusterController, {
      $scope: scope
      $historical: historical
      $indexing: indexing
      $q
    })

  it 'should set env', () ->
    expect(scope.env).toBe(fakeEnv)

  it 'should set tiers', () ->
    expect(scope.tiers).toBe(fakeCluster.tiers)

  it 'should set dataSources', () ->
    expect(scope.dataSources).toBe(fakeDataSources)

  it 'should set indexing tasks', () ->
    console.log 'test', scope.indexing
    expect(scope.indexing.tasks).toBe(fakeTasks)

  it 'should set indexing workers', () ->
    expect(scope.indexing.workers).toBe(fakeWorkers.workers)
    expect(scope.indexing.dataSources).toBe(fakeWorkers.dataSources)
    expect(scope.indexing.slots).toBe(fakeWorkers.slots)
