d3 = require '../../../bower_components/d3/d3.js'

module.exports = ->
  restrict: 'E'
  replace: true
  scope: {
    tasks: '=tasks'
  }
  template: '<svg class="running-tasks" width="100%" preserveAspectRatio="xMidYMid meet"></svg>'

  link: (scope, el) ->

    [chartHeight, axisHeight] = [120, 20]
    viewBoxWidth = 720
    markRadius = 4
    [width, height] = [200, chartHeight + axisHeight + markRadius]

    dateAttr = 'createdDate'

    svg = d3.select(el[0]).attr({
      viewBox: "0 0 #{viewBoxWidth} #{height}"
    })

    tasksG = svg.append("g").attr(
      class: "tasks"
    )

    axisG = svg.append("g").attr(
      class: "axis"
      transform: "translate(0,#{chartHeight + markRadius})"
    )

    x = null
    color = null

    taskIdYMap = {}

    updateScalesAndAxes = (tasks, dataSources) ->
      x = d3.time.scale.utc()
        .domain(d3.extent(tasks, (t) -> t[dateAttr]).reverse())
        .range([markRadius, viewBoxWidth - (markRadius) * 2])

      color = d3.scale.category20()
        .domain(dataSources)

      xAxis = d3.svg.axis()
        .scale(x)
        .orient("bottom")

      axisG.call(xAxis)

    updateTasks = (tasks) ->
      tasksSel = tasksG.selectAll("circle.task")
        .data(tasks, (d) -> d.id)

      tasksSel.enter().append("circle")
        .attr({
          class: "task"
          fill: (d) -> color(d.dataSource)
        })
        .append("title")
          .text((d) ->
            "#{d.dataSource} (#{d.dataTime.substr(0,16)})" +
              "\n#{d.id}"
          )

      tasksSel # update
        .attr({
          r: markRadius
          cx: (d) -> x(d[dateAttr])
          cy: (d) -> taskIdYMap[d.id]

        })

      tasksSel.exit().remove()


    scope.$watchCollection(
      '[tasks]'
      ([tasks]) ->
        return unless scope.tasks?

        tasks = scope.tasks
        newTaskIdYMap = {}
        tasks.forEach (t) ->
          newTaskIdYMap[t.id] = if t.id of taskIdYMap then taskIdYMap[t.id] else markRadius + Math.random() * (chartHeight - 2 * markRadius)
        taskIdYMap = newTaskIdYMap
        dataSources = d3.set(tasks.map((t) -> t.dataSource)).values()

        updateScalesAndAxes(tasks, dataSources)
        updateTasks(tasks)
    )
