module.exports = ->
  restrict: 'E'
  replace: true
  scope: { rule: '=rule' }
  template: """
    <div class="concise-rule">
      <div>
        <span class="type">
          <span ng-class="rule.direction">{{ rule.direction }}</span>{{ rule.type.substr(4) }}
        </span>
        <span class="default" ng-if="rule.default">(default rule)</span>
      </div>

      <div class="period" ng-if="rule.period">
        <span class="value">{{ rule.period }}</span>
        <span class="human">({{ rule.momentInterval.period().humanize() }})</span>
      </div>

      <div class="interval" ng-if="rule.interval">
        <span class="value" ng-bind-html="rule.interval | simplifyInterval"></span>
        <span class="human">({{ rule.momentInterval.period().humanize() }})</span>
      </div>

      <div class="replicants">
        <div class="replicant" ng-repeat="(tier, n) in rule.tieredReplicants">
          <span class="value">{{ n }}</span> in
          <span class="tier" ng-class="tier">{{ tier | tierName}}</span>
        </div>
      </div>
    </div>"""
