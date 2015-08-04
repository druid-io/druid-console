module.exports = ($scope, $historical, $indexing, $q) ->
  $scope.env = $historical.env
  $scope.indexing = {}

  $indexing.getAllTasks()
    .then (tasks) ->
      $scope.indexing.tasks = tasks
      console.log {tasks}
      $scope.indexing.taskTypes = (type for type, n of tasks.running.all.reduce(((types, t) ->
        types[t.type] ||= 1
        types
      ), {}))

      dataSourceMap = {}
      for i, iTasks of tasks
        for j, jTasks of iTasks
          jTasks.forEach (t) ->
            dataSourceMap[t.dataSource] ||= 1

      dataSources = ({id} for id, d of dataSourceMap)

      dataSources.sort (a, b) ->
        return -1 if a.id < b.id
        return 1 if a.id > b.id
        return 0

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

  $scope.taskUrl = (id) ->
    $indexing.proxy "/task/#{id}"
