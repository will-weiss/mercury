module.exports.load = ->
  delete module.exports.load
  require('./load')(module.exports)
