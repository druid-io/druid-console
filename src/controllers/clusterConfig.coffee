module.exports = ($scope, $modal, $historical, $hUtils, $location) ->
  $scope.open = ->
    modalInstance = $modal.open(
      # templateUrl: '/pages/disable.html'
      template: '
        <div class="cluster-config">
          <div class="modal-header">
              <h1>Edit Cluster Config</h1>
          </div>
          <div class="modal-body">
            <span class="fa fa-cog fa-spin fa-2x" ng-show="loading"></span>
            <table>
              <tr ng-repeat="(key, val) in config">
                <td class="key">{{ key }}</td>
                <td class="val">
                  <input ng-model="config[key]">
                </td>
              </td>
            </table>
            <alert type="danger" ng-show="postError">{{postError}}</alert>
          </div>
          <div class="modal-footer">
            <button class="btn btn-danger" ng-click="cancel()" ng-disabled="loading">Cancel</button>
            <button class="btn btn-primary" ng-click="save()" ng-disabled="loading">Save</button>
          </div>
        </div>'
      controller: ClusterConfigInstanceCtrl
      size: 'sm'
      resolve:
        '$historical': -> $historical
    )

    return


ClusterConfigInstanceCtrl = ($scope, $modalInstance, $historical) ->
  $scope.loading = true

  $historical.getClusterConfig()
    .then (config) ->
      $scope.config = config
      $scope.loading = false

  $scope.save = ->
    console.log "saving config"
    if confirm("Do you really want to update the cluster configuration?")
      $scope.loading = true
      console.log '$scope.config', $scope.config
      $historical.saveClusterConfig($scope.config)
        .then (() ->
          $modalInstance.close()
        ), ((reason) ->
          $scope.postError = reason
          console.log reason
        )
      return

  $scope.cancel = ->
    $modalInstance.dismiss "cancel"
    return

  return
