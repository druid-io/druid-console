module.exports = ($scope, $historical, $stateParams, $q) ->
  $scope.env = $historical.env
  $scope.dataSource = {id: $stateParams.id}

  $scope.segUrl = (segId) ->
    $historical.proxy "/datasources/#{$scope.dataSource.id}/segments/#{segId}"

  $scope.selectInterval = (interval) ->
    delete $scope.selectedSegments
    $scope.selectedInterval = interval

    unless $scope.serverTiers?
      $historical.getServerTiers()
        .then (serverTiers) ->
          $scope.serverTiers = serverTiers

    $historical.getSegmentsForInterval($scope.dataSource.id, $scope.selectedInterval.interval)
      .then (segments) ->
        $scope.selectedSegments = segments

  $scope.getDaily = ->
    console.log 'getDaily'
    return ({
      day: d.day
      size: d.size
      count: d.count
      start: d.startDate.toISOString()
      end: d.endDate.toISOString()
    } for d in $scope.days)

  $scope.getMonthly = ->
    console.log 'getMonthly'
    months = ({
      month: m.month
      size: m.size
      count: m.count
      start: (new Date(m.start)).toISOString()
      end: (new Date(m.end)).toISOString()
    } for i, m of $scope.days.reduce(((months, d) ->
      m = d.day.substr(0,7)
      months[m] ?= {
        month: m
        size: 0
        count: 0
        start: d.startDate
        end: d.endDate
      }
      month = months[m]
      month.size += d.size
      month.count += d.count
      month.start = Math.min(d.startDate, month.start)
      month.end = Math.min(d.endDate, month.end)
      months
    ), {}))
    return months

  $scope.s3Path = (seg) ->
    "s3://#{seg.loadSpec.bucket}/#{seg.loadSpec.key}"

  $historical.getDataSource($scope.dataSource.id)
    .then (dataSource) ->
      angular.extend $scope.dataSource, dataSource

  $historical.getRules($scope.dataSource.id)
    .then (rules) ->
      $scope.dataSource.rules = rules
      $historical.getDataSourceIntervals($scope.dataSource.id)
    .then (results) ->
      console.log {results}
      $scope.intervals = results.intervals
      $scope.days = results.days
      $scope.dataSummary = results.summary
      $scope.unreplicatedSegmentSize = d3.sum(results.intervals, (i) -> i.size)

  $historical.getRules('_default')
    .then (defaultRules) ->
      rule.default = true for rule in defaultRules
      $scope.defaultRules = defaultRules

  unless $scope.tierNames
    $historical.getTierNames().then (tierNames) ->
      $scope.tierNames = tierNames

