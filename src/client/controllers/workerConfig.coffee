module.exports = ($scope, $modal, $indexing, $iUtils) ->
  $scope.open = ->
    modalInstance = $modal.open(
      template: '
        <div class="worker-config">
          <div class="modal-header">
              <h1>Edit Worker Config</h1>
          </div>
          <div class="modal-body">
            <span class="fa fa-cog fa-spin fa-2x" ng-show="loading"></span>
            <pre ng-show="config">{{ config | json }}</pre>
          </div>
          <div class="modal-footer">
            <button class="btn btn-danger" ng-click="cancel()" ng-disabled="loading">Cancel</button>
            <button disabled class="btn btn-primary" ng-click="save()">Read only right now</button>
          </div>
        </div>'
      controller: WorkerConfigInstanceCtrl
      resolve:
        '$indexing': -> $indexing
    )

    return


WorkerConfigInstanceCtrl = ($scope, $modalInstance, $indexing) ->
  $scope.loading = true

  $indexing.getWorkerConfig()
    .then (config) ->
      $scope.config = config
      $scope.loading = false

  $scope.save = ->
    console.log "saving config"
    if confirm("Do you really want to update the worker configuration?")
      $scope.loading = true
      console.log '$scope.config', $scope.config
      $indexing.saveWorkerConfig($scope.config)
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
