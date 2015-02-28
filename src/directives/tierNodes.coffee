module.exports = ->
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
      .domain([0, d3.max($scope.tier.nodes, (d) -> d.maxSize)])
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
