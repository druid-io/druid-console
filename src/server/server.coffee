express = require 'express'
path = require 'path'
request = require 'request'
url = require 'url'
httpProxy = require 'http-proxy'
dns = require 'dns'
{ SimpleLocator, ZookeeperLocator } = require 'locators'

app = express()

zkHostname = process.env.ZK_HOSTNAME
zkDiscovery = null

getZkDruidCoordinator = (req) -> "druid:#{req.params.cluster}:master"
getZkDruidIndexer = (req) -> "druid:#{req.params.cluster}:indexer"
getZkDruidBard = (req) -> "druid:#{req.params.cluster}:bard"

getDruidLocator = (druidZkLocation) ->
  zkDiscovery(druidZkLocation)()

dns.resolve4 zkHostname, (err, addresses) ->
  throw err if err
  console.log "#{zkHostname} resolved to #{addresses.length} ZK node IP addresses: #{addresses.join(', ')}"
  zkLocator = SimpleLocator.getLocatorFactory()(zkHostname)
  zkDiscovery = ZookeeperLocator.getLocatorFactory({
    serverLocator: zkLocator,
    path: process.env.ZK_SERVICE_DISC_PATH
  })

proxy = new httpProxy.createProxyServer({})

proxy.on 'error', (e) ->
  console.log "proxy error: ", e

rootPath = path.normalize(path.join(__dirname, '/../../') )

app.use(express.logger('dev'))

app.all '/pass/coordinator/:cluster*', (req, res) ->
  req.url = req.url.replace(/\/pass\/coordinator\/[^\/]+\//, '/')
  zkDruidCoordinator = getZkDruidCoordinator(req)
  getDruidLocator(zkDruidCoordinator).then((loc) =>
    console.log "Proxying to druid coordinator at #{getHttpHostAndPort(loc)}#{req.url}"

    doOnCoordinator loc, res, (coordHostPort) =>
      target = if coordHostPort.indexOf("http") < 0 then "http://#{coordHostPort}" else coordHostPort
      proxy.web req, res, {target}
  ).catch((err) ->
    console.log "can't find #{zkDruidCoordinator}", err
    res.send(500, { error: "can't find #{zkDruidCoordinator}, #{err}" })
  )

app.all '/pass/indexer/:cluster*', (req, res) ->
  req.url = req.url.replace(/\/pass\/indexer\/[^\/]+\//, '/')
  zkDruidIndexer = getZkDruidIndexer(req)
  getDruidLocator(zkDruidIndexer).then((loc) ->
    target = getHttpHostAndPort(loc)
    console.log "Proxying to indexer at #{target}#{req.url}"
    proxy.web req, res, {target}
  ).catch((err) ->
    console.log "can't find #{zkDruidIndexer}", err
    res.send(500, { error: "can't find #{zkDruidIndexer}, #{err}" })
  )

app.get '/pass/bard/:cluster*', (req, res) ->
  req.url = req.url.replace(/\/pass\/bard\/[^\/]+\//, '/')
  zkDruidBard = getZkDruidBard(req)
  getDruidLocator(zkDruidBard).then((loc) ->
    target = getHttpHostAndPort(loc)
    console.log "Proxying to bard at #{target}#{req.url}"
    proxy.web req, res, {target}
  ).catch((err) ->
    console.log "can't find #{zkDruidBard}", err
    res.send(500, { error: "can't find #{zkDruidBard} - #{err}" })
  )

app.use(express.cookieParser())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(express.compress())
app.use(express.json())

oneDay = 86400000
oneYear = oneDay * 365
app.use(express.static(path.join(rootPath, 'static'), { maxAge: oneYear }))
app.use(express.static(path.join(rootPath, 'build')))
app.use('/fonts', express.static(path.join(rootPath, 'bower_components/font-awesome/fonts')))
app.use('/css', express.static(path.join(rootPath, 'bower_components/font-awesome/css')))
app.use('/css', express.static(path.join(rootPath, 'bower_components/bootstrap/dist/css')))

app.disable('x-powered-by')

getHttpHostAndPort = (loc) ->
  targetHost = if loc.host.indexOf("http") < 0 then "http://#{loc.host}" else loc.host
  return "#{targetHost}:#{loc.port}"

handleError = (res, statusCode, msg, err) ->
  console.log 'ERROR', msg, err
  res.send(statusCode, { msg: msg, error: err })

respondWithResult = (res) -> (err, result) ->
  if err
    res.json(500, err)
    return
  res.json(result)
  return

doOnCoordinator = (location, res, cb) ->
  request({
    url: "#{getHttpHostAndPort(location)}/druid/coordinator/v1/leader"
  }, (error, response, coordHostPort) =>
    return handleError(res, 500, 'finding coordinator', error) if error or response.statusCode != 200
    cb(coordHostPort)
  )

app.get '/', (req, res) ->
  res.redirect '/console/prod'

app.get '/console*', (req, res) ->
  res.sendfile(path.join(rootPath, 'static/console.html'))

app.get '/coordinator/:cluster', (req, res) ->
  zkDruidCoordinator = getZkDruidCoordinator(req)
  getDruidLocator(zkDruidCoordinator).then((loc) ->
    res.send loc
  ).catch((err) ->
    console.log "can't find #{zkDruidCoordinator}", err
    res.send(500, { error: "can't find #{zkDruidCoordinator}, #{err}" })
  )

app.get '/overlord/:cluster', (req, res) ->
  zkDruidIndexer = getZkDruidIndexer(req)
  getDruidLocator(zkDruidIndexer).then((loc) ->
    res.send loc
  ).catch((err) ->
    console.log "can't find #{zkDruidIndexer}", err
    res.send(500, { error: "can't find #{zkDruidIndexer}, #{err}" })
  )

port = if /^\d+$/.test process.argv[2] then parseInt(process.argv[2]) else 8080

app.all '/health', (req, res) -> res.send 'OK'

app.listen(port)
console.log("Listening on port #{port}")
