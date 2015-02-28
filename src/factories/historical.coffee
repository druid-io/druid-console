module.exports = ($q, $http, $hUtils, $window) ->
  fullPath = $window.location.pathname
  env = switch
    when fullPath is '/context.html' then 'unitTest'
    when not /^\/console/.test fullPath  then false
    else
      matches = fullPath.match /^\/console\/([^\\]+)/
      matches[1]

  return {

    env

    coordinator: undefined

    proxy: (path) ->
      if @env
        "/pass/coordinator/#{@env}/druid/coordinator/v1#{path}"
      else
        "/druid/coordinator/v1#{path}"

    getAndProcess: (url, cb, cbArgs...) ->
      deferred = $q.defer()
      $http.get( @proxy url)
        .success (data) ->
          cbArgs.unshift data
          deferred.resolve cb.apply($hUtils, cbArgs)
      return deferred.promise

    getCoordinator: ->
      deferred = $q.defer()
      $http.get("/coordinator/#{@env}")
        .success (data) =>
          @coordinator = "#{data.host}:#{data.port}"
          deferred.resolve @coordinator
      return deferred.promise

    getNodes: ->
      @getAndProcess "/servers?simple", $hUtils.processServers

    getServerTiers: ->
      @getAndProcess "/servers?simple", $hUtils.processServerTiers

    getDataSources: ->
      @getAndProcess "/metadata/datasources", $hUtils.processDataSources

    getAllDataSources: ->
      @getAndProcess "/metadata/datasources?includeDisabled", (dataSources) -> dataSources

    getDataSource: (dataSourceId) ->
      @getAndProcess "/datasources/" + dataSourceId, $hUtils.processDataSource

    getLoadStatus: (dataSources) ->
      @getAndProcess "/loadstatus", $hUtils.processLoadStatus, dataSources

    getLoadQueue: (tiers) ->
      @getAndProcess "/loadqueue?simple", $hUtils.processLoadQueue, tiers

    getClusterConfig: () ->
      @getAndProcess "/config", (config) -> config

    saveClusterConfig: (config) ->
      deferred = $q.defer()
      $http.post( @proxy("/config"), config)
        .success () ->
          deferred.resolve()
        .error (data, status, headers) ->
          console.error "Error saving config - data, status, headers:", data, status, headers
          deferred.reject("Could not save config, error #{status}: #{data}")
      return deferred.promise

    getTierNames: () ->
      @getAndProcess "/tiers", (tiers) -> tiers

    getTierIntervals: (tier, dataSources) ->
      @getAndProcess "/tiers/#{tier}?simple", $hUtils.processTierIntervals, tier, dataSources

    getDataSourceIntervals: (dataSourceId) ->
      @getAndProcess "/datasources/#{dataSourceId}/intervals?simple", $hUtils.processDataSourceIntervals

    getSegmentsForInterval: (dataSourceId, interval) ->
      cleanInterval = interval.replace('/','_')
      @getAndProcess "/datasources/#{dataSourceId}/intervals/#{cleanInterval}?full", $hUtils.processSegmentsForInterval

    getAllRules: (dataSources) ->
      @getAndProcess "/rules", $hUtils.processAllRules, dataSources

    getRules: (dataSourceId) ->
      @getAndProcess "/rules/#{dataSourceId}", $hUtils.processRules

    saveRules: (dataSourceId, rules) ->
      deferred = $q.defer()
      $http.post( @proxy("/rules/#{dataSourceId}"), rules)
        .success () ->
          deferred.resolve()
        .error (data, status, headers) ->
          console.error "Error saving rules - data, status, headers:", data, status, headers
          deferred.reject("Could not save rules, error #{status}: #{data}")
      return deferred.promise

    disableDataSource: (dataSourceId) ->
      deferred = $q.defer()
      $http.delete( @proxy "/datasources/#{dataSourceId}")
        .success (data) ->
          console.log "#{dataSourceId} disabled"
          deferred.resolve "#{dataSourceId} disabled"
      return deferred.promise

    enableDataSource: (dataSourceId) ->
      deferred = $q.defer()
      $http.post( @proxy "/datasources/#{dataSourceId}")
        .success (data) ->
          console.log "#{dataSourceId} enabled"
          deferred.resolve "#{dataSourceId} enabled"
      return deferred.promise
  }
