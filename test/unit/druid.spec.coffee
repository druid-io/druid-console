'use strict'

beforeEach module 'druid'

describe '$utils', () ->
  $utils = undefined

  beforeEach inject (_$utils_) ->
    $utils = _$utils_

  it 'should have a defined $utils', () ->
    expect($utils?).toBeTruthy()

  describe 'processServers', () ->
    it 'should break the list of servers into tiers and calculate tier summaries', () ->
      fakeServersSimple = [
        {
          host: "10.148.210.133:8081"
          tier: "_default_tier"
          type: "realtime"
          currSize: 0
          maxSize: 0
        }
        {
          host: "10.218.142.162:8080"
          tier: "hot"
          type: "historical"
          currSize: 84870943992
          maxSize: 1550000000000
        }
        {
          host: "10.218.142.164:8080"
          tier: "hot"
          type: "historical"
          currSize: 84612949688
          maxSize: 1550000000000
        }
        {
          host: "10.71.140.235:8080"
          tier: "_default_tier"
          type: "historical"
          currSize: 700461427524
          maxSize: 1550000000000
        }
      ]
      expected = {
        indexer: []
        realtime: [
          {
            id: "10.148.210.133:8081"
            host: "10.148.210.133:8081"
            hostname: "10.148.210.133"
            port: "8081"
            tier: "_default_tier"
            type: "realtime"
            currSize: 0
            maxSize: 0
          }
        ]
        tiers: [
          {
            tier: "hot"
            nodes: [
              {
                host: "10.218.142.162:8080"
                tier: "hot"
                type: "historical"
                currSize: 84870943992
                maxSize: 1550000000000
                id: "10.218.142.162:8080"
                hostname: "10.218.142.162"
                port: "8080"
                utilization: 84870943992 / 1550000000000
              }
              {
                host: "10.218.142.164:8080"
                tier: "hot"
                type: "historical"
                currSize: 84612949688
                maxSize: 1550000000000
                id: "10.218.142.164:8080"
                hostname: "10.218.142.164"
                port: "8080"
                utilization: 84612949688 / 1550000000000
              }
            ]
            maxSize: 3100000000000
            currSize: 169483893680
            utilization: 169483893680 / 3100000000000
            resilience: 1
          }
          {
            tier: "_default_tier"
            nodes: [
              {
                host: "10.71.140.235:8080"
                tier: "_default_tier"
                type: "historical"
                currSize: 700461427524
                maxSize: 1550000000000
                id: "10.71.140.235:8080"
                hostname: "10.71.140.235"
                port: "8080"
                utilization: 0.45191059840258063
              }
            ]

            maxSize: 1550000000000
            currSize: 700461427524
            utilization: 0.45191059840258063
            resilience: 0
          }
        ]
      }
      computed = $utils.processServers(fakeServersSimple)
      expect(computed).toEqual(expected)

      diff = DeepDiff(computed, expected)
      console.log JSON.stringify(diff) if diff?

  describe 'processServerTiers', () ->
    it 'should break the list of servers into tiers and calculate tier summaries', () ->
      fakeServersSimple = [
        {
          host: "1.2.3.4:5678"
          tier: "_default_tier"
          currSize: 1234
          maxSize: 12345
        }
        {
          host: "2.3.4.5:6789"
          tier: "hot"
          currSize: 987
          maxSize: 9876
        }
      ]
      expected = {
        "1.2.3.4:5678": {
          host: "1.2.3.4:5678"
          hostname: "1.2.3.4"
          port: "5678"
          tier: "_default_tier"
          currSize: 1234
          maxSize: 12345
        }
        "2.3.4.5:6789": {
          host: "2.3.4.5:6789"
          hostname: "2.3.4.5"
          port: "6789"
          tier: "hot"
          currSize: 987
          maxSize: 9876
        }

      }
      computed = $utils.processServerTiers(fakeServersSimple)
      expect(computed).toEqual(expected)

      diff = DeepDiff(computed, expected)
      console.log JSON.stringify(diff) if diff?

  describe 'processDataSources', () ->
    it 'should turn the array of datasources into an array of objects', () ->
      fakeDatasources = ["mmx_metrics","oculus"]
      expected = [{id: "mmx_metrics"}, {id: "oculus"}]
      computed = $utils.processDataSources(fakeDatasources)
      expect(computed).toEqual(expected)

  describe 'processLoadStatus', () ->
    it 'should assign loadstatus to the correct datasources', () ->
      fakeLoadStatuses = {oculus:88.0, mmx_metrics:100.0}
      dataSources = [{id: "mmx_metrics"}, {id: "oculus"}]
      expected = [
        {id: "mmx_metrics", loadStatus: 100.0}
        {id: "oculus", loadStatus: 88.0}
      ]
      computed = $utils.processLoadStatus(fakeLoadStatuses, dataSources)
      expect(computed).toEqual(expected)

      diff = DeepDiff(computed, expected)
      console.log JSON.stringify(diff) if diff?

  describe 'processLoadQueue', () ->
    it 'should assign the load queue to the correct nodes', () ->
      fakeLoadQueue =
        "1.2.3.4:5678":
          segmentsToLoad: 1
          segmentsToDrop: 2
          segmentsToLoadSize: 3
          segmentsToDropSize: 4
        "2.3.4.5:6789":
          segmentsToLoad: 4
          segmentsToDrop: 3
          segmentsToLoadSize: 2
          segmentsToDropSize: 1
        "8.7.6.5:4321":
          segmentsToLoad: 8
          segmentsToDrop: 7
          segmentsToLoadSize: 6
          segmentsToDropSize: 5
      tiers = [
        nodes: [
          host: "1.2.3.4:5678"
        ,
          host: "2.3.4.5:6789"
        ]
      ,
        nodes: [
          host: "8.7.6.5:4321"
        ]
      ]
      expected = [
        segmentsToLoad: 5
        segmentsToDrop: 5
        segmentsToLoadSize: 5
        segmentsToDropSize: 5
        nodes: [
          host: "1.2.3.4:5678"
          segmentsToLoad: 1
          segmentsToDrop: 2
          segmentsToLoadSize: 3
          segmentsToDropSize: 4
        ,
          host: "2.3.4.5:6789"
          segmentsToLoad: 4
          segmentsToDrop: 3
          segmentsToLoadSize: 2
          segmentsToDropSize: 1
        ]
      ,
        segmentsToLoad: 8
        segmentsToDrop: 7
        segmentsToLoadSize: 6
        segmentsToDropSize: 5
        nodes: [
          host: "8.7.6.5:4321"
          segmentsToLoad: 8
          segmentsToDrop: 7
          segmentsToLoadSize: 6
          segmentsToDropSize: 5
        ]
      ]

      computed = $utils.processLoadQueue(fakeLoadQueue, tiers)
      expect(computed).toEqual(expected)

      diff = DeepDiff(computed, expected)
      console.log JSON.stringify(diff) if diff?

  describe 'processRulesAll', () ->
    it 'should assign explicit and default rules to the correct datasources', () ->
      fakeRules =
        _default: [
          tieredReplicants:
            _default_tier: 2
          type: "loadForever"
        ]
        mmx_metrics: [
          period: "P1M"
          tieredReplicants:
            hot: 1
            _default_tier: 1
          type: "loadByPeriod"
        ]
      dataSources = [{id: "mmx_metrics"}, {id: "oculus"}]
      expected = [
        id: "mmx_metrics"
        rules: [
          period: "P1M"
          tieredReplicants:
            hot: 1
            _default_tier: 1
          type: "loadByPeriod"
          timeType: "ByPeriod"
          default: false
          direction: 'load'
          # momentInterval: moment.interval(fakeRules.mmx_metrics[0].period + '/')
        ]
      ,
        id: "oculus"
        rules: [
        ]
      ]

      computed = $utils.processAllRules(fakeRules, dataSources)
      computedMoment = computed[0].rules[0].momentInterval

      expect(computedMoment.period().toISOString())
        .toEqual(fakeRules.mmx_metrics[0].period)
      delete computed[0].rules[0].momentInterval
      expect(computed).toEqual(expected)

      diff = DeepDiff(computed, expected)
      console.log JSON.stringify(diff) if diff?

  describe 'resilience', () ->
    it 'should calculate resilience properly', () ->
      tier =
        currSize: 80
        nodes: [{maxSize: 10}, 0, 0, 0, 0, 0, 0, 0, 0, 0] # 10 nodes

      expect($utils.resilience(tier)).toEqual(2)
      tier.currSize = 80.1
      expect($utils.resilience(tier)).toEqual(1)
      tier.currSize = 89.9
      expect($utils.resilience(tier)).toEqual(1)
      tier.currSize = 90.1
      expect($utils.resilience(tier)).toEqual(0)
      tier.currSize = 1
      expect($utils.resilience(tier)).toEqual(9)

  describe 'processDataSourceIntervals', () ->
    it 'should turn the object of intervals into a sorted list', () ->
      fakeIntervals =
        "2014-04-15T23:00:00.000Z/2014-04-16T00:00:00.000Z":
          count: 3
          size: 222
        "2014-01-31T22:00:00.000Z/2014-02-12T19:00:00.000Z":
          count: 1
          size: 123
        "2014-03-12T15:00:00.000Z/2014-04-16T18:00:00.000Z":
          count: 2
          size: 321

      expected =
        intervals: [
          interval: "2014-04-15T23:00:00.000Z/2014-04-16T00:00:00.000Z"
          count: 3
          size: 222
        ,
          interval: "2014-03-12T15:00:00.000Z/2014-04-16T18:00:00.000Z"
          count: 2
          size: 321
        ,
          interval: "2014-01-31T22:00:00.000Z/2014-02-12T19:00:00.000Z"
          count: 1
          size: 123
        ]
        days: [
          day: "2014-04-15"
          interval: "2014-04-15T23:00:00.000Z/2014-04-16T00:00:00.000Z"
          count: 3
          size: 222
          startDate: new Date("2014-04-15T23:00:00.000Z")
          endDate: new Date("2014-04-16T00:00:00.000Z")
        ,
          day: "2014-03-12"
          interval: "2014-03-12T15:00:00.000Z/2014-04-16T18:00:00.000Z"
          count: 2
          size: 321
          startDate: new Date("2014-03-12T15:00:00.000Z")
          endDate: new Date("2014-04-16T18:00:00.000Z")
        ,
          day: "2014-01-31"
          interval: "2014-01-31T22:00:00.000Z/2014-02-12T19:00:00.000Z"
          count: 1
          size: 123
          startDate: new Date("2014-01-31T22:00:00.000Z")
          endDate: new Date("2014-02-12T19:00:00.000Z")
        ]
        summary:
          count: 6
          size: 666
          # interval:
      expectedInterval = "2014-01-31T22:00:00.000Z/2014-04-16T00:00:00.000Z"

      computed = $utils.processDataSourceIntervals(fakeIntervals)

      computedInterval = computed.summary.interval
      expect(computedInterval.start().toISOString() +
        '/' + computedInterval.end().toISOString())
        .toEqual(expectedInterval)
      delete computed.summary.interval

      expect(computed).toEqual(expected)

      diff = DeepDiff(computed, expected)
      console.log JSON.stringify(diff) if diff?

  describe "processSegmentsForInterval", () ->
    it "should combine the segments' servers and metadata", () ->
      fakeSegments =
        interval:
          ab:
            servers: ["a", "b"]
            metadata:
              key: "value"
          cd:
            servers: [ "c", "d"]
            metadata:
              key: "another value"
      expected =
        ab:
          servers: fakeSegments.interval.ab.servers
          key: "value"
        cd:
          servers: fakeSegments.interval.cd.servers
          key: "another value"

      computed = $utils.processSegmentsForInterval(fakeSegments)
      expect(computed).toEqual(expected)

      diff = DeepDiff(computed, expected)
      console.log JSON.stringify(diff) if diff?

  describe 'processSegmentsAll', () ->
    it 'should parse the nodes and give us everything (for now)', () ->
      expect(true).toBeTruthy()

describe 'DruidClusterCtrl', () ->
  scope = undefined
  env = undefined
  routeParams = undefined
  fakeCoordinator = undefined
  fakeCluster = undefined
  fakeDataSources = undefined

  beforeEach inject ($controller, $rootScope) ->
    fakeCoordinator = ''
    fakeCluster =
      tiers: []
    fakeDataSources = []

    scope = $rootScope.$new()

    druid =
      getCoordinator: ->
        then: (cb) -> cb fakeCoordinator
      getNodes: ->
        then: (cb) -> cb fakeCluster
      getDataSources: ->
        then: (cb) -> cb fakeDataSources
      getLoadStatus: ->
        then: (cb) -> return
      getLoadQueue: ->
        then: (cb) -> return

    routeParams = {env: 'test'}

    ctrl = $controller('DruidClusterCtrl', {
      $scope: scope
      $druid: druid
      $routeParams: routeParams
    })

  it 'should set env', () ->
    expect(scope.env).toBe(routeParams.env)

  it 'should set coordinator', () ->
    expect(scope.coordinator).toBe(fakeCoordinator)

  it 'should set tiers', () ->
    expect(scope.tiers).toBe(fakeCluster.tiers)

  it 'should set dataSources', () ->
    expect(scope.dataSources).toBe(fakeDataSources)

describe 'DruidDataSourcesCtrl', () ->
  scope = undefined
  env = undefined
  routeParams = undefined
  fakeCoordinator = undefined
  fakeCluster = undefined
  fakeDataSources = undefined

  beforeEach inject ($controller, $rootScope, $q) ->
    fakeCoordinator = ''
    fakeCluster =
      tiers: []
      dataExtents: {}
    fakeDataSources = []
    fakeRules = {}

    scope = $rootScope.$new()

    druid =
      getCoordinator: ->
        then: (cb) -> cb fakeCoordinator
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
      getSegmentsAll: (d) ->
        then: (cb) -> cb fakeCluster

    routeParams = {env: 'test'}

    ctrl = $controller('DruidDataSourcesCtrl', {
      $scope: scope
      $druid: druid
      $routeParams: routeParams
      $q
    })

  it 'should set env', () ->
    expect(scope.env).toBe(routeParams.env)

  it 'should set coordinator', () ->
    expect(scope.coordinator).toBe(fakeCoordinator)

  it 'should set dataSources', () ->
    expect(scope.dataSources).toBe(fakeDataSources)


  # it 'should set dataExtents', () ->
  #   expect(scope.dataExtents).toBe(fakeCluster.dataExtents)


describe 'DruidDataSourceCtrl', () ->
  $httpBackend = undefined
  $rootScope = undefined
  createController = undefined

  scope = undefined
  env = undefined
  routeParams = { env: 'testEnv', dataSource: 'testDataSource'}
  fakeCoordinator = undefined
  fakeDataSource = undefined
  fakeDataSources = undefined
  fakeIntervals = undefined
  fakeTierNames = undefined
  fakeRules = undefined

  beforeEach inject ($injector, $druid) ->
    routeParams =
      env: 'testEnv'
      dataSource: 'testDataSource'

    fakeCoordinator = {host:'123', port:456}
    fakeDataSources = []
    fakeDataSource = {tiers: {}, segments: {}}
    fakeIntervals = {
      intervals: {}
      days: {}
      dataSummary: {}
    }
    fakeTierNames = ['a', 'b']
    fakeRules = []

    $druid.env = routeParams.env

    $httpBackend = $injector.get '$httpBackend'

    $httpBackend.whenGET(/^\/coordinator/)
      .respond(fakeCoordinator)

    $httpBackend.whenGET($druid.proxy "/datasources/#{routeParams.dataSource}")
      .respond(fakeDataSource)

    $httpBackend.whenGET($druid.proxy "/datasources/#{routeParams.dataSource}/intervals?simple")
      .respond(fakeIntervals)

    $httpBackend.whenGET($druid.proxy "/rules/#{routeParams.dataSource}")
      .respond(fakeRules)

    $httpBackend.whenGET($druid.proxy "/datasources/#{routeParams.dataSource}")
      .respond(fakeRules)

    $httpBackend.whenGET($druid.proxy "/tiers")
      .respond(fakeTierNames)

    delete $druid.env
    $controller = $injector.get '$controller'
    $rootScope = $injector.get '$rootScope'

    createController = () ->
      $controller 'DruidDataSourceCtrl', {
        '$scope': $rootScope
        $druid: $injector.get '$druid'
        $routeParams: routeParams
        $q: $injector.get '$q'
      }

  afterEach () ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  it 'should set env', () ->
    controller = createController()
    $httpBackend.flush();
    expect($rootScope.env).toBe(routeParams.env)

  it 'should set coordinator', () ->
    controller = createController()
    $httpBackend.flush()
    expect($rootScope.coordinator).toBe('123:456')

  it 'should set tierNames', () ->
    controller = createController()
    $httpBackend.flush()
    expect($rootScope.tierNames).toEqual(fakeTierNames)

  it 'should extend dataSource', () ->
    controller = createController()
    $httpBackend.flush()
    expect($rootScope.dataSource.tiers).toBeDefined()

  it 'should set rules', () ->
    controller = createController()
    $httpBackend.flush()
    expect($rootScope.dataSource.rules).toBeDefined()

  it 'should set intervals, days, and dataSummary', () ->
    controller = createController()
    $httpBackend.flush()
    expect($rootScope.intervals).toBeDefined()
    expect($rootScope.days).toBeDefined()
    expect($rootScope.dataSummary).toBeDefined()
