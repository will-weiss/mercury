{_, graphql} = require('./dependencies')

{ GraphQLNonNull, GraphQLString, GraphQLObjectType, GraphQLSchema
, GraphQLList } = graphql

idType = new GraphQLNonNull(GraphQLString)
fieldListType = new GraphQLList(GraphQLString)

getCreateField = (model, name) ->
  {appearsAsSingular, objectType, basicFields, parentNameToParentId} = model
  createFieldName = 'create' + _.capitalize(appearsAsSingular)
  type = objectType
  args = _.clone(basicFields)
  args[name] = {name, type: GraphQLString} for name of parentNameToParentId

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
  {appearsAsSingular, objectType, basicFields, parentNameToParentId} = model

  updateFieldName = 'update' + _.capitalize(appearsAsSingular)
  type = objectType
  args = _.clone(basicFields)
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
