module.exports = ->
  restrict: 'E'
  replace: true
  scope: { rule: '=rule' }
  template: """
    <div class="rule">
      <span class="direction" ng-class="rule.direction">
        {{ rule.direction }}
      </span>

      <span class="forever" ng-if="rule.timeType == 'Forever'">Forever</span>

      <span class="period" ng-if="rule.period">
        <span class="value">{{ rule.period }}</span><span ng-if="rule.direction == 'load'">:</span>
      </span>

      <span class="interval" ng-if="rule.interval">
        <span class="value" ng-bind-html="rule.interval | simplifyInterval"></span><span ng-if="rule.direction == 'load'">:</span>
      </span>

      <span class="replicants">
        <span class="replicant" ng-repeat="(tier, n) in rule.tieredReplicants">
          <span class="value">{{ n }}</span>
          in
          <span class="tier" ng-class="tier">{{ tier | tierName }}</span>{{ $last ? '' : ',' }}
        </span>
      </span>
    </div>
  """
