express = require('express')
bodyParser = require('body-parser')
compression = require('compression')
cookieParser = require('cookie-parser')
dns = require('dns')
httpProxy = require('http-proxy')
logger = require('morgan')
methodOverride = require('method-override')
path = require('path')
request = require('request')
url = require('url')
{ SimpleLocator, ZookeeperLocator } = require('locators')


# helper methods
getZkDruidCoordinator = (req) -> "druid:#{req.params.cluster}:master"
getZkDruidIndexer = (req) -> "druid:#{req.params.cluster}:indexer"
getZkDruidBard = (req) -> "druid:#{req.params.cluster}:bard"

getDruidLocator = (druidZkLocation) ->
  zkDiscovery(druidZkLocation)()

getHttpHostAndPort = (loc) ->
  targetHost = if loc.host.indexOf("http") < 0 then "http://#{loc.host}" else loc.host
  return "#{targetHost}:#{loc.port}"

handleError = (res, statusCode, msg, err) ->
  console.log('ERROR', msg, err)
  res.status(statusCode).send({ msg: msg, error: err })

respondWithResult =
  (res) ->
    (err, result) ->
      if err
        res.status(500).json(err)
        return
      res.status(200).json(result)
    return

doOnCoordinator = (location, res, cb) ->
  request({
    url: "#{getHttpHostAndPort(location)}/druid/coordinator/v1/leader"
  }, (error, response, coordHostPort) =>
    return handleError(res, 500, 'finding coordinator', error) if error or response.statusCode != 200
    cb(coordHostPort)
  )

# initialization
console.log('Initializing druid-console server...')

oneDay = 86400000
oneYear = oneDay * 365

zkHostname = process.env.ZK_HOSTNAME
zkDiscovery = null

proxy = new httpProxy.createProxyServer({})

proxy.on('error', (e) ->
  console.log("proxy error: ", e)
)

rootPath = path.normalize(path.join(__dirname, '/../../'))

app = express()

app.use(logger('dev'))

app.all('/pass/coordinator/:cluster*', (req, res) ->
  req.url = req.url.replace(/\/pass\/coordinator\/[^\/]+\//, '/')
  zkDruidCoordinator = getZkDruidCoordinator(req)
  getDruidLocator(zkDruidCoordinator).then((loc) =>
    console.log("Proxying to druid coordinator at #{getHttpHostAndPort(loc)}#{req.url}")

    doOnCoordinator(loc, res, (coordHostPort) =>
      target = if coordHostPort.indexOf("http") < 0 then "http://#{coordHostPort}" else coordHostPort
      proxy.web(req, res, {target})
    )
  ).catch((err) ->
    console.log("can't find #{zkDruidCoordinator}", err)
    res.send(500, { error: "can't find #{zkDruidCoordinator}, #{err}" })
  )
)

app.all('/pass/indexer/:cluster*', (req, res) ->
  req.url = req.url.replace(/\/pass\/indexer\/[^\/]+\//, '/')
  zkDruidIndexer = getZkDruidIndexer(req)
  getDruidLocator(zkDruidIndexer).then((loc) ->
    target = getHttpHostAndPort(loc)
    console.log("Proxying to indexer at #{target}#{req.url}")
    proxy.web(req, res, {target})
  ).catch((err) ->
    console.log("can't find #{zkDruidIndexer}", err)
    res.send(500, { error: "can't find #{zkDruidIndexer}, #{err}" })
  )
)

app.get('/pass/bard/:cluster*', (req, res) ->
  req.url = req.url.replace(/\/pass\/bard\/[^\/]+\//, '/')
  zkDruidBard = getZkDruidBard(req)
  getDruidLocator(zkDruidBard).then((loc) ->
    target = getHttpHostAndPort(loc)
    console.log("Proxying to bard at #{target}#{req.url}")
    proxy.web(req, res, {target})
  ).catch((err) ->
    console.log("can't find #{zkDruidBard}", err)
    res.send(500, { error: "can't find #{zkDruidBard} - #{err}" })
  )
)

app.get('/', (req, res) ->
  res.redirect(302, '/console/prod/#/')
)

app.use(cookieParser())
app.use(bodyParser.raw())
app.use(methodOverride())
app.use(compression())
app.use(express.json())

app.use(express.static(path.join(rootPath, 'static'), { maxAge: oneYear }))
app.use(express.static(path.join(rootPath, 'build')))
app.use('/fonts', express.static(path.join(rootPath, 'bower_components/font-awesome/fonts')))
app.use('/css', express.static(path.join(rootPath, 'bower_components/font-awesome/css')))
app.use('/css', express.static(path.join(rootPath, 'bower_components/bootstrap/dist/css')))

app.disable('x-powered-by')

app.get('/console*', (req, res) ->
  res.sendfile(path.join(rootPath, 'static/console.html'))
)

app.get('/coordinator/:cluster', (req, res) ->
  zkDruidCoordinator = getZkDruidCoordinator(req)
  getDruidLocator(zkDruidCoordinator).then((loc) ->
    res.status(200).send(loc)
  ).catch((err) ->
    console.log("can't find #{zkDruidCoordinator}", err)
    res.status(500).send({ error: "can't find #{zkDruidCoordinator}, #{err}" })
  )
)

app.get('/overlord/:cluster', (req, res) ->
  zkDruidIndexer = getZkDruidIndexer(req)
  getDruidLocator(zkDruidIndexer).then((loc) ->
    res.status(200).send(loc)
  ).catch((err) ->
    console.log("can't find #{zkDruidIndexer}", err)
    res.status(500).send({ error: "can't find #{zkDruidIndexer}, #{err}" })
  )
)

app.all('/health', (req, res) -> res.status(200).send('OK'))

# startup
console.log('Discovering druid cluster...')
dns.resolve4(zkHostname, (err, addresses) ->
  throw err if err
  console.log(
    "Zookeeper discovery at #{zkHostname} resolved to #{addresses.length} ZK node IP addresses: #{addresses.join(', ')}"
  )
  zkDiscovery = ZookeeperLocator.getLocatorFactory({
    serverLocator: SimpleLocator.getLocatorFactory()(zkHostname),
    path: process.env.ZK_SERVICE_DISC_PATH
  })

  console.log('Starting http server...')
  port = if /^\d+$/.test process.argv[2] then parseInt(process.argv[2]) else 8080
  app.listen(port)
  console.log("Listening on port #{port}")
)
