module.exports = ->
  restrict: 'E'
  replace: true
  scope: {
    loadHistory: '='
    id: '='
    label: '@'
    button: '='
  }
  template: """
    <span class="audit-history">
      <button class="btn btn-default btn-xs" ng-click="loadAndShowHistory()"
        ng-show="button">
      <span class="fa fa-clock-o"></span> {{ label }}</button>
      <span class="fa fa-clock-o"
        ng-click="loadAndShowHistory()"
        ng-hide="button"
        ></span>

      <div class="history-overlay" ng-show="showHistory" ng-click="showHistory = false">
        <div class="history" ng-click="$event.stopPropagation()">
          <h1>Audit history changes for {{ id }}</h1>
          <div class="loading" ng-hide="auditItems">
            <i class="fa fa-circle-o-notch fa-spin"></i>
            <div>Loading rule change history...</div>
          </div>
          <div class="no-history" ng-show="auditItems.length == 0">
            No audit history found for {{ id }}
          </div>
          <div class="audit-item" ng-repeat="item in auditItems">
            <h2>
              <span class="time">{{ item.timeMoment.format("YYYY-MM-DDTHH:mm") }}Z</span>
              <span class="relative-time">({{ item.timeMoment.fromNow() }})</span>
            </h2>
            <div class="by">
              <span class="author">{{ item.auditInfo.author ? item.auditInfo.author : 'no author' }}</span>
              @
              <span class="ip">{{ item.auditInfo.ip }}</span>

            </div>
            <div class="comment">
              comment: {{ item.auditInfo.comment }}
            </div>
            <div class="payload">
              <ul>
                <li ng-repeat="rule in item.payloadParsed">
                  <one-line-rule
                    rule="rule"
                  ></one-line-rule>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </span>
  """

  link: (scope) ->
    scope.loadAndShowHistory = ->
      scope.showHistory = true
      scope.loadHistory()
        .then (auditItems) ->
          scope.auditItems = auditItems
