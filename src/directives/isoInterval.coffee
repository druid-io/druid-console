moment = require '../../../bower_components/moment/min/moment.min.js'
require '../../../lib/moment-interval.js'

module.exports = ->
  require: 'ngModel'
  link: ($scope, $el, $attrs, $ctrl) ->
    $ctrl.$parsers.unshift (viewValue) ->
      unless viewValue?
        $ctrl.$setValidity 'isoInterval', true
        return ''
      viewValues = viewValue.split('/').map (v) -> moment.utc(if v is '' then 'empty' else v )
      if viewValues.length isnt 2 or
          viewValues.some((v) -> not v.isValid()) or
          not viewValues[0].isBefore(viewValues[1])
        $ctrl.$setValidity 'isoInterval', false
        delete $scope.rule.momentInterval if $scope.rule.momentInterval?
        return undefined
      else
        $ctrl.$setValidity 'isoInterval', true
        val = viewValues.map( (v) -> v.toISOString()).join('/')
        $scope.rule.momentInterval = moment.interval(val)
        return val
