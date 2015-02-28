module.exports = ->
  restrict: 'E'
  replace: true
  scope: {
    tasks: '=tasks'
  }
  template: '<svg class="running-tasks" width="100%" preserveAspectRatio="xMidYMid meet"></svg>'

  link: (scope, el) ->
    scope.$watchCollection(
      '[tasks]'
      ([tasks]) ->
        return unless scope.tasks?

        tasks = scope.tasks
        dataSources = d3.set(tasks.map((t) -> t.dataSource)).values()

        [chartHeight, axisHeight] = [120, 20]
        viewBoxWidth = 720
        markRadius = 4
        [width, height] = [200, chartHeight + axisHeight + markRadius]

        dateAttr = 'createdDate'
        x = d3.time.scale.utc()
          .domain(d3.extent(tasks, (t) -> t[dateAttr]).reverse())
          .range([markRadius, viewBoxWidth - (markRadius) * 2])

        color = d3.scale.category20()
          .domain(dataSources)

        svg = d3.select(el[0]).attr({
          viewBox: "0 0 #{viewBoxWidth} #{height}"
        })

        xAxis = d3.svg.axis()
          .scale(x)
          .orient("bottom")

        axisG = svg.append("g").attr(
          class: "axis"
          transform: "translate(0,#{chartHeight + markRadius})"
        )
          .call(xAxis);


        tasksG = svg.append("g").attr(
          class: "tasks"
          transform: "translate(0,#{markRadius})"
        )

        tasks = tasksG.selectAll("circle.task").data(tasks)

        tasks.enter().append("circle").attr({
          class: "task"
          r: markRadius
          cx: (d) -> x(d[dateAttr])
          cy: -> Math.random() * chartHeight
          fill: (d) -> color(d.dataSource)
        })
          .append("title")
            .text((d) ->
              "#{d.dataSource} (#{d.dataTime.substr(0,16)})" +
                "\n#{d.id}"
            )
    )
