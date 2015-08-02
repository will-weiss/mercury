# This module exports the dependencies of mercury
dependencies = module.exports

# Dependencies listed in a non-circular resolution order.
#
dependencyList = [
  # node_modules
  'allong.es::allong'
  'bluebird::Promise'
  'body-parser'
  'cookie-parser'
  'connect-mongo'
  'express'
  'express-session'
  'fs'
  'graphql'
  'i'
  'LaterList'
  'lodash::_'
  'moment'
  'vers'
  'util'
  'winston'
  # mercury
  './utils'
  './Caches'
  './Batcher'
  './Relationship'
  './ModelPrototype'
  './Model'
  './ModelContainer'
  './mongo'
  './graphQL'
  './Controller'
  './controllers'
  './Application'
]

# Loads a dependency
loadOne = (dependency) ->
  [loc, name] = dependency.split('::')
  name ?= loc.split('/').pop()
  dependencies[name] = require(loc)

# Loads all dependencies
dependencies.load = ->
  delete dependencies.load
  dependencyList.forEach(loadOne)
