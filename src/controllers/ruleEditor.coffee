moment = require '../../../bower_components/moment/min/moment.min.js'
require '../../../lib/moment-interval.js'

module.exports = ($scope, $modal, $historical, $hUtils) ->

  $scope.open = ->
    modalInstance = $modal.open(
      templateUrl: '/pages/rules.html'
      controller: RuleEditorInstanceCtrl
      resolve:
        originalRules: -> angular.copy $scope.dataSource.rules
        dataSourceId: -> $scope.dataSource.id
        tierNames: -> $scope.tierNames
        '$historical': -> $historical
    )
    modalInstance.result.then ( (newRules) ->
      $scope.dataSource.rules = $hUtils.processRules(newRules)
    ), ->
      return

    return


RuleEditorInstanceCtrl = ($scope, $modalInstance, originalRules, dataSourceId, tierNames, $historical) ->
  $scope.originalRules = originalRules
  $scope.rules = angular.copy originalRules
  $scope.dataSourceId = dataSourceId
  $scope.tierNames = tierNames

  $scope.updateRuleType = (i, innerScope) ->
    rule = $scope.rules[i]

    if rule.timeType isnt rule.type.substr(4)
      switch rule.type.substr(4)
        when 'ByPeriod'
          innerScope.ruleForm.period.$setValidity 'isoDuration', true
          rule.period = ''
        when 'ByInterval'
          innerScope.ruleForm.interval.$setValidity 'isoInterval', true
          rule.interval = ''

      switch rule.timeType
        when 'Forever'
          rule.momentInterval = moment.interval("P100Y/2100")
        else delete rule.momentInterval
      console.log "rule.timeType isnt rule.type.substr(4)", rule

    rule.type = "#{rule.direction}#{rule.timeType}"
    return

  $scope.addRule = ->
    $scope.rules.push {direction: 'load', type: 'loadByPeriod', timeType: 'ByPeriod', tieredReplicants: {}}
    return

  $scope.removeRule = (i) ->
    removed = $scope.rules.splice i, 1
    return

  $scope.moveRule = (i, where) ->
    $scope.rules.splice i + where, 0, $scope.rules.splice(i, 1)[0]
    return

  $scope.addReplicant = (rule, tier)->
    rule.tieredReplicants[tier] = 1
    return

  $scope.updateReplicantCount = (rule, tier, innerScope) ->
    rule.tieredReplicants[tier] = innerScope.n
    return

  $scope.removeReplicant = (rule, tier) ->
    delete rule.tieredReplicants[tier]
    return

  $scope.replicantsNeeded = (rule) ->
    return rule.direction == 'load' and Object.keys(rule.tieredReplicants).length is 0

  $scope.replicantsForAll = (sc) ->
    return $scope.rules.every (r) -> not $scope.replicantsNeeded r

  $scope.save = ->
    rulesToSave = $scope.rules.map (r) ->
      rule = {
        type: r.type
        tieredReplicants: r.tieredReplicants
      }
      switch r.timeType
        when 'ByPeriod' then rule.period = r.period
        when 'ByInterval' then rule.interval = r.interval
      rule
    console.log "saving", rulesToSave
    $historical.saveRules($scope.dataSourceId, rulesToSave)
      .then (() ->
        $modalInstance.close(rulesToSave)
      ), ((reason) ->
        $scope.postError = reason
      )
    return

  $scope.reset = ->
    $scope.rules = angular.copy originalRules
    return

  $scope.cancel = ->
    $modalInstance.dismiss "cancel"
    return
  return
