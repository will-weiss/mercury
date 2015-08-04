{utils, LaterList} = require('./dependencies')

class ModelInstance
  constructor: (@Model) ->

  findAncestor: (ancestorName) ->
    {links} = @relationships.parent[ancestorName]


    @genFirstQuery(parentId)
    Later


utils.protoMustImplement(ModelInstance, 'get', 'set', 'getId', 'getQuery')

module.exports = ModelInstance
