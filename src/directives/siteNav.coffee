module.exports = ->
  restrict: 'E'
  templateUrl: '/pages/site-nav.html'
  controller: ($scope, $historical, $indexing) ->
    $historical.getCoordinator().then (c) ->
      $scope.coordinator = c

    $indexing.getOverlord().then (c) ->
      $scope.overlord = c
