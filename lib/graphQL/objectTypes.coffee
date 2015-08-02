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

# Convert a given collection with its modelCfg to an info object containing the GraphQL object type
toGraphQlObjectTypeInfo = ([coll, modelCfg]) ->
  {model} = modelCfg
  {modelName} = model
  fields = getFields(model)

  objectType = GRAPH_QL_OBJECT_TYPES[modelName] = new GraphQLObjectType
    name: modelName
    description: coll
    fields: => fields

  return [coll, {objectType, fields, modelCfg}]

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

addChildResolves = ({parentColl, resolve, coll, objectType, modelCfg}) ->
  {fields} = objectInfos[parentColl]
  {prettyPlural} = modelCfg
  fields[prettyPlural] =
    resolve: resolve
    description: coll
    type: new GraphQLList(objectType)

addParentResolves = ({childColl, resolve, coll, objectType, modelCfg}) ->
  {fields} = objectInfos[childColl]
  {prettyName} = modelCfg
  fields[prettyName] =
    resolve: resolve
    description: coll
    type: objectType

# Extend existing object infos with other fields
extendObjectInfo = ({objectType, fields, modelCfg}, coll) ->
  _.chain(modelCfg.findAsChildrenFns)
    .pairs()
    .map ([parentColl, findAsChildrenFn]) ->
      resolve = getResolve(findAsChildrenFn)
      {parentColl, resolve}
    .forEach ({parentColl, resolve}) ->
      addChildResolves({parentColl, resolve, coll, objectType, modelCfg})
    .value()

  _.chain(modelCfg.childChains)
    .keys()
    .map (childColl) ->
      resolve = getResolve(modelCfg.findParent)
      {childColl, resolve}
    .forEach ({childColl, resolve}) ->
      addParentResolves({childColl, resolve, coll, objectType, modelCfg})
    .value()

_.chain(objectInfos).forEach(extendObjectInfo).value()

module.exports = GRAPH_QL_OBJECT_TYPES
