{_, graphql} = require('./dependencies')

{ GraphQLNonNull, GraphQLString, GraphQLObjectType, GraphQLSchema
, GraphQLList, GraphQLID } = graphql

idType = new GraphQLNonNull(GraphQLID)
fieldListType = new GraphQLList(GraphQLString)

getCreateField = (model, name) ->
  {appearsAsSingular, objectType, fieldsOnDoc} = model
  createFieldName = 'create' + _.capitalize(appearsAsSingular)
  type = objectType
  args = _.clone(fieldsOnDoc)
  parentNameToParentId = _.chain(model.relationships.parent)
    .map ({links}, name) ->
      return if links.length isnt 1
      [name, links[0].refKey]
    .compact()
    .tap ([name, parentId]) -> args[name] = {name, type: GraphQLID}
    .object()
    .value()

  resolve = (root, docInit) ->
    _.chain(docInit)
      .map (value, key) ->
        return unless value?
        key = parentNameToParentId[key] || key
        [key, value]
      .compact()
      .object()
      .thru(model.create.bind(model))
      .value()

  [createFieldName, {type, args, resolve}]

getUpdateField = (model, name) ->
  {appearsAsSingular, objectType, fieldsOnDoc, parentNameToParentId} = model

  updateFieldName = 'update' + _.capitalize(appearsAsSingular)
  type = objectType
  args = _.clone(fieldsOnDoc)
  args[name] = {name, type: GraphQLString} for name of parentNameToParentId

  args =
    id:
      description: "id of the #{name} to update"
      type: idType
    set:
      description: "Values of the #{name} to update"
      type: objectType
    unset:
      description: "Keys of the #{name} to set as null"
      type: fieldListType

  resolve = (root, {id, set, unset}) ->
    console.log set
    _.chain(set)
      .map (value, key) ->
        return unless value?
        key = parentNameToParentId[key] || key
        [key, value]
      .compact()
      .object()
      .thru (doc) -> doc[key] = null for key in (unset || [])
      .thru(model.update.bind(model, id))
      .value()

  [updateFieldName, {type, args, resolve}]

createMutationType = (models) ->
  fields = _.chain([getCreateField, getUpdateField])
    .map (fn) -> _.chain(models).map(fn).value()
    .flatten()
    .object()
    .value()

  new GraphQLObjectType({fields, name: 'Mutation'})

createQueryType = (models) ->
  fields = _.chain(models)
    .map (model, name) ->
      field =
        type: model.objectType
        args:
          id:
            description: "id of the #{name} to find"
            type: idType
        resolve: (root, {id}) -> model.findById(id)
      [model.appearsAsSingular, field]
    .object()
    .value()

  new GraphQLObjectType({fields, name: 'Query'})

createRootSchema = (models) ->
  query = createQueryType(models)
  mutation = createMutationType(models)
  new GraphQLSchema({query, mutation})

module.exports = createRootSchema
