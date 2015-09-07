{ _, bodyParser, cookieParser, debug, express
, expressSession, graphql , LaterList, defaults
, buildModels, Driver, Caches, createSchema } = require('./dependencies')

class Application

  constructor: (@opts={}) ->
    _.defaults(@opts, defaults.application)
    @express = express()
    @drivers = []
    @caches = new Caches()
    @models = {}
    @schema = null

  addDriver: (type, opts) ->
    driver = new Driver.drivers[type](@, opts)
    @drivers.push(driver)
    driver

  configure: ->
    @express.set('port', @opts.port)
    @express.use(bodyParser.json())
    @express.use(bodyParser.urlencoded({extended:true, limit: @opts.fileLimit}))
    @express.use(cookieParser())

  startServer: ->
    new Promise (resolve, reject) =>
      @express.listen @opts.port, (err) ->
        if err then reject(err) else resolve()

  addSchema: ->
    @schema = createSchema(@models)
    respond = graphql.graphql.bind(graphql, @schema)
    @express.get @opts.route, (req, res) ->
      respond(req.query.query, req)
        .then (result) -> res.status(200).send(result)
        .catch (err) -> res.status(500).send(err)

  run: ->
    LaterList.Relay.from(@drivers)
      .forEach (driver) -> driver.connect()
      .then =>
        @configure()
        buildModels(@models)
        @addSchema()
        @startServer()


module.exports = Application
