module.exports = ($scope, $historical, $q) ->
  $scope.env = $historical.env

  $scope.loadFootprints = (show) ->
    unless $scope.tiers
      $scope.footprintsLoading = true
      $historical.getTierNames()
        .then (tierNames) ->
          $scope.tierNames = tierNames
          tiers = {}
          for t in tierNames
            tiers[t] = $historical.getTierIntervals(t, $scope.dataSources)
          $q.all( tiers )
        .then (tiers) ->
          $scope.footprintsLoading = false
          $scope.footprintsLoaded = true
          $scope.tiers = tiers
          tiersArr = (t for n, t of tiers)
          $scope.clusterSummary =
            size: d3.sum tiersArr, (t) -> t.size
            count: d3.sum tiersArr, (t) -> t.count
            minTime: d3.min tiersArr, (t) -> t.minTime
            maxTime: d3.max tiersArr, (t) -> t.maxTime

  $scope.setEnabled = (status) ->
    $scope.enabled = status
    if status is 'disabled' and not $scope.disabledDataSources?
      $historical.getAllDataSources()
        .then (dataSources) ->
          $scope.allDataSources = dataSources
          $scope.disabledDataSources = dataSources.filter (ds) ->
            ds not in $scope.dataSources.map (d) -> d.id

  $historical.getDataSources()
    .then (dataSources) ->
      $scope.dataSources = dataSources
      $q.all(
        loadStatus: $historical.getLoadStatus($scope.dataSources)
        rules: $historical.getAllRules($scope.dataSources)
      )
    .then (results) ->
      $scope.defaultRules = results.rules._default

  unless $scope.tierNames
    $historical.getTierNames().then (tierNames) ->
      $scope.tierNames = tierNames
