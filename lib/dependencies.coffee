# This module exports the dependencies of mercury.
dependencies = module.exports

# Dependencies listed in a non-circular resolution order.
dependencyList = [

  # node_modules
  'bluebird::Promise'
  'body-parser::bodyParser'
  'cookie-parser::cookieParser'
  'express'
  'express-session::expressSession'
  'fs'
  'graphql'
  'i'
  'lodash::_'
  'mongoose'

  # mercury
  './defaults'
  './utils'
  './Queryable'
  './Caches'
  './Batcher'
  './Driver'
  './createSchema'
  './Link'
  './buildModels'
  './Model'
  './Mongo'
  './Application'
]

# Load a dependency
loadOne = (dependency) ->
  [loc, name] = dependency.split('::')
  name ?= loc.split('/').pop()
  dependencies[name] = require(loc)

# Load all dependencies
dependencies.load = ->
  delete dependencies.load
  dependencyList.forEach(loadOne)
  return dependencies
