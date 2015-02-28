_ = require '../../../bower_components/underscore/underscore.js'
moment = require '../../../bower_components/moment/min/moment.min.js'

module.exports = ($window, $filter, $compile) ->
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
