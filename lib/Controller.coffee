# A class for registrering controllers of an app.
class Controller

  constructor: (@app) ->

  addEndpoint: (verb, route, fns...) ->
    args = [route, auth.requireLogin.bind(auth)].concat(fns)
    @app[verb].apply(@app, args)


module.exports = Controller
