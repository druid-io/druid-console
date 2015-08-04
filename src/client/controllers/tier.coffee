# TODO - build this out
module.exports = ($scope, $historical, $stateParams, $q) ->
  $scope.env = $historical.env
  $scope.id = {id: $stateParams.id}
