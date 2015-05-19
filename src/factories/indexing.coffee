# http://10.190.217.107:8080/druid/indexer/v1/scaling
# http://10.190.217.107:8080/druid/indexer/v1/workers
# http://10.190.217.107:8080/druid/indexer/v1/runningTasks (running, pending, waiting, complete)
module.exports = ($q, $http, $iUtils, $window) ->
  fullPath = $window.location.pathname
  env = switch
    when fullPath is '/context.html' then 'unitTest'
    when not /^\/console/.test fullPath  then false
    else
      matches = fullPath.match /^\/console\/([^\\]+)/
      matches[1]

  return {

    env

    overlord: undefined

    proxy: (path) ->
      if @env
        "/pass/indexer/#{@env}/druid/indexer/v1#{path}"
      else
        "/druid/indexer/v1#{path}"

    getAndProcess: (url, cb, cbArgs...) ->
      deferred = $q.defer()
      $http.get( @proxy url)
        .success (data) ->
          cbArgs.unshift data
          deferred.resolve cb.apply($iUtils, cbArgs)
      return deferred.promise

    getOverlord: ->
      deferred = $q.defer()
      $http.get("/overlord/#{@env}")
        .success (data) =>
          @overlord = "#{data.host}:#{data.port}"
          deferred.resolve @overlord
      return deferred.promise

    getWorkers: ->
      @getAndProcess "/workers", (rawWorkers) ->
        rawWorkers.reduce(((all, worker) ->
          {tasks, dataSources} = worker.runningTasks.reduce(((allTasks, id) ->
            task = $iUtils.parseTaskId id
            allTasks.tasks.push(task)
            allTasks.dataSources[task.dataSource] ?=  []
            allTasks.dataSources[task.dataSource].push task
            return allTasks
          ), {tasks:[], dataSources: all.dataSources})
          worker.tasks = tasks

          all.slots.capacity += worker.worker.capacity
          all.slots.used += worker.currCapacityUsed

          all.workers.push worker
          return all
        ), {workers:[], dataSources:{}, slots: {capacity:0, used:0}})


    getScaling: ->
      @getAndProcess "/scaling", (scaling) ->
        scaling.map (s) -> s.date = new Date(s.timestamp); s

    getAllTasks: ->
      $q.all({
        running: @getRunningTasks()
        pending: @getPendingTasks()
        waiting: @getWaitingTasks()
      })

    getRunningTasks: ->
      @getAndProcess "/runningTasks", $iUtils.processTasks

    getPendingTasks: ->
      @getAndProcess "/pendingTasks", $iUtils.processTasks

    getWaitingTasks: ->
      @getAndProcess "/waitingTasks", $iUtils.processTasks

    getCompleteTasks: ->
      @getAndProcess "/completeTasks", $iUtils.processTasks

    getTask: (id) ->
      @getAndProcess "/task/#{id}", (task) -> task

    getWorkerConfig: () ->
      @getAndProcess "/worker", (config) -> config

    saveWorkerConfig: (config) ->
      # TODO: Remove the following
      return
      deferred = $q.defer()
      $http.post( @proxy("/worker"), config)
        .success () ->
          deferred.resolve()
        .error (data, status, headers) ->
          console.error "Error saving config - data, status, headers:", data, status, headers
          deferred.reject("Could not save config, error #{status}: #{data}")
      return deferred.promise

    getWorkerConfigHistory: (interval=null) ->
      intervalQuery = if interval? then "interval=#{interval}" else ""
      @getAndProcess "/worker/history?#{intervalQuery}", $iUtils.processConfigHistory

  }
