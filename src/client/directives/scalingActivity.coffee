d3 = require '../../../bower_components/d3/d3.js'

module.exports = ->
  restrict: 'E'
  replace: true
  scope: {
    scaling: '=scaling'
    workers: '=workers'
  }
  template: '<svg class="scaling-activity" width="100%" preserveAspectRatio="xMidYMid meet"></svg>'

  link: (scope, el) ->
    [chartHeight, axisHeight] = [80, 20]
    viewBoxWidth = 720
    markRadius = 1
    [width, height] = [200, chartHeight + axisHeight + markRadius]

    svg = d3.select(el[0]).attr({
      viewBox: "0 0 #{viewBoxWidth} #{height}"
    })

    historyAreaG = svg.append("g")
      .attr(
        transform: "translate(0,#{markRadius})"
      )

    eventsG = svg.append("g").attr(
      class: "events"
    )

    axisG = svg.append("g").attr(
      class: "axis"
      transform: "translate(0,#{chartHeight + markRadius})"
    )

    x = null
    y = null

    historyArea = d3.svg.area()
      .x((d) -> x(d.date))
      .y0(chartHeight)
      .y1((d) -> y(d.count))
      .interpolate('step-after')

    updateScalesAndAxes = (scaling, workerHistory) ->
      x = d3.time.scale.utc()
        .domain([new Date(), d3.min(scaling, (s) -> s.date)])
        .range([markRadius, viewBoxWidth - (markRadius) * 2])

      xAxis = d3.svg.axis()
        .scale(x)
        .orient("bottom")

      y = d3.scale.linear()
        .domain([0, d3.max(workerHistory, (d) -> d.count)])
        .range([chartHeight, 0])

      axisG.call(xAxis)

    updateScaling = (scaling, workerHistory) ->

      historyAreaG.append("path")
        .data([workerHistory])
        .attr({
          class: "history"
          d: historyArea
        })

      eventsSel = eventsG.selectAll("line.event")
        .data(scaling)

      eventsSel.enter()
        .append("line")
        .attr({
          class: (d) -> "event #{d.event}"
        })
        .append("title")
          .text((d) ->
            "#{d.event} #{d.data.nodeIds.length} node(s)\n\nat #{d.timestamp}"
          )
      eventsSel
        .attr({
          x1: (d) -> x(d.date)
          x2: (d) -> x(d.date)
          y1: (d) -> y(d.countBefore)
          y2: (d) -> y(d.countBefore - d.delta)
        })

      eventsSel.exit().remove()


    scope.$watchCollection(
      '[scaling, workers]'
      ([scaling, workers]) ->

        return unless scope.scaling? and scope.workers?

        scaling = scope.scaling

        workerHistory = scaling.reduce(((workerHistory, s) ->
          delta = if s.event == "PROVISION"
              - s.data.nodeIds.length
            else
              s.data.nodeIds.length
          count = workerHistory[workerHistory.length - 1].count + delta
          workerHistory.push {
            count
            date: s.date
            s
          }
          s.countBefore = count
          s.delta = delta
          workerHistory
        ), [{count: workers.length, date: new Date}])

        updateScalesAndAxes(scaling, workerHistory)
        updateScaling(scaling, workerHistory)


    )

