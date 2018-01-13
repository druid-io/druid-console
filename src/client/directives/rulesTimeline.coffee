_ = require '../../../bower_components/underscore/underscore.js'
moment = require '../../../bower_components/moment/min/moment.min.js'
require '../../../lib/moment-interval.js'
d3 = require '../../../bower_components/d3/d3.js'

module.exports = ($window, $filter, $compile) ->
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
          moment.utc().subtract(18, 'months').startOf('day').toDate(),
          moment.utc().toDate()
        ])
        .range([chartWidth, 0])
        .clamp(true)

      rules.forEach (r) ->
        r.width = x(r.momentInterval.start().toDate()) - x(r.momentInterval.end().toDate())

      lastYear = [
        moment.utc().subtract(1, 'years').startOf('day').toDate(),
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

    angular.element($window).bind 'resize', _.debounce(draw, 1000)
    $scope.$watch 'footprintsLoaded', -> draw()

    draw()
