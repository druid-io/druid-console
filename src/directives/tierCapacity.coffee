moment = require '../../../bower_components/moment/min/moment.min.js'

module.exports = ->
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

    maxSize = topLabels.append('div').attr('class', 'maxSize')
    maxSize.append('span').attr('class', 'size  value')
      .text((d) -> siBytesFormat(d.maxSize))
    maxSize.append('span').attr('class', 'size-label')
      .text(' total')

    currSize = topLabels.append('div').attr('class', 'currSize')
      .html((d) ->
        "<span class=\"size value\">#{siBytesFormat(d.currSize)}</span>" +
        " (<span class=\"percent\">#{percentFormat(d.utilization)}</span>)" +
        " <span class=\"size-label\"> used</span>"
      )

    # currSize.append('span').attr('class', 'size  value')
    #   .text((d) -> siBytesFormat(d.currSize))
    # currSize.append('span').attr('class', 'percent')
    #   .text((d) -> " (#{percentFormat(d.utilization)})")
    # currSize.append('span').attr('class', 'size-label')
    #   .text(' used')

    if tier.weeklyDelta?

      bottomLabels = labels.append('div').attr('class', 'bottom-labels')
      growth = bottomLabels.append('div').attr('class', 'growth')

      growth.append('div').attr('class', 'last-week')
        .html("<span class=\"value\">#{siBytesPosFormat(@model.get('weeklyDelta').Bytes)}</span> (#{percentRoundFormat(@model.get('weeklyDelta').proportion)}) last week")

      if @model.get('weeklyDelta').Bytes > 0
        growth.append('div').attr('class', 'node-rate')
          .html((d) => "New node every <span class=\"value\">#{moment.duration((d.maxSize / d.nodeCount) / (@model.get('weeklyDelta').Bytes), 'weeks').humanize()}</span>")
