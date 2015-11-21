{ _, graphqlHTTP, session, bodyParser, cookieParser, express, graphql
, buildModels, createSchema, utils, Caches } = require('./dependencies')


class Application
  defaults =
    fileLimit: '50mb'
    maxCookieAge: 60000
    port: 8000
    route: '/mercury'
    secret: 'random'
    verbose: true

  constructor: (@opts={}) ->
    _.defaults(@opts, defaults)
    @express = express()
    @drivers = []
    @caches = new Caches()
    @models = {}
    @schema = null

    for type of Application.drivers
      continue unless type of @opts
      for driverOpts in [].concat(@opts[type])
        @addDriver(type, driverOpts)

  use: ->
    @express.use.apply(@express, arguments)

  set: ->
    @express.set.apply(@express, arguments)

  configure: ->
    @set('port', @opts.port)
    @use(bodyParser.json())
    @use(bodyParser.urlencoded({extended: true, limit: @opts.fileLimit}))
    @use(cookieParser())
    @use(session({secret: @opts.secret, cookie: {maxAge: @opts.maxCookieAge}}))

  startServer: ->
    new Promise (resolve, reject) =>
      @express.listen @opts.port, (err) ->
        if err then reject(err) else resolve()

  addSchema: ->
    @schema = schema = createSchema(@models)
    @express.use @opts.route, graphqlHTTP (request) ->
      schema: schema
      rootValue: request.session

  run: ->
    Promise.all(driver.connect() for driver in @drivers).then =>
      @configure()
      buildModels(@models)
      @addSchema()
      @startServer()

  addDriver: (type, name, opts) ->
    DriverCtor = Application.drivers[type]
    driver = new DriverCtor(@, name, opts)
    @drivers.push(driver)
    driver

# Keep a map of available driver constructors.
Application.drivers = {}

# Include a driver constructor, enabling drivers of that type to be added to
# applications.
Application.includeDriver = (DriverCtor) ->
  # Check the implementation of the driver constructor.
  utils.checkImplementation(DriverCtor)
  # Get the type of driver.
  type = DriverCtor::type
  # Add the driver constructor by type.
  Application.drivers[type] = DriverCtor

  # Add to an application's prototype a function for adding this type of driver.
  Application::["add#{type}Driver"] = (name, opts) ->
    @addDriver(type, name, opts)

module.exports = Application
