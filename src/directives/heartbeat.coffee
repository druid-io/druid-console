moment = require '../../bower_components/moment/min/moment.min.js'

module.exports = ['$timeout', '$interval', ($timeout, $interval) ->
  restrict: 'E'
  replace: true
  scope: {
    reloadData: '='
    loadedAt: '='
    initialLoad: '='
  }
  template: """
    <div class="heartbeat">
      <div ng-hide="loadedAt"><i class="fa fa-circle-o-notch fa-spin"></i>
 loading...</div>
      <div ng-show="loadedAt">data loaded {{ loadedAt.fromNow() }} <a ng-click="reloadNow()">refresh now</a>
</div>
      <div ng-show="heartbeatEnabled && nextReloadMoment">will reload {{ nextReloadMoment.fromNow() }} <a ng-click="toggleHeartbeat()">disable auto-refresh</button></div>
      <div ng-hide="heartbeatEnabled"><a ng-click="toggleHeartbeat()">enable auto-refresh</button></div>
    </span>
  """

  link: (scope, element) ->
    showHeartbeat = true
    scope.heartbeatEnabled = true
    reloadIntervalMs = 5 * 60 * 1000
    progressUpdateMs = 10 * 1000
    nextReload = null
    scope.propRemaining = 100
    scope.nextReloadMoment = false

    reload = ->
      scope.nextReloadMoment = false
      scope.reloadData()
        .then ->
          scheduleNextReload() if scope.heartbeatEnabled

    scheduleNextReload = ->
      scope.nextReloadMoment = moment.utc().add(reloadIntervalMs, 'ms')
      nextReload = $timeout(reload, reloadIntervalMs)

    scope.toggleHeartbeat = ->
      if scope.heartbeatEnabled
        $timeout.cancel(nextReload)
      else
        scheduleNextReload()

      scope.heartbeatEnabled = ! scope.heartbeatEnabled

    scope.reloadNow = ->
      $timeout.cancel(nextReload)
      reload()

    scope.initialLoad.then scheduleNextReload

    progressInterval = $interval(null, progressUpdateMs, true)

    element.on '$destroy', ->
      console.log "destroyed"
      $interval.cancel(progressInterval)
      $timeout.cancel(nextReload)

]
