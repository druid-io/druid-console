# dataSourceController = require '../../../src/controllers/dataSource.coffee'

# beforeEach angular.mock.module("druid")

# describe 'dataSourceCtrl', () ->
#   $httpBackend = undefined
#   $rootScope = undefined
#   createController = undefined

#   scope = undefined
#   fakeEnv = undefined
#   routeParams = undefined
#   fakeCoordinator = undefined
#   fakeDataSource = undefined
#   fakeDataSources = undefined
#   fakeIntervals = undefined
#   fakeTierNames = undefined
#   fakeRules = undefined

#   beforeEach inject ($injector, $historical) ->
#     routeParams =
#       dataSource: 'testDataSource'
#     fakeEnv = "testEnv"
#     fakeCoordinator = {host:'123', port:456}
#     fakeDataSources = []
#     fakeDataSource = {tiers: {}, segments: {}}
#     fakeIntervals = {
#       intervals: {}
#       days: {}
#       dataSummary: {}
#     }
#     fakeTierNames = ['a', 'b']
#     fakeRules = []

#     $historical.env = routeParams.env

#     $httpBackend = $injector.get '$httpBackend'

#     $httpBackend.whenGET(/^\/coordinator/)
#       .respond(fakeCoordinator)

#     $httpBackend.whenGET($historical.proxy "/datasources/#{routeParams.dataSource}")
#       .respond(fakeDataSource)

#     $httpBackend.whenGET($historical.proxy "/datasources/#{routeParams.dataSource}/intervals?simple")
#       .respond(fakeIntervals)

#     $httpBackend.whenGET($historical.proxy "/rules/#{routeParams.dataSource}")
#       .respond(fakeRules)

#     $httpBackend.whenGET($historical.proxy "/datasources/#{routeParams.dataSource}")
#       .respond(fakeRules)

#     $httpBackend.whenGET($historical.proxy "/tiers")
#       .respond(fakeTierNames)

#     delete $historical.env
#     $controller = $injector.get '$controller'
#     $rootScope = $injector.get '$rootScope'

#     createController = () ->
#       $controller dataSourceController, {
#         '$scope': $rootScope
#         $historical: $injector.get '$historical'
#         $routeParams: routeParams
#         $q: $injector.get '$q'
#       }

#   afterEach () ->
#     $httpBackend.verifyNoOutstandingExpectation()
#     $httpBackend.verifyNoOutstandingRequest()

#   it 'should set env', () ->
#     controller = createController()
#     $httpBackend.flush();
#     expect($rootScope.env).toBe(routeParams.env)

#   it 'should set coordinator', () ->
#     controller = createController()
#     $httpBackend.flush()
#     expect($rootScope.coordinator).toBe('123:456')

#   it 'should set tierNames', () ->
#     controller = createController()
#     $httpBackend.flush()
#     expect($rootScope.tierNames).toEqual(fakeTierNames)

#   it 'should extend dataSource', () ->
#     controller = createController()
#     $httpBackend.flush()
#     expect($rootScope.dataSource.tiers).toBeDefined()

#   it 'should set rules', () ->
#     controller = createController()
#     $httpBackend.flush()
#     expect($rootScope.dataSource.rules).toBeDefined()

#   it 'should set intervals, days, and dataSummary', () ->
#     controller = createController()
#     $httpBackend.flush()
#     expect($rootScope.intervals).toBeDefined()
#     expect($rootScope.days).toBeDefined()
#     expect($rootScope.dataSummary).toBeDefined()
