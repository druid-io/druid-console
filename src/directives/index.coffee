app = angular.module 'druid'

app.directive 'siteNav', require('./siteNav.coffee')
app.directive 'isoDuration', require('./isoDuration.coffee')
app.directive 'isoInterval', require('./isoInterval.coffee')
app.directive 'selectTextOnClick', require('./selectTextOnClick.coffee')
app.directive 'runningTasks', require('./runningTasks.coffee')
app.directive 'scalingActivity', require('./scalingActivity.coffee')
app.directive 'tierCapacity', require('./tierCapacity.coffee')
app.directive 'tierNodes', require('./tierNodes.coffee')
app.directive 'rulesTimeline', require('./rulesTimeline.coffee')
app.directive 'timeline', require('./timeline.coffee')
