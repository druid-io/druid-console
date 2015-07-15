moment = require '../../../bower_components/moment/min/moment.min.js'
require '../../../lib/moment-interval.js'

module.exports = ->
  require: 'ngModel'
  link: ($scope, $el, $attrs, $ctrl) ->
    durationRegex = /^P(?=\w*\d)(?:\d+Y|Y)?(?:\d+M|M)?(?:\d+W|W)?(?:\d+D|D)?(?:T(?:\d+H|H)?(?:\d+M|M)?(?:\d+(?:\­.\d{1,2})?S|S)?)?$/
    $ctrl.$parsers.unshift (viewValue) ->
      unless viewValue?
        $ctrl.$setValidity 'isoDuration', true
        return ''
      if durationRegex.test viewValue
        $ctrl.$setValidity 'isoDuration', true
        $scope.rule.momentInterval = moment.interval(viewValue + '/')
        return viewValue
      else
        $ctrl.$setValidity 'isoDuration', false
        delete $scope.rule.momentInterval if $scope.rule.momentInterval?
        return undefined
