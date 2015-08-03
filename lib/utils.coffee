{LaterList} = require('./dependencies')

{Flood, Relay} = LaterList

exports.toFlood = (stream) ->
  flood = new Flood()
  stream.on 'data', flood.push.bind(flood)
  stream.on 'error', flood.end.bind(flood)
  stream.on 'close', flood.end.bind(flood)
  return flood

exports.accumQuery = (query, queryFn) -> queryFn(query)

exports.reduceQueries = (firstQuery, queryFns) ->
  Relay.from(queryFns).reduce(accumQuery, firstQuery)

exports.ctorMustImplement = (Ctor, fnNames...) ->
  fnNames.forEach (fnName) ->
    Ctor[fnName] = ->
      throw new Error("#{Ctor.name} must implement #{fnName}.")

exports.protoMustImplement = (Ctor, fnNames...) ->
  fnNames.forEach (fnName) ->
    Ctor[fnName] = ->
      throw new Error("#{Ctor.name}.prototype must implement #{fnName}.")
