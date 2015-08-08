{ _, bodyParser, cookieParser, express, expressSession, graphql, LaterList
, defaults, buildModels, Driver, Caches } = require('./dependencies')

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
    @express.use(bodyParser({limit: @opts.fileLimit}))
    @express.use(bodyParser.urlencoded({extended:true}))
    @express.use(cookieParser())

  configureAppErrorHandling: ->
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

  addSchemas: ->
    _.forEach @models, (model, name) =>
      return unless model.schema
      @express.get "#{@opts.route}/#{name}", (req, res) ->
        graphql.graphql(model.schema, JSON.parse(req.query.query).query, req)
        .then (result) =>
          res.status(200).send(result)
        .catch (err) =>
          console.log(err)
          res.status(500).send(err)

  run: ->
    LaterList.Relay.from(@drivers)
      .forEach (driver) => driver.connect()
      .then =>
        @configure()
        buildModels(@models)
        @addSchemas()
        @startServer()


module.exports = Application
