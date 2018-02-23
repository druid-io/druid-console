iUtilsFactory = require '../../../src/client/factories/iUtils.coffee'

describe '$iUtils', () ->
  $iUtils = undefined
  $taskTimestamp = '2018-01-01T10:20:30.400Z'

  beforeEach ->
    $iUtils = iUtilsFactory()

  it 'should have a defined $iUtils', () ->
    expect($iUtils?).toBeTruthy()

  describe 'parseTaskId', () ->
    it 'should parse hadoop_convert task', () ->
      task = $iUtils.parseTaskId('hadoop_convert_segment_wikipedia_' + $taskTimestamp)
      expect(task).toEqual({
        id: 'hadoop_convert_segment_wikipedia_' + $taskTimestamp
        type: 'hadoop_convert_segment'
        dataSource: 'wikipedia'
        dataTime: $taskTimestamp
      })

    it 'should parse index_hadoop task', () ->
      task = $iUtils.parseTaskId('index_hadoop_twitter_' + $taskTimestamp)
      expect(task).toEqual({
        id: 'index_hadoop_twitter_' + $taskTimestamp
        type: 'hadoop'
        dataSource: 'twitter'
        dataTime: $taskTimestamp
      })

    it 'should parse index_realtime task', () ->
      task = $iUtils.parseTaskId('index_realtime_twitter_' + $taskTimestamp)
      expect(task).toEqual({
        id: 'index_realtime_twitter_' + $taskTimestamp
        type: 'realtime'
        dataSource: 'twitter'
        dataTime: $taskTimestamp
      })

    it 'should parse index_spark task', () ->
      task = $iUtils.parseTaskId('index_spark_twitter_' + $taskTimestamp)
      expect(task).toEqual({
        id: 'index_spark_twitter_' + $taskTimestamp
        type: 'spark'
        dataSource: 'twitter'
        dataTime: $taskTimestamp
      })

    it 'should parse archive task', () ->
      task = $iUtils.parseTaskId('archive_wikipedia_' + $taskTimestamp)
      expect(task).toEqual({
        id: 'archive_wikipedia_' + $taskTimestamp
        type: 'archive'
        dataSource: 'wikipedia'
        dataTime: $taskTimestamp
      })

    it 'should not throw an error if taskId does not match expected pattern', () ->
      task = $iUtils.parseTaskId('index_kafka_twitter_1675e770de9a423_hfdhgjko')
      expect(task).toEqual({
        id: 'index_kafka_twitter_1675e770de9a423_hfdhgjko'
        type: 'other'
        dataSource: undefined
        dataTime: undefined
      })
