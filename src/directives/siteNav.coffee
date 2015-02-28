module.exports = ->
  restrict: 'E'
  templateUrl: '/pages/site-nav.html'
  controller: ($scope, $historical) ->
    $historical.getCoordinator().then (c) ->
      $scope.coordinator = c
