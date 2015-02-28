module.exports = ($scope, $historical, $indexing, $q) ->
  $scope.env = $historical.env
  $scope.indexing = {}

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
