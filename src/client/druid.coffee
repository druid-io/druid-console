require '../../bower_components/zeroclipboard/ZeroClipboard.min.js'
_ = require '../../bower_components/underscore/underscore.js'
$ = require 'jquery'
require '../../bower_components/angular/angular.min.js'
require '../../bower_components/angular-ui-router/release/angular-ui-router.min.js'
require '../../bower_components/angular-sanitize/angular-sanitize.min.js'
require '../../bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js'
require '../../bower_components/ng-clip/dest/ng-clip.min.js'
require '../../bower_components/ng-csv/build/ng-csv.min.js'
moment = require '../../bower_components/moment/min/moment.min.js'
require '../../lib/moment-interval.js'
d3 = require '../../bower_components/d3/d3.js'

startTime = new Date()
app = angular.module 'druid', ['ngClipboard', 'ngCsv', 'ui.bootstrap', 'ui.router']

app.filter 'startsWith', () ->
  (items, prefix) ->
    return items unless prefix?.length > 0
    filtered = []
    angular.forEach items, (item) ->
      filtered.push(item) if (item.interval.indexOf prefix) is 0
    filtered

app.filter 'bytes', () ->
  (n) ->
    return unless n?
    prefix = d3.formatPrefix(n, 3)
    "" + prefix.scale(d3.format('.3r')(n)) + " " + prefix.symbol + 'B'

app.filter 'percentRound', () ->
  (n) ->
    return unless n?
    d3.format('.2p')(n)

app.filter 'tierName', () ->
  (n) -> if n is '_default_tier' then 'cold' else n

app.filter 'commasToSpaces', () ->
  (x) ->
    x.replace /,/g, ' '

app.filter 'availableTiers', () ->
  (x, $scope) ->
    x.filter (x) -> x not of $scope.rule.tieredReplicants

app.filter 'simplifyInterval', ($sce) ->
  (x, html) ->
    html ?= true
    [timeSep, intervalSep] = if html
      ['<span class="time-sep">T</span>', '<span class="interval-sep">/</span>']
    else
      ['T', '/']

    intervalRe = /(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2}).(\d{3})Z\/(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2}).(\d{3})Z/
    m = x.match intervalRe
    throw "#{x} is not a valid interval" unless m

    simplified = [ [5,4,3,2], [10,9,8,7] ].map( (idx, j) ->
      date = m[j * 5 + 1]
      nonZero = _.find idx, (i) -> parseInt m[i] isnt 0
      switch nonZero
        when undefined then date
        when idx[3] then "#{date}#{timeSep}#{m[idx[3]]}"
        when idx[0] then "#{date}#{timeSep}#{m[idx[3]]}:#{m[idx[2]]}"
        when idx[0] then "#{date}#{timeSep}#{m[idx[3]]}:#{m[idx[2]]}:#{m[idx[1]]}"
        when idx[0] then "#{date}#{timeSep}#{m[idx[3]]}:#{m[idx[2]]}:#{m[idx[1]]}.#{m[idx[0]]}Z"
    ).join(intervalSep)

    return $sce.trustAsHtml(simplified)

app.filter 'isoHour', () ->
  (t) ->
    "#{t.substring(0,10)}<span class=\"sep\">T</span>#{t.substring(11,13)}"

app.config ($stateProvider, $urlRouterProvider) ->

  $stateProvider
    .state('cluster', {
      url: '/'
      templateUrl: '/pages/cluster.html'
      controller: 'DruidClusterCtrl'
    })
    .state('dataSources', {
      url: '/datasources'
      templateUrl: '/pages/data-sources.html'
      controller: 'DruidDataSourcesCtrl'
    })
    .state('dataSource', {
      url: '/datasources/:id'
      templateUrl: '/pages/data-source.html'
      controller: 'DruidDataSourceCtrl'
    })
    .state('rules', {
      url: '/datasources/:id/rules'
      templateUrl: '/pages/rules.html'
      controller: 'RulesCtrl'
    })

  $urlRouterProvider.otherwise('/')


app.factory '$druid', ($q, $http, $utils, $window) ->
  fullPath = $window.location.pathname
  env = switch
    when fullPath is '/context.html' then 'unitTest'
    when not /^\/console/.test fullPath  then false
    else
      matches = fullPath.match /^\/console\/([^\\]+)/
      matches[1]

  return {

    env

    coordinator: undefined

    proxy: (path) ->
      if @env
        "/pass/coordinator/#{@env}/druid/coordinator/v1#{path}"
      else
        "/druid/coordinator/v1#{path}"

    getAndProcess: (url, cb, cbArgs...) ->
      deferred = $q.defer()
      $http.get( @proxy url)
        .success (data) ->
          cbArgs.unshift data
          deferred.resolve cb.apply($utils, cbArgs)
      return deferred.promise

    getCoordinator: ->
      deferred = $q.defer()
      $http.get("/coordinator/#{@env}")
        .success (data) =>
          @coordinator = "#{data.host}:#{data.port}"
          deferred.resolve @coordinator
      return deferred.promise

    getNodes: ->
      @getAndProcess "/servers?simple", $utils.processServers

    getServerTiers: ->
      @getAndProcess "/servers?simple", $utils.processServerTiers

    getDataSources: ->
      @getAndProcess "/db/datasources", $utils.processDataSources

    getAllDataSources: ->
      @getAndProcess "/db/datasources?includeDisabled", (dataSources) -> dataSources

    getDataSource: (dataSourceId) ->
      @getAndProcess "/datasources/#{dataSourceId}", $utils.processDataSource

    getLoadStatus: (dataSources) ->
      @getAndProcess "/loadstatus", $utils.processLoadStatus, dataSources

    getLoadQueue: (tiers) ->
      @getAndProcess "/loadqueue?simple", $utils.processLoadQueue, tiers

    getClusterConfig: () ->
      @getAndProcess "/config", (config) -> config

    saveClusterConfig: (config) ->
      deferred = $q.defer()
      $http.post( @proxy("/config"), config)
        .success () ->
          deferred.resolve()
        .error (data, status, headers) ->
          console.error "Error saving config - data, status, headers:", data, status, headers
          deferred.reject("Could not save config, error #{status}: #{data}")
      return deferred.promise

    getTierNames: () ->
      @getAndProcess "/tiers", (tiers) -> tiers

    getTierIntervals: (tier, dataSources) ->
      @getAndProcess "/tiers/#{tier}?simple", $utils.processTierIntervals, tier, dataSources

    getDataSourceIntervals: (dataSourceId) ->
      @getAndProcess "/datasources/#{dataSourceId}/intervals?simple", $utils.processDataSourceIntervals

    getSegmentsForInterval: (dataSourceId, interval) ->
      cleanInterval = interval.replace('/','_')
      @getAndProcess "/datasources/#{dataSourceId}/intervals/#{cleanInterval}?full", $utils.processSegmentsForInterval

    getAllRules: (dataSources) ->
      @getAndProcess "/rules", $utils.processAllRules, dataSources

    getRules: (dataSourceId) ->
      @getAndProcess "/rules/#{dataSourceId}", $utils.processRules

    saveRules: (dataSourceId, rules) ->
      deferred = $q.defer()
      $http.post( @proxy("/rules/#{dataSourceId}"), rules)
        .success () ->
          deferred.resolve()
        .error (data, status, headers) ->
          console.error "Error saving rules - data, status, headers:", data, status, headers
          deferred.reject("Could not save rules, error #{status}: #{data}")
      return deferred.promise

    disableDataSource: (dataSourceId) ->
      deferred = $q.defer()
      $http.delete( @proxy "/datasources/#{dataSourceId}")
        .success (data) ->
          console.log "#{dataSourceId} disabled"
          deferred.resolve "#{dataSourceId} disabled"
      return deferred.promise

    enableDataSource: (dataSourceId) ->
      deferred = $q.defer()
      $http.post( @proxy "/datasources/#{dataSourceId}")
        .success (data) ->
          console.log "#{dataSourceId} enabled"
          deferred.resolve "#{dataSourceId} enabled"
      return deferred.promise
  }


app.factory '$utils', ->

  processServers: (nodes) ->
    cluster = nodes.reduce(((cluster, node) ->
      node.id = node.host
      [node.hostname, node.port] = node.host.split(':')

      if node.type isnt 'historical'
        if node.type is 'realtime'
          cluster.realtime.push node
          return cluster
        if node.type is 'indexer-executor'
          cluster.indexer.push node
          return cluster
        console.log node
        throw "Don't know what to do with this node"

      node.utilization = node.currSize / node.maxSize

      if node.tier of cluster.tiers
        cluster.tiers[node.tier].nodes.push node
      else
        cluster.tiers[node.tier] = {
          tier: node.tier
          nodes: [node]
        }
      return cluster
    ), { tiers:{}, realtime:[], indexer:[]})

    cluster.tiers = (tier for n, tier of cluster.tiers)

    for tier in cluster.tiers
      tier.maxSize = d3.sum tier.nodes, (t) -> t.maxSize
      tier.currSize = d3.sum tier.nodes, (t) -> t.currSize
      tier.utilization = tier.currSize / tier.maxSize
      tier.resilience = @resilience(tier)
      tier.nodes.sort (a,b) ->
        b.utilization - a.utilization

    return cluster

  processServerTiers: (servers) ->
    serverTiers = {}
    for server in servers
      [server.hostname, server.port] = server.host.split(':')
      serverTiers[server.host] = server
    return serverTiers

  processDataSources: (dataSources) -> ({id: ds} for ds in dataSources)

  processDataSource: (dataSource) ->
    dataSource.segments.interval = moment.interval "#{dataSource.segments.minTime}/#{dataSource.segments.maxTime}"
    return dataSource

  processLoadStatus: (loadStatuses, dataSources) ->
    for ds in dataSources
      ds.loadStatus = loadStatuses[ds.id]
    return dataSources

  processLoadQueue: (nodes, tiers) ->
    for tier in tiers
      for node in tier.nodes
        angular.extend(node, nodes[node.host])
      for i in [
        "segmentsToLoad"
        "segmentsToDrop"
        "segmentsToLoadSize"
        "segmentsToDropSize"
      ]
        tier[i] = d3.sum(tier.nodes, (n) -> n[i])
    return tiers

  decorateRule: (rule) ->
    rule.direction = rule.type.substr(0,4)
    rule.timeType = rule.type.substr(4)
    switch rule.timeType
      when 'ByPeriod'
        rule.momentInterval = moment.interval(rule.period + '/')
      when 'ByInterval'
        rule.momentInterval = moment.interval(rule.interval)
      when 'Forever'
        rule.momentInterval = moment.interval("P100Y/2100")
    return rule

  processAllRules: (rules, dataSources) ->
    for rule in rules._default
      @decorateRule(rule)
      rule.default = true

    for ds in dataSources
      if ds.id of rules
        ds.rules = rules[ds.id]
        for rule in ds.rules
          @decorateRule(rule)
          rule.default = false
      else
        ds.rules = []

    return { dataSources, _default: {id:'_default', rules: rules._default} }

  processRules: (rules) ->
    rules.map @decorateRule

  resilience: (tier) ->
    Math.floor(tier.nodes.length - tier.currSize / d3.max(tier.nodes, (d) -> d.maxSize))

  processDataSourceIntervals: (ints) ->
    preProcess = new Date()

    intervals = (angular.extend(int, {interval: i}) for i, int of ints)
      .sort (a, b) ->
        return -1 if (a.interval > b.interval)
        return 1 if (a.interval < b.interval)
        return 0
    preProcessDays = new Date()

    # console.log "processed intervals in #{(new Date() - preProcess)/ 1000}s"

    intervalDays = intervals.reduce(((days, i) ->
      day = i.interval.substring(0,10)
      days[day] ?= []
      days[day].push i
      days
    ), {})

    days = ({
       day: day
       size: d3.sum ints, (i) -> i.size
       count: d3.sum ints, (i) -> i.count
       startDate: new Date(ints[ints.length - 1].interval.substring(0,24))
       endDate: new Date(ints[0].interval.substring(25))
       interval: ints[ints.length - 1].interval.substring(0,24) + '/' + ints[0].interval.substring(25)
    } for day, ints of intervalDays)

    # console.log "processed days in #{(new Date() - preProcessDays)/ 1000}s"

    summary =
      size: d3.sum intervals, (i) -> i.size
      count: d3.sum intervals, (i) -> i.count
      interval: moment.interval(
        intervals[intervals.length - 1]
          .interval.substring(0,24) +
        "/" + intervals[0].interval.substring(25)
      )
    return {intervals, summary, days}

  processSegmentsForInterval: (segs) ->
    segs = (s for i, s of segs)[0]
    segments = {}
    for s, seg of segs
      seg.metadata.servers = seg.servers
      segments[s] = seg.metadata
    segments

  processTierIntervals: (results, tier, dataSources) ->
    preParse = new Date()

    tierDataSources = []
    for ds, ints of results

      intervals = (angular.extend(int, {interval: i}) for i, int of ints)
        .sort (a, b) ->
          return -1 if (a.interval > b.interval)
          return 1 if (a.interval < b.interval)
          return 0

      intervalDays = intervals.reduce(((days, i) ->
        day = i.interval.substring(0,10)
        days[day] ?= []
        days[day].push i
        days
      ), {})

      days = ({
         tier
         day: day
         size: d3.sum ints, (i) -> i.size
         count: d3.sum ints, (i) -> i.count
         startDate: new Date(_.last(ints).interval.substring(0,24))
         endDate: new Date(ints[0].interval.substring(25))
         interval: _.last(ints).interval.substring(0,24) + '/' + ints[0].interval.substring(25)
      } for day, ints of intervalDays)

      summary =
        size: d3.sum intervals, (i) -> i.size
        count: d3.sum intervals, (i) -> i.count
        interval: moment.interval(
          _.last(intervals)
            .interval.substring(0,24) +
          "/" + intervals[0].interval.substring(25)
        )

      og = _.find dataSources, (d) -> d.id is ds
      og.tiers ?= {}
      og.tiers[tier] = { tier, intervals, days, summary }
      tierDataSources.push og.tiers[tier]

    tierSummary =
      size: d3.sum tierDataSources, (ds) -> ds.summary.size
      count: d3.sum tierDataSources, (ds) -> ds.summary.count
      minTime: d3.min tierDataSources, (ds) -> _.last(ds.days).startDate
      maxTime: d3.max tierDataSources, (ds) -> ds.days[0].endDate

    console.log "Parsed all intervals for #{tier} in #{(new Date() - preParse)/ 1000}s"

    return tierSummary


app.directive 'siteNav', ->
  restrict: 'E'
  templateUrl: '/pages/site-nav.html'
  controller: ($scope, $druid) ->
    $druid.getCoordinator().then (c) ->
      $scope.coordinator = c


app.directive 'isoDuration', ->
  require: 'ngModel'
  link: ($scope, $el, $attrs, $ctrl) ->
    durationRegex = /^P(((\d+)Y)?((\d)+M)?((\d)+D)?|(\d)+W)$/
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


app.directive 'isoInterval', ->
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
        console.log 'true'
        $ctrl.$setValidity 'isoInterval', true
        val = viewValues.map( (v) -> v.toISOString()).join('/')
        $scope.rule.momentInterval = moment.interval(val)
        return val


app.directive 'selectTextOnClick', ->
  restrict: 'A',
  link: ($scope, $el) ->
    $el.on 'click', () ->
      window.getSelection().selectAllChildren($el[0])


app.directive 'tierCapacity', ->
  restrict: 'E'
  link: ($scope, el) ->
    siBytesFormat = (n) ->
      return unless n?
      prefix = d3.formatPrefix(n, 3)
      "" + prefix.scale(d3.format('.3r')(n)) + " " + prefix.symbol + 'B'
    percentFormat = d3.format('.1%')

    tier = $scope.tier
    tierData =
      currSize: tier.currSize
      maxSize: tier.maxSize
      nodeCount: tier.nodes.length
      utilization: tier.utilization
      resilience: tier.resilience

    topMargin = 0
    [barWidth, barHeight] = [60, 180]

    capDiv = d3.select(el[0])

    svg = capDiv.append('svg')
      .attr("width", barWidth)
      .attr("height", barHeight + topMargin)

    capacityG = svg.selectAll("g.capacity")
        .data([tierData])
      .enter()
        .append("g").attr('class', 'capacity')
          .attr('transform', "translate(0,#{topMargin})")

    capacityG.append('rect').attr('class', 'maxSize')
      .attr("width", barWidth)
      .attr("height", barHeight)

    capacityG.append('rect').attr('class', 'currSize')
      .attr('y', (d) -> barHeight * (1 - d.utilization))
      .attr("width", barWidth)
      .attr("height", (d) -> barHeight * d.utilization)

    nodesG = svg.append('g').attr('class', 'nodes')
      .attr('transform', "translate(0,#{topMargin})")

    nodes = nodesG.selectAll("circle.node")
        .data(tier.nodes)
      .enter()
        .append("circle").attr('class', 'node')
          .attr('transform', (d) ->
            "translate(0,#{barHeight * (1 - d.currSize / d.maxSize)})"
          )
          .attr('r', 3)
          .attr('cx', (d) -> barWidth * (0.08 + Math.random() * 0.84 ))

    labels = capDiv.selectAll("div.labels")
        .data([tierData])
      .enter()
        .append('div')
            .attr("class", 'labels')

    topLabels = labels.append('div').attr('class', 'top-labels')
    topLabels.append('div').attr('class', 'resilience')
      .text((d) -> "n + #{d.resilience}")

    minResilience = 2
    mmx = true
    if mmx and tier.resilience >= minResilience and tier.timeToResilience?
      topLabels.append('div').attr('class', 'time-to-critical')
        .text((d) => "#{tier.timeToResilience.humanize()} until n + #{r-1}")

    topLabels.append('div').attr('class', 'free')
      .html((d) -> "<span class=\"value\">#{siBytesFormat(d.maxSize - d.currSize)}</span> free")

    topLabels.append('div').attr('class', 'node-info')
      .html((d) -> "<span class=\"value\">#{d.nodeCount}</span> nodes, <span class=\"value\">#{siBytesFormat(d.maxSize / d.nodeCount)}</span> each")

    topLabels.append('div').attr('class', 'maxSize')
      .html((d) -> "<span class=\"value\">#{siBytesFormat(d.maxSize)}</span> total")

    currSize = topLabels.append('div').attr('class', 'currSize')
    currSize.append('span').attr('class', 'size  value')
      .text((d) -> siBytesFormat(d.currSize))
    currSize.append('span').attr('class', 'percent')
      .text((d) -> " (#{percentFormat(d.utilization)}) ")
    currSize.append('span').attr('class', 'label')
      .text('used')

    if tier.weeklyDelta?

      bottomLabels = labels.append('div').attr('class', 'bottom-labels')
      growth = bottomLabels.append('div').attr('class', 'growth')

      growth.append('div').attr('class', 'last-week')
        .html("<span class=\"value\">#{siBytesPosFormat(@model.get('weeklyDelta').Bytes)}</span> (#{percentRoundFormat(@model.get('weeklyDelta').proportion)}) last week")

      if @model.get('weeklyDelta').Bytes > 0
        growth.append('div').attr('class', 'node-rate')
          .html((d) => "New node every <span class=\"value\">#{moment.duration((d.maxSize / d.nodeCount) / (@model.get('weeklyDelta').Bytes), 'weeks').humanize()}</span>")


app.directive 'tierNodes', ->
  restrict: 'E'
  link: ($scope, el) ->
    siBytesFormat = (n) ->
      return unless n?
      prefix = d3.formatPrefix(n, 3)
      "" + prefix.scale(d3.format('.3r')(n)) + " " + prefix.symbol + 'B'
    percentFormat = d3.format('.1%')

    [barWidth, barHeight] = [60, 14]

    table = d3.select(el[0]).append('table')

    x = d3.scale.linear()
      .domain([0, d3.max(_.pluck($scope.tier.nodes, 'maxSize'))])
      .range([0, barWidth])

    tbody= table.append('tbody')

    nodes = tbody.selectAll("tr.node")
        .data($scope.tier.nodes)
      .enter()
        .append("tr").attr('class', 'node')

    svgs = nodes.append('td').append('svg')
      .attr("width", barWidth)
      .attr("height", barHeight)

    svgs.append('rect').attr('class', 'maxSize')
      .attr("width", (d) -> x(d.maxSize))
      .attr("height", barHeight)

    svgs.append('rect').attr('class', 'currSize')
      .attr("width", (d) -> x(d.currSize))
      .attr("height", barHeight )

    svgs.append('text')
      .text((d) -> "#{percentFormat(d.utilization)}")
      .attr('x', '4px')
      .attr('y', barHeight / 2)

    nodeNames = nodes.append('td').attr('class', 'host')
      .attr('title', (d) -> "#{d.hostname}\nmaxSize: #{siBytesFormat(d.maxSize)}\ncurrSize: #{siBytesFormat(d.currSize, true)}")
      .text((d) -> d.hostname)


app.directive 'rulesTimeline', ($window, $filter, $compile) ->
  restrict: 'A'
  link: ($scope, $el) ->
    draw = ->
      rules = $scope.dataSource.rules.slice().reverse()
      $el.empty()
      chartWidth = $el.parent().width()
      [ruleTimeHeight, chartHeight, axisHeight] = [15, 36, 0]
      svgHeight = ruleTimeHeight + chartHeight + axisHeight
      replicantHeight = chartHeight / 2

      x = d3.time.scale.utc()
        .domain([
          moment.utc().subtract('months', 18).startOf('day').toDate(),
          moment.utc().toDate()
        ])
        .range([chartWidth, 0])
        .clamp(true)

      rules.forEach (r) ->
        r.width = x(r.momentInterval.start().toDate()) - x(r.momentInterval.end().toDate())

      lastYear = [
        moment.utc().subtract('years', 1).startOf('day').toDate(),
        moment.utc().endOf('day').toDate()
      ]

      svg = d3.select($el[0]).append('svg')
        .classed('with-footprint', $scope.dataSource.tiers?)
        .classed('rules-timeline', true)
        .attr("width", chartWidth)
        .attr("height", svgHeight)

      defs = svg.append('defs')
      randId = "drop-pattern-#{Math.floor(Math.random() * 1000000) + 1}"

      dropPattern = defs.append('pattern')
        .attr({
          id: randId
          patternUnits: "userSpaceOnUse"
          width: 16
          height: 32
          viewBox: "0 0 5 10"
        })
        .append('path')
        .attr({
          d: "M-2,1L7,10M-2,6L7,15M-2,-4L7,5"
          stroke: "#c6c631"
          "stroke-width": 0.5
          opacity: 0.5
        })

      rulesG = svg.append("g").attr("class", "rules")

      ruleGs = rulesG.selectAll("g.rule")
          .data(rules)
        .enter()
          .append("g").attr('class', "rule")
            .attr('transform', (d) -> "translate(#{Math.max(0, x( d.momentInterval.end().toDate()))},#{ruleTimeHeight})")

      loadGs = ruleGs.selectAll("g.load")
          .data((d) -> if d.direction is 'load' and d.momentInterval? then [d] else [])
        .enter()
          .append("g").attr('class', "load")

      tierGs = loadGs.selectAll("g.tier")
          .data((d, i) ->
            ({ tier, n, width: d.width } for tier, n of d.tieredReplicants) )
        .enter()
          .append("g")
          .attr('class', (d) -> "tier #{d.tier}")
          .attr('transform', (d, i) -> "translate(0,#{i * replicantHeight})")

      tierBars = tierGs.selectAll("rect")
          .data((d) -> [d])
        .enter()
          .append("rect")
          .attr('width', (d) -> d.width)
          .attr('height', (d) -> d.n * replicantHeight)

      dropGs = ruleGs.selectAll("g.drop")
          .data( (d) -> if d.direction is 'drop' then [d] else [])
        .enter()
          .append("g").attr('class', "drop")

      dropBars = dropGs.selectAll("rect")
          .data((d) -> [d])
        .enter()
          .append("rect")
          .attr('width', (d) -> x(d.momentInterval.start().toDate()) - x(d.momentInterval.end().toDate()))
          .attr('height', 2 * replicantHeight)
          .attr('fill', "url(##{randId})")

      dropText = dropGs.append("text")
          .attr('x', (d) -> d.width)
          .attr('y', replicantHeight)
          .attr('dx', '-0.25em')
          .attr('dy', '0.5em')
          .text((d) -> "drop")

      timeText = ruleGs.append("text")
          .attr('class', 'time')
          .attr('x', (d) -> d.width)
          .attr('dx', '-0.25em')
          .attr('dy', '-0.2em')
          .text((d) ->
            switch d.timeType
              when 'ByPeriod' then d.period
              when 'ByInterval' then $filter('simplifyInterval') d.interval, false
              when 'Forever' then 'forever'
          )

      tierText = tierGs.append("text")
          .attr('x', (d) -> d.width)
          .attr('y', (d) -> d.n * replicantHeight)
          .attr('dx', '-0.25em')
          .attr('dy', '-0.2em')
          .text((d) -> "#{$filter('tierName') d.tier}: #{d.n}")

      if $scope.dataSource.tiers?

        tiers = (tier for n, tier of $scope.dataSource.tiers)

        y = d3.scale.linear()
          .domain([0, d3.max(tiers, (t) -> d3.max(t.days, (d) -> d.size))])
          .range([0, replicantHeight])

        tierGs = svg.selectAll("g.footprint")
            .data(tiers)
          .enter()
            .append("g").attr('class', (d) -> "footprint #{d.tier}")
              .attr('transform', (d, i) -> "translate(0,#{ruleTimeHeight + (replicantHeight) * i})")

        dayBars = tierGs.selectAll("text")
            .data((d) -> [d])
          .enter()
            .append("text")
            .attr('transform', "translate(0,#{chartHeight * 0.75})")
            .text((d) -> "#{$filter('tierName') d.tier}: #{$filter('bytes') d.summary.size} in #{$filter('number') d.summary.count} segments")

        dayBars = tierGs.selectAll("rect.day")
            .data((d) -> d.days)
          .enter()
            .append("rect").attr('class', "day")
            .attr('x', (d) -> x d.endDate)
            .attr('width', (d) -> x(d.startDate) - x(d.endDate))
            .attr('y', (d) -> if d.tier is 'hot' then replicantHeight - y d.size else 0)
            .attr('height', (d) -> y d.size)
            .attr('tooltip-html-unsafe', (d) -> "#{d.day}<br/>#{$filter('bytes') d.size} in #{$filter('number') d.count} segments")
            .attr("tooltip-trigger", "mouseenter")
            .attr("tooltip-animation", false)
            .attr("tooltip-append-to-body", true)

      $el.removeAttr "rules-timeline"
      $compile($el)($scope)
      $el.attr "rules-timeline"

      console.log "Drew #{$scope.dataSource.id} after #{(new Date() - startTime)/ 1000}s"

    angular.element($window).bind 'resize', _.debounce(draw, 1000)
    $scope.$watch 'footprintsLoaded', -> draw()

    draw()


app.directive 'timeline', ($window, $filter, $compile) ->
  restrict: 'A'
  link: ($scope, $el) ->
    draw = ->
      days = $scope.days
      rules = $scope.dataSource.rules.slice().reverse()

      $el.empty()
      [ruleTimeHeight, chartHeight, axisHeight] = [15, 120, 15]
      chartWidth = $el.parent().width()

      replicantHeight = chartHeight / 2
      svgHeight = ruleTimeHeight + chartHeight + axisHeight

      x = d3.time.scale.utc()
        .domain([
          $scope.dataSummary.interval.end().valueOf(),
          $scope.dataSummary.interval.start().valueOf()
        ])
        .range([0, chartWidth])
        .clamp(true)

      rules.forEach (r) ->
        r.width = x(r.momentInterval.start().toDate()) - x(r.momentInterval.end().toDate())

      lastYear = [
        moment.utc().subtract('years', 1).startOf('day').toDate(),
        moment.utc().endOf('day').toDate()
      ]

      y = d3.scale.linear()
        .domain([0, d3.max(days, (d) -> d.size)])
        .range([0, chartHeight])

      svg = d3.select($el[0]).append('svg')
        .attr("width", chartWidth)
        .attr("height", svgHeight)
        .classed('timeline', true)

      defs = svg.append('defs')
      randId = "drop-pattern-#{Math.floor(Math.random() * 1000000) + 1}"

      dropPattern = defs.append('pattern')
        .attr({
          id: randId
          patternUnits: "userSpaceOnUse"
          width: 16
          height: 32
          viewBox: "0 0 5 10"
        })
        .append('path')
        .attr({
          d: "M-2,1L7,10M-2,6L7,15M-2,-4L7,5"
          stroke: "#c6c631"
          "stroke-width": 0.5
          opacity: 0.5
        })

      rulesG = svg.append("g").attr("class", "rules")

      ruleGs = rulesG.selectAll("g.rule")
          .data(rules)
        .enter()
          .append("g").attr('class', "rule")
            .attr('transform', (d) -> "translate(#{Math.max(0, x( d.momentInterval.end().toDate()))},#{ruleTimeHeight})")

      loadGs = ruleGs.selectAll("g.load")
          .data((d) -> if d.direction is 'load' and d.momentInterval? then [d] else [])
        .enter()
          .append("g").attr('class', "load")

      tierGs = loadGs.selectAll("g.tier")
          .data((d, i) ->
            ({ tier, n, width: d.width } for tier, n of d.tieredReplicants) )
        .enter()
          .append("g")
          .attr('class', (d) -> "tier #{d.tier}")
          .attr('transform', (d, i) -> "translate(0,#{i * replicantHeight})")

      tierBars = tierGs.selectAll("rect")
          .data((d) -> [d])
        .enter()
          .append("rect")
          .attr('width', (d) -> d.width)
          .attr('height', (d) -> d.n * replicantHeight)

      dropGs = ruleGs.selectAll("g.drop")
          .data( (d) -> if d.direction is 'drop' then [d] else [])
        .enter()
          .append("g").attr('class', "drop")

      dropBars = dropGs.selectAll("rect")
          .data((d) -> [d])
        .enter()
          .append("rect")
          .attr('width', (d) -> x(d.momentInterval.start().toDate()) - x(d.momentInterval.end().toDate()))
          .attr('height', 2 * replicantHeight)
          .attr('fill', "url(##{randId})")

      dropText = dropGs.append("text")
          .attr('x', (d) -> d.width)
          .attr('y', replicantHeight)
          .attr('dx', '-0.25em')
          .attr('dy', '0.5em')
          .text((d) -> "drop")

      timeText = ruleGs.append("text")
          .attr('class', 'time')
          .attr('x', (d) -> d.width)
          .attr('dx', '-0.25em')
          .attr('dy', '-0.2em')
          .text((d) ->
            switch d.timeType
              when 'ByPeriod' then d.period
              when 'ByInterval' then $filter('simplifyInterval') d.interval, false
              when 'Forever' then 'forever'
          )

      daysG = svg.append("g")
        .attr('class', (d) -> "days")
        .attr('transform', "translate(0,#{ruleTimeHeight})")

      dayBars = daysG.selectAll("rect.day")
          .data(days)
        .enter()
          .append("rect").attr('class', "day")
          .attr('x', (d) -> x d.endDate)
          .attr('width', (d) -> x(d.startDate) - x(d.endDate) )
          .attr('y', (d) -> chartHeight - y d.size)
          .attr('height', (d) -> y d.size)
          .attr('tooltip-html-unsafe', (d) -> "#{d.day}<br/>#{$filter('bytes') d.size} in #{$filter('number') d.count} segments")
          .attr("tooltip-trigger", "mouseenter")
          .attr("tooltip-animation", false)
          .attr("tooltip-append-to-body", true)

      console.log "Drew timeline after #{(new Date() - startTime)/ 1000}s"
      xAxis = d3.svg.axis().scale(x).tickSize(-chartHeight).tickSubdivide(true)

      svg.append("g")
          .attr("class", "x axis")
          .attr("transform", "translate(0,#{ruleTimeHeight + chartHeight})")
          .call(xAxis)

      $el.removeAttr "timeline"
      $compile($el)($scope)
      $el.attr "timeline"

    angular.element($window).bind 'resize', _.debounce(draw, 500)
    draw()


app.controller 'DruidClusterCtrl', ($scope, $druid, $q) ->
  $scope.env = $druid.env

  $druid.getNodes()
    .then (cluster) ->
      $scope.tiers = cluster.tiers
      $q.all([
        $druid.getLoadQueue($scope.tiers)
      ])

  $druid.getDataSources()
    .then (dataSources) ->
      $scope.dataSources = dataSources
      $druid.getLoadStatus($scope.dataSources)


app.controller 'DruidDataSourcesCtrl', ($scope, $druid, $q) ->
  $scope.env = $druid.env

  $scope.loadFootprints = (show) ->
    unless $scope.tiers
      $scope.footprintsLoading = true
      $druid.getTierNames()
        .then (tierNames) ->
          $scope.tierNames = tierNames
          tiers = {}
          for t in tierNames
            tiers[t] = $druid.getTierIntervals(t, $scope.dataSources)
          $q.all( tiers )
        .then (tiers) ->
          $scope.footprintsLoading = false
          $scope.footprintsLoaded = true
          $scope.tiers = tiers
          tiersArr = (t for n, t of tiers)
          $scope.clusterSummary =
            size: d3.sum tiersArr, (t) -> t.size
            count: d3.sum tiersArr, (t) -> t.count
            minTime: d3.min tiersArr, (t) -> t.minTime
            maxTime: d3.max tiersArr, (t) -> t.maxTime

  $scope.setEnabled = (status) ->
    $scope.enabled = status
    if status is 'disabled' and not $scope.disabledDataSources?
      $druid.getAllDataSources()
        .then (dataSources) ->
          $scope.allDataSources = dataSources
          $scope.disabledDataSources = dataSources.filter (ds) ->
            ds not in $scope.dataSources.map (d) -> d.id

  $druid.getDataSources()
    .then (dataSources) ->
      $scope.dataSources = dataSources
      $q.all(
        loadStatus: $druid.getLoadStatus($scope.dataSources)
        rules: $druid.getAllRules($scope.dataSources)
      )
    .then (results) ->
      $scope.defaultRules = results.rules._default

  unless $scope.tierNames
    $druid.getTierNames().then (tierNames) ->
      $scope.tierNames = tierNames

app.controller 'DruidDataSourceCtrl', ($scope, $druid, $stateParams, $q) ->
  $scope.env = $druid.env
  $scope.dataSource = {id: $stateParams.id}

  $scope.segUrl = (segId) ->
    $druid.proxy "/datasources/#{$scope.dataSource.id}/segments/#{segId}"

  $scope.selectInterval = (interval) ->
    delete $scope.selectedSegments
    $scope.selectedInterval = interval

    unless $scope.serverTiers?
      $druid.getServerTiers()
        .then (serverTiers) ->
          $scope.serverTiers = serverTiers

    $druid.getSegmentsForInterval($scope.dataSource.id, $scope.selectedInterval.interval)
      .then (segments) ->
        $scope.selectedSegments = segments

  $scope.getDaily = ->
    console.log 'getDaily'
    return ({
      day: d.day
      size: d.size
      count: d.count
      start: d.startDate.toISOString()
      end: d.endDate.toISOString()
    } for d in $scope.days)

  $scope.getMonthly = ->
    console.log 'getMonthly'
    months = ({
      month: m.month
      size: m.size
      count: m.count
      start: (new Date(m.start)).toISOString()
      end: (new Date(m.end)).toISOString()
    } for i, m of $scope.days.reduce(((months, d) ->
      m = d.day.substr(0,7)
      months[m] ?= {
        month: m
        size: 0
        count: 0
        start: d.startDate
        end: d.endDate
      }
      month = months[m]
      month.size += d.size
      month.count += d.count
      month.start = Math.min(d.startDate, month.start)
      month.end = Math.min(d.endDate, month.end)
      months
    ), {}))
    return months

  $scope.s3Path = (seg) ->
    "s3://#{seg.loadSpec.bucket}/#{seg.loadSpec.key}"

  $druid.getDataSource($scope.dataSource.id)
    .then (dataSource) ->
      angular.extend $scope.dataSource, dataSource

  $druid.getRules($scope.dataSource.id)
    .then (rules) ->
      $scope.dataSource.rules = rules
      $druid.getDataSourceIntervals($scope.dataSource.id)
    .then (results) ->
      $scope.intervals = results.intervals
      $scope.days = results.days
      $scope.dataSummary = results.summary
      $scope.unreplicatedSegmentSize = d3.sum(results.intervals, (i) -> i.size)

  $druid.getRules('_default')
    .then (defaultRules) ->
      rule.default = true for rule in defaultRules
      $scope.defaultRules = defaultRules

  unless $scope.tierNames
    $druid.getTierNames().then (tierNames) ->
      $scope.tierNames = tierNames


app.controller 'RuleEditorCtrl', ($scope, $modal, $druid, $utils) ->

  $scope.open = ->
    modalInstance = $modal.open(
      templateUrl: '/pages/rules.html'
      controller: RuleEditorInstanceCtrl
      resolve:
        originalRules: -> angular.copy $scope.dataSource.rules
        dataSourceId: -> $scope.dataSource.id
        tierNames: -> $scope.tierNames
        '$druid': -> $druid
    )
    modalInstance.result.then ( (newRules) ->
      console.log "getting new rules for", $scope.dataSource.id
      $scope.dataSource.rules = $utils.processRules(newRules)
    ), ->
      console.log "modal dismissed"
      return

    return


RuleEditorInstanceCtrl = ($scope, $modalInstance, originalRules, dataSourceId, tierNames, $druid) ->
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
    return rule.direction == 'load' and _.isEmpty rule.tieredReplicants

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
    $druid.saveRules($scope.dataSourceId, rulesToSave)
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


app.controller 'DataSourceDisableCtrl', ($scope, $modal, $druid, $utils, $location) ->
  $scope.open = ->
    modalInstance = $modal.open(
      templateUrl: '/pages/disable.html'
      controller: DataSourceDisableInstanceCtrl
      size: 'sm'
      resolve:
        dataSourceId: -> $scope.dataSource.id
        '$druid': -> $druid
    )
    modalInstance.result.then ( ->
      $location.path "/#{$scope.env}/datasources"
    ), ->
      console.log "modal dismissed"
      return

    return


DataSourceDisableInstanceCtrl = ($scope, $modalInstance, dataSourceId, $druid) ->
  $scope.dataSourceId = dataSourceId

  $scope.confirm = ->
    console.log "disabling #{$scope.dataSourceId}"
    $scope.loading = true
    $druid.disableDataSource($scope.dataSourceId)
      .then (() ->
        $modalInstance.close()
      ), ((reason) ->
        $scope.postError = reason
      )
    return

  $scope.cancel = ->
    $modalInstance.dismiss "cancel"
    return

  return


app.controller 'DataSourceEnableCtrl', ($scope, $modal, $druid, $utils, $location) ->
  $scope.open = ->
    modalInstance = $modal.open(
      # templateUrl: '/pages/disable.html'
      template: '
        <div class="modal-body">
          <span class="fa fa-cog fa-spin fa-2x" ng-show="loading"></span>
          <button class="btn btn-primary" ng-click="confirm()" ng-disabled="loading">Enable {{ dataSourceId }}</button>
          <button class="btn btn-default" ng-click="cancel()" ng-disabled="loading">Never mind...</button>
        </div>'
      controller: DataSourceEnableInstanceCtrl
      size: 'sm'
      resolve:
        dataSourceId: -> $scope.dataSourceId
        '$druid': -> $druid
    )
    modalInstance.result.then ( ->
      $location.path "/#{$scope.env}/datasources/#{$scope.dataSourceId}";
    ), ->
      console.log "modal dismissed"
      return

    return


DataSourceEnableInstanceCtrl = ($scope, $modalInstance, dataSourceId, $druid) ->
  $scope.dataSourceId = dataSourceId

  $scope.confirm = ->
    console.log "enabling #{$scope.dataSourceId}"
    $scope.loading = true
    $druid.enableDataSource($scope.dataSourceId)
      .then (() ->
        $modalInstance.close()
      ), ((reason) ->
        $scope.postError = reason
      )
    return

  $scope.cancel = ->
    $modalInstance.dismiss "cancel"
    return

  return

app.controller 'ClusterConfigCtrl', ($scope, $modal, $druid, $utils, $location) ->
  $scope.open = ->
    modalInstance = $modal.open(
      # templateUrl: '/pages/disable.html'
      template: '
        <div class="cluster-config">
          <div class="modal-header">
              <h1>Edit Cluster Config</h1>
          </div>
          <div class="modal-body">
            <span class="fa fa-cog fa-spin fa-2x" ng-show="loading"></span>
            <table>
              <tr ng-repeat="(key, val) in config">
                <td class="key">{{ key }}</td>
                <td class="val">
                  <input ng-model="config[key]">
                </td>
              </td>
            </table>
            <alert type="danger" ng-show="postError">{{postError}}</alert>
          </div>
          <div class="modal-footer">
            <button class="btn btn-danger" ng-click="cancel()" ng-disabled="loading">Cancel</button>
            <button class="btn btn-primary" ng-click="save()" ng-disabled="loading">Save</button>
          </div>
        </div>'
      controller: ClusterConfigInstanceCtrl
      size: 'sm'
      resolve:
        '$druid': -> $druid
    )

    return


ClusterConfigInstanceCtrl = ($scope, $modalInstance, $druid) ->
  $scope.loading = true

  $druid.getClusterConfig()
    .then (config) ->
      $scope.config = config
      $scope.loading = false

  $scope.save = ->
    console.log "saving config"
    if confirm("Do you really want to update the cluster configuration?")
      $scope.loading = true
      console.log '$scope.config', $scope.config
      $druid.saveClusterConfig($scope.config)
        .then (() ->
          $modalInstance.close()
        ), ((reason) ->
          $scope.postError = reason
          console.log reason
        )
      return

  $scope.cancel = ->
    $modalInstance.dismiss "cancel"
    return

  return
