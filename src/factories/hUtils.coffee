require '../../../bower_components/d3/d3.js'
require '../../../bower_components/zeroclipboard/ZeroClipboard.min.js'

require '../../../bower_components/angular/angular.min.js'
require '../../../bower_components/angular-ui-router/release/angular-ui-router.min.js'
require '../../../bower_components/angular-sanitize/angular-sanitize.min.js'
require '../../../bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js'
require '../../../bower_components/ng-clip/dest/ng-clip.min.js'
require '../../../bower_components/ng-csv/build/ng-csv.min.js'

_ = require '../../../bower_components/underscore/underscore.js'
moment = require '../../../bower_components/moment/min/moment.min.js'
require '../../../lib/moment-interval.js'

module.exports = ->

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
        throw Error("Don't know what to do with this node")

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
    dataSource.segments.interval = moment.interval(
      "#{dataSource.segments.minTime}/#{dataSource.segments.maxTime}}"
    )
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
      tier.loadQueueLoaded = true
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

      og = _.find dataSources.filter((d) -> d.id is ds)[0]
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
