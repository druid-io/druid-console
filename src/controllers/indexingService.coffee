module.exports = ($scope, $historical, $indexing, $q) ->
  $scope.env = $historical.env
  $scope.indexing = {}

  $indexing.getAllTasks()
    .then (tasks) ->
      $scope.indexing.tasks = tasks
      console.log {tasks}

      dataSourceMap = {}
      for i, iTasks of tasks
        console.log {iTasks}
        for j, jTasks of iTasks
          console.log {jTasks}
          jTasks.forEach (t) ->
            dataSourceMap[t.dataSource] ||= 1

      console.log {dataSourceMap}
      dataSources = ({id} for id, d of dataSourceMap)
        .sort (a, b) -> a.id - b.id
      $scope.dataSources = dataSources
      console.log {dataSources}

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

  $scope.loadWorkerConfigHistory = ->
    $indexing.getWorkerConfigHistory()
