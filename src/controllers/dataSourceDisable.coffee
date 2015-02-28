module.exports = ($scope, $modal, $historical, $hUtils, $location) ->
  $scope.open = ->
    modalInstance = $modal.open(
      templateUrl: '/pages/disable.html'
      controller: DataSourceDisableInstanceCtrl
      size: 'sm'
      resolve:
        dataSourceId: -> $scope.dataSource.id
        '$historical': -> $historical
    )
    modalInstance.result.then ( ->
      $location.path "/#{$scope.env}/datasources"
    ), ->
      console.log "modal dismissed"
      return
    return


DataSourceDisableInstanceCtrl = ($scope, $modalInstance, dataSourceId, $historical) ->
  $scope.dataSourceId = dataSourceId

  $scope.confirm = ->
    console.log "disabling #{$scope.dataSourceId}"
    $scope.loading = true
    $historical.disableDataSource($scope.dataSourceId)
      .then (() ->
        $modalInstance.close()
      ), ((reason) ->
        $scope.postError = reason
      )
    return

  $scope.cancel = ->
    $modalInstance.dismiss "cancel"
    return
  return
