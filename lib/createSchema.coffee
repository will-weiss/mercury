{_, graphql} = require('./dependencies')

{ GraphQLNonNull, GraphQLString, GraphQLObjectType, GraphQLSchema
, GraphQLBoolean, GraphQLList, GraphQLID } = graphql

idType = new GraphQLNonNull(GraphQLID)
fieldListType = new GraphQLList(GraphQLString)


class GraphQLField
  constructor: (@name) ->
    @args = {}
    @type = null
    @resolve = null


class ReadField extends GraphQLField
  constructor: (model, name) ->
    super model.appearsAsSingular
    @type = model.objectType

    @args.id =
      description: "id of the #{name} to find"
      type: idType

    @resolve = (root, {id}) -> model.findById(id)


class MutationField extends GraphQLField
  constructor: (model) ->
    super @mutation + _.capitalize(model.appearsAsSingular)


class CreateField extends MutationField
  mutation: 'create'

  constructor: (model, name) ->
    super model
    @args.doc =
      description: "A #{name} document to create"
      type: model.inputObjectType
    @type = model.objectType

    @resolve = (root, {doc}) -> model.create(doc)


class UpdateField extends MutationField
  mutation: 'update'

  constructor: (model, name) ->
    super model
    @args.id =
      description: "id of the #{name} to update"
      type: idType
    @args.set =
      description: "Updates to a #{name} document"
      type: new GraphQLNonNull(model.inputObjectType)
    @args.unset =
      description: "Keys of the #{name} document to unset"
      type: fieldListType

    @type = model.objectType

    @resolve = (root, {id, set, unset}) ->
      updates = {}
      updates[k] = v for k, v of set when v?
      updates[k] = null for k in unset if unset
      model.update(id, updates)


class RemoveField extends MutationField
  mutation: 'remove'

  constructor: (model, name) ->
    super model
    @args.id =
      description: "id of the #{name} to remove"
      type: idType
    @type = GraphQLBoolean

    @resolve = (root, {id}) -> model.remove(id)


createOperationObjectType = (models, ctors, operation) ->
  fields =_.chain(ctors)
    .map (FieldCtor) ->
      _.map models, (model, name) -> new FieldCtor(model, name)
    .flatten()
    .map (f) -> [f.name, f]
    .object()
    .value()

  new GraphQLObjectType({fields, name: _.capitalize(operation)})

operationCtors =
  query: [ReadField]
  mutation: [CreateField, UpdateField, RemoveField]


module.exports = (models) ->
  _.chain(operationCtors)
    .mapValues(createOperationObjectType.bind(null, models))
    .thru (obj) ->
      new GraphQLSchema(obj)
    .value()
