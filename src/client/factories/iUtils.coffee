moment = require '../../../bower_components/moment/min/moment.min.js'

module.exports = ->
  parseTaskId: (taskId) ->
    m = taskId.match /^((hadoop_convert_segment)|index_(hadoop|realtime|spark)|(archive))_(.+)_(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}Z)/
    type = m[3]
    type ||= m[2]
    throw Error("Can't parse #{taskId}") unless m
    {
      id: taskId
      type
      dataSource: m[4]
      dataTime: m[5]
    }

  decorateTask: (task) ->
    angular.extend(task, @parseTaskId task.id)
    task.dataDate = new Date(task.dataTime) if task.dataTime?
    task.createdDate = new Date(task.createdTime) if task.createdTime?
    task.insertedDate = new Date(task.queueInsertionTime) if task.queueInsertionTime?
    task.dataMoment = moment.utc(task.dataDate) if task.dataDate?
    task.createdMoment = moment.utc(task.createdDate) if task.createdDate?
    task.insertedMoment = moment.utc(task.insertedDate) if task.insertedDate?
    task

  processTasks: (tasks) ->
    processedTasks = tasks.reduce(((types, task) =>
      task = @decorateTask task
      types[task.type] ||= []
      types[task.type].push task
      types.all.push task
      return types
    ), {all: []})
    processedTasks.all.sort (a, b) -> b.dataDate - a.dataDate
    processedTasks

  processAuditItem: (auditItem) ->
    auditItem.payloadParsed = JSON.parse auditItem.payload
    auditItem.timeMoment = moment.utc(auditItem.auditTime)
    return auditItem

  processConfigHistory: (ruleChanges) ->
    ruleChanges.reverse().forEach (c) => @processAuditItem c
    return ruleChanges
