module.exports = ($scope, $modal, $historical, $hUtils, $location) ->
  $scope.open = ->
    modalInstance = $modal.open(
      # templateUrl: '/pages/disable.html'
      template: '
        <div class="modal-body">
          <span class="fa fa-cog fa-spin fa-2x" ng-show="loading"></span>
          <button class="btn btn-primary" ng-click="confirm()" ng-disabled="loading">Enable {{ dataSourceId }}</button>
          <button class="btn btn-default" ng-click="cancel()" ng-disabled="loading">Never mind...</button>
        </div>'
      controller: DataSourceEnableInstanceCtrl
      size: 'sm'
      resolve:
        dataSourceId: -> $scope.dataSourceId
        '$historical': -> $historical
    )
    modalInstance.result.then ( ->
      $location.path "/#{$scope.env}/datasources/#{$scope.dataSourceId}";
    ), ->
      console.log "modal dismissed"
      return
    return


DataSourceEnableInstanceCtrl = ($scope, $modalInstance, dataSourceId, $historical) ->
  $scope.dataSourceId = dataSourceId

  $scope.confirm = ->
    console.log "enabling #{$scope.dataSourceId}"
    $scope.loading = true
    $historical.enableDataSource($scope.dataSourceId)
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
