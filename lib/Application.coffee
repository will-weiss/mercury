{ _, bodyParser, cookieParser, express, expressSession, LaterList, defaults
, buildRelationships, buildGraphQLObjectTypes, Driver
, Caches } = require('./dependencies')

class Application
  constructor: (@opts={}) ->
    _.defaults(@opts, defaults.application)
    @express = express()
    @drivers = []
    @caches = new Caches()
    @models = {}

  addDriver: (type, opts) ->
    driver = new Driver.drivers[type](@, opts)
    @drivers.push(driver)
    driver

  configure: ->
    @express.set('port', @opts.port)
    @express.use(express.static(@opts.static)) if @opts.static
    @express.use(bodyParser({ limit: @opts.fileLimit }))
    @express.use(bodyParser.urlencoded({extended:true}))
    @express.use(cookieParser())

  # Error handling is the last thing in the stack
  configureAppErrorHandling: ->
    logger.info("Configuring error handling for app")
    @express.use (err, req, res, next) ->
      logger.error(err.message)
      res.status(500)
      res.send(err.stack)

  # Finally, start the server
  startServer: ->
    return new Promise (resolve, reject) =>
      @express.server = @express.listen @opts.port, (err) =>
        reject(err) if err
        resolve(@)

  run: ->
    LaterList.Relay.from(@drivers)
      .forEach (driver) => driver.connect()
      .then =>
        model.init() for model in _.values(@models)
        buildRelationships(@models)
        buildGraphQLObjectTypes(@models)
        @configure()
        @startServer()


module.exports = Application
