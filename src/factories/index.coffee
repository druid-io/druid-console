app = angular.module 'druid'

app.factory '$historical', require('./historical.coffee')
app.factory '$hUtils', require('./hUtils.coffee')
app.factory '$indexing', require('./indexing.coffee')
app.factory '$iUtils', require('./iUtils.coffee')

