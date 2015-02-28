module.exports = ->
  parseTaskId: (taskId) ->
    m = taskId.match /^index_(hadoop|realtime)_(.+)_(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}Z)/
    throw Error("Can't parse #{taskId}") unless m
    {
      id: taskId
      type: m[1]
      dataSource: m[2]
      dataTime: m[3]
      dataDate: new Date(m[3])
    }

  decorateTask: (task) ->
    angular.extend(task, @parseTaskId task.id)
    task.createdDate = new Date(task.createdTime) if task.createdTime?
    task.insertedDate = new Date(task.queueInsertionTime) if task.queueInsertionTime?
    task

  processTasks: (tasks) ->
    tasks.reduce(((types, task) =>
      task = @decorateTask task
      types[task.type] ?= []
      types[task.type].push task
      return types
    ), {realtime: [], hadoop: []})
