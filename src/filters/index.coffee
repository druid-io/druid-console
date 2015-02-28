_ = require '../../../bower_components/underscore/underscore.js'

app = angular.module 'druid'

app.filter 'startsWith', () ->
  (items, prefix) ->
    return items unless prefix?.length > 0
    filtered = []
    angular.forEach items, (item) ->
      filtered.push(item) if (item.interval.indexOf prefix) is 0
    filtered

app.filter 'bytes', () ->
  (n) ->
    return unless n?
    prefix = d3.formatPrefix(n, 3)
    "" + prefix.scale(d3.format('.3r')(n)) + " " + prefix.symbol + 'B'

app.filter 'percentRound', () ->
  (n) ->
    return unless n?
    d3.format('.2p')(n)

app.filter 'tierName', () ->
  (n) -> if n is '_default_tier' then 'cold' else n

app.filter 'commasToSpaces', () ->
  (x) ->
    x.replace /,/g, ' '

app.filter 'availableTiers', () ->
  (x, $scope) ->
    x.filter (x) -> x not of $scope.rule.tieredReplicants

app.filter 'simplifyInterval', ($sce) ->
  (x, html) ->
    html ?= true
    [timeSep, intervalSep] = if html
      ['<span class="time-sep">T</span>', '<span class="interval-sep">/</span>']
    else
      ['T', '/']

    intervalRe = /(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2}).(\d{3})Z\/(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2}).(\d{3})Z/
    m = x.match intervalRe
    throw "#{x} is not a valid interval" unless m

    simplified = [ [5,4,3,2], [10,9,8,7] ].map( (idx, j) ->
      date = m[j * 5 + 1]
      nonZero = _.find idx, (i) -> parseInt(m[i]) isnt 0
      switch nonZero
        when undefined then date
        when idx[3] then "#{date}#{timeSep}#{m[idx[3]]}"
        when idx[2] then "#{date}#{timeSep}#{m[idx[3]]}:#{m[idx[2]]}"
        when idx[1] then "#{date}#{timeSep}#{m[idx[3]]}:#{m[idx[2]]}:#{m[idx[1]]}"
        when idx[0] then "#{date}#{timeSep}#{m[idx[3]]}:#{m[idx[2]]}:#{m[idx[1]]}.#{m[idx[0]]}Z"
    ).join(intervalSep)

    return $sce.trustAsHtml(simplified)

app.filter 'isoHour', () ->
  (t) ->
    "#{t.substring(0,10)}<span class=\"sep\">T</span>#{t.substring(11,13)}"
