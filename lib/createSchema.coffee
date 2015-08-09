{_, graphql} = require('./dependencies')

{GraphQLNonNull, GraphQLString, GraphQLObjectType, GraphQLSchema} = graphql

idArgumentType = new GraphQLNonNull(GraphQLString)

getCreateField = (model, name) ->
  type = model.objectType
  args = _.clone(model.basicFields)
  parentNameToParentId = _.invert(model.parentIdFields)
  _.keys(parentNameToParentId).forEach (name) ->
    args[name] = {name, type: GraphQLString}

  resolve = (root, docInit) ->
    doc = _.chain(docInit)
      .map (value, key) ->
        return unless value?
        key = parentNameToParentId[key] || key
        [key, value]
      .compact()
      .object()
      .value()
    model.create(doc)

  ['create' + _.capitalize(model.appearsAsSingular), {type, args, resolve}]

createMutation = (models) ->
  fields = _.chain(models).map(getCreateField).object().value()
  new GraphQLObjectType({fields, name: 'Mutation'})

createQuery = (models) ->
  fields = _.chain(models)
    .map (model, name) ->
      field =
        type: model.objectType
        args:
          id:
            description: "id of the #{name}"
            type: new GraphQLNonNull(GraphQLString)
        resolve: (root, {id}) -> model.findById(id)
      [model.appearsAsSingular, field]
    .object()
    .value()

  new GraphQLObjectType({fields, name: 'Query'})

createRootSchema = (models) ->
  query = createQuery(models)
  mutation = createMutation(models)
  new GraphQLSchema({query, mutation})

module.exports = createRootSchema
