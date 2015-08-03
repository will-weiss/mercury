{_, graphql, allong} = DEPENDENCIES
{ GraphQLObjectType, GraphQLNonNull, GraphQLSchema, GraphQLString,
  GraphQLBoolean, GraphQLFloat, GraphQLList } = graphql

relations = require('./relations')
getProjection = require('./getProjection')

# Store a map of GraphQL object types for the various models
GRAPH_QL_OBJECT_TYPES = {}

# Map mongoose types to their corresponding GraphQL types
mongooseTypeToGraphQLType =
  String: GraphQLString
  Mixed: GraphQLObjectType
  Boolean: GraphQLBoolean
  Number: GraphQLFloat
  ObjectId: GraphQLString
  Date: GraphQLString

# Get a 'fields' object for a given model
getFields = (model) ->
  _.chain(model.schema.paths)
    .filter ({instance, path}) -> instance of mongooseTypeToGraphQLType
    .map ({instance, path}) ->
      type = mongooseTypeToGraphQLType[instance]
      description = path
      [path, {type, description}]
    .object()
    .value()

# Convert a given collection with its model to an info object containing the GraphQL object type
toGraphQlObjectTypeInfo = ([name, model]) ->
  {model} = model
  {modelName} = model
  fields = model.getFields()

  objectType = GRAPH_QL_OBJECT_TYPES[modelName] = new GraphQLObjectType
    name: modelName
    description: name
    fields: => fields

  return [name, {objectType, fields, model}]

# Get a resolve function for a given model
getResolve = (modelResolveFn) -> allong.es.unary(modelResolveFn)

# # Get a resolve function for a given model
# getResolve = (modelResolveFn) ->
#   (childModel, params, source, fieldASTs) =>
#     selections = getProjection(fieldASTs)
#     modelResolveFn(childModel, {}, selections)

# Get object infos by mapping over the titan configuration
objectInfos = _.chain(relations)
  .pairs()
  .map(toGraphQlObjectTypeInfo)
  .object()
  .value()

addChildResolves = ({parentColl, resolve, name, objectType, model}) ->
  {fields} = objectInfos[parentColl]
  {prettyPlural} = model
  fields[prettyPlural] =
    resolve: resolve
    description: name
    type: new GraphQLList(objectType)

addParentResolves = ({childColl, resolve, name, objectType, model}) ->
  {fields} = objectInfos[childColl]
  {prettyName} = model
  fields[prettyName] =
    resolve: resolve
    description: name
    type: objectType

# Extend existing object infos with other fields
extendObjectInfo = ({objectType, fields, model}, name) ->
  _.chain(model.findAsChildrenFns)
    .pairs()
    .map ([parentColl, findAsChildrenFn]) ->
      resolve = getResolve(findAsChildrenFn)
      {parentColl, resolve}
    .forEach ({parentColl, resolve}) ->
      addChildResolves({parentColl, resolve, name, objectType, model})
    .value()

  _.chain(model.childChains)
    .keys()
    .map (childColl) ->
      resolve = getResolve(model.findParent)
      {childColl, resolve}
    .forEach ({childColl, resolve}) ->
      addParentResolves({childColl, resolve, name, objectType, model})
    .value()

_.chain(objectInfos).forEach(extendObjectInfo).value()

module.exports = GRAPH_QL_OBJECT_TYPES
