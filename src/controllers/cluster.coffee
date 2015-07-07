moment = require '../../bower_components/moment/min/moment.min.js'

module.exports = ($scope, $historical, $indexing, $q) ->
  $scope.env = $historical.env
  $scope.indexing = {}
  $scope.loadedAt = false

  $scope.loadAllData = ->
    $scope.loadedAt = false
    $q.all [
      $historical.getNodes()
        .then (cluster) ->
          $scope.tiers = cluster.tiers
          $q.all([
            $historical.getLoadQueue($scope.tiers)
          ])
      $historical.getDataSources()
        .then (dataSources) ->
          $scope.dataSources = dataSources
          $historical.getLoadStatus($scope.dataSources)

      $indexing.getAllTasks()
        .then (tasks) ->
          $scope.indexing.tasks = tasks
          console.log {tasks}

      $indexing.getWorkers()
        .then ({workers, dataSources, slots}) ->
          $scope.indexing.workers = workers
          $scope.indexing.dataSources = dataSources
          $scope.indexing.slots = slots
          console.log {workers, dataSources, slots}

      $indexing.getScaling()
        .then (scaling) ->
          $scope.indexing.scaling = scaling
          console.log {scaling}

    ]
      .then ->
        $scope.loadedAt = moment.utc()



  $scope.loadConfigHistory = ->
    $historical.getCoordinatorConfigHistory()

  $scope.initialLoad = $scope.loadAllData()
