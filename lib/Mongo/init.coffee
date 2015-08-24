# Initializes an instance of MongoModel by extending its fields and adding one
# level of relationships.

{_, graphql, Link, Queryable} = require('../dependencies')

{ GraphQLString, GraphQLBoolean, GraphQLFloat, GraphQLID, GraphQLString
, GraphQLObjectType, GraphQLList } = graphql

# Maintain a type representing a list of ids.
idListType = new GraphQLList(GraphQLID)

# Map MongoDB types to GraphQL types.
typeMap =
  Boolean: GraphQLBoolean
  Number: GraphQLFloat
  String: GraphQLString
  Date: GraphQLString
  ObjectId: GraphQLID


# Called with an execution context of a MongoModel. Iterate over the schema of
# the MongooseModel to determine its fields and relationships.
module.exports = ->
  thisModel = @
  {appearsAsSingular} = @
  {schema} = @MongooseModel
  {models} = @app


  # From a document field, obtain a corresponding GraphQL field. Return
  # undefined if the document field has no valid GraphQL type.
  getGraphQLField = (docField, name) =>
    type = getGraphQLType(docField, name)
    if type then toGraphQLField(type, name)

  # Create a GraphQLObjectType for a subdocument.
  getGraphQLObjectType = (subDoc, name) =>
    fields = _.mapValues subDoc, (field, path) =>
      getGraphQLField(field, "#{name}.#{path}")
    new GraphQLObjectType({name: "#{appearsAsSingular}.#{name}", fields})

  # Add a link between the model and its referrant model.
  addLink = (name, ref, nested) =>
    type = if nested then idListType else GraphQLID
    @fieldsOfDoc[name] = toGraphQLField(type, name)

    refModel = models[ref]
    # TODO throw if referrant model cannot be found?
    if refModel
      # Arrays of ids refer to siblings. Single id's refer to parents.
      LinkCtor = if nested then Link.Sibling else Link.ParentChild
      new LinkCtor(@, refModel, name)

    # Return no type. Fields have already been added by the Link constructor
    # when there is a referrant model.
    return

  # Recursively determine the GraphQL type of a document field.
  getGraphQLType = (docField, name, nested) =>
    # The doc field must exist to have a GraphQL type.
    return unless docField?
    # Alias the referrant and type of the docField.
    {ref, type} = docField
    # Determine the GraphQL type
    switch
      # If the field refers to another model, the objectType of that model is
      # the GraphQL type.
      when ref
        addLink(name, ref, nested)

      # If the docField or its 'type' attribute is a function, the corresponding
      # GraphQL type of that path is given by the type map. Note, that some
      # Mongoose's Mixed type does not map to any type such that these fields
      # are not immediately queryable.
      when [docField, type].some(_.isFunction)
        # TODO this feels hacky
        if nested
          typeMap[schema.paths[name].caster.instance]
        else
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
    return @addField(name, GraphQLID) if name is 'id'
    getGraphQLField(docField, name)
