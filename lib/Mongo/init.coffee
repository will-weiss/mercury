# Initializes an instance of MongoModel by extending its fields and adding one
# level of relationships.

{_, graphql, Link} = require('../dependencies')

{ GraphQLString, GraphQLBoolean, GraphQLFloat, GraphQLID, GraphQLString
, GraphQLObjectType, GraphQLList } = graphql

idListType = new GraphQLList(GraphQLID)

# Map MongoDB types to GraphQL types
typeMap =
  Boolean: GraphQLBoolean
  Number: GraphQLFloat
  String: GraphQLString
  Date: GraphQLString
  ObjectId: GraphQLID


# Iterate over the schema of the MongoModel's MongooseModel to determine its
# fields and relationships.
init = ->
  {schema} = @MongooseModel
  {models} = @app

  # From a document field, obtain a corresponding GraphQL field. Return
  # undefined if the document field has no valid GraphQL type.
  getGraphQLField = (docField, name) =>
    type = getGraphQLType(docField, name)
    if type then {type, description: name}

  # Create a GraphQLObjectType for a subdocument.
  getGraphQLObjectType = (subDoc, name) =>
    fields = _.mapValues subDoc, (field, path) =>
      getGraphQLField(field, "#{name}.#{path}")
    new GraphQLObjectType({name, fields})

  addLink = (name, ref, nested) =>
    type = if nested then idListType else GraphQLID
    @fieldsOnDoc[name] = {type, description: name}

    refModel = models[ref]
    # TODO throw if referrant model cannot be found?
    if refModel
      LinkCtor = if nested then Link.Sibling else Link.ParentChild
      new LinkCtor(@, refModel, name)

    return

  # Recursively determine the GraphQL type of a document field.
  getGraphQLType = (docField, name, nested) =>

    return unless docField?

    {ref, type} = docField

    switch
      # The virtual 'id' field is a GraphQLID
      when name is 'id'
        GraphQLID

      # If the field refers to another model, the objectType of that model is
      # the GraphQL type.
      when ref
        addLink(name, ref, nested)

      # If the docField or its 'type' attribute is a function, the corresponding
      # GraphQL type of that path is given by the type map. Note, that
      # Mongoose's Mixed type does not map to any type.
      when [docField, type].some(_.isFunction)
        typeMap[schema.paths[name].instance]

      # If the document field is an array, it is interpreted as a list of the
      # type given by the first element of the array.
      # i.e., [String] -> new GraphQLList(GraphQLString)
      when _.isArray(docField)
        new GraphQLList(getGraphQLType(docField[0], name, true))

      # If the document field is a subdocument, a corresponding
      # GraphQLObjectType is created.
      when _.isObject(docField)
        getGraphQLObjectType(docField, name)

      # Throw if the type could not be interpreted.
      else
        throw new Error("""Could not interpret schema path #{name} as a GraphQL
           type.""")

  # For each field in the tree of the schema, add a GraphQL field to the model
  # for all those document fields that correspond with GraphQL types.
  _.forEach schema.tree, (docField, name) =>
    field = getGraphQLField(docField, name)
    return unless field
    @fields[name] = @fieldsOnDoc[name] = field

  if @name is 'EmployerGroup'
    console.log @fieldsOnDoc

module.exports = init
