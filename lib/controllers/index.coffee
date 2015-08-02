module.exports.load = (app) ->
  delete module.exports.load
  require('./load')(module.exports, app)
