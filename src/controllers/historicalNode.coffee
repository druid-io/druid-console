module.exports = ($scope, $historical, $stateParams, $q) ->
  $scope.env = $historical.env
  $scope.dataSource = {id: $stateParams.id}
