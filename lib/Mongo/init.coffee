# Initializes an instance of MongoModel by extending its fields and adding one
# level of relationships.
{_, graphql, utils, Link, Queryable} = require('../dependencies')

{ GraphQLString, GraphQLBoolean, GraphQLFloat
, GraphQLID , GraphQLString } = graphql


# Map MongoDB types to GraphQL types.
typeMap =
  Boolean: GraphQLBoolean
  Number: GraphQLFloat
  String: GraphQLString
  Date: GraphQLString
  ObjectID: GraphQLID


# Interprets a schema field, adding the appropriate GraphQL typed fields to
# the queryable entity of a supplied initializer.
class FieldInterpreter
  # Set the properties of the interpreter and add fields given the calculated
  # type information for the supplied schema field.
  constructor: (@initializer, @schemaField, @name) ->
    @path = @initializer.path.concat([@name])
    @dotPath = @path.join('.')
    @inputObjectType = null
    @objectType = @getObjectType()

  typeErr: (explanation) ->
    throw new Error("Indeterminate GraphQL type for {path: '#{@dotPath}', model:
      #{@initializer.model.name}}. #{explanation}")

  # Recursively determine the GraphQL type of a schema field.
  getObjectType: (nested) ->
    # If getting the object type of a nested field examine the first element of
    # the supplied schema field, otherwise use the schema field itself.
    schemaField = if nested then @schemaField[0] else @schemaField
    # Alias the model of the initializer.
    {model} = @initializer
    # Alias the referrant and type of the schemaField.
    {ref, type} = schemaField
    switch
      # If the field refers to another model, add a link to the referrant model.
      # If the schema field is nested in an array, the type is a list of ids,
      # otherwise is is a single id.
      when ref
        refModel = model.app.models[ref]
        unless refModel
          return @typeErr("The schema refers to an unknown model '#{ref}'.")
        # Arrays of ids refer to siblings. Single id's refer to parents.
        LinkCtor = if nested then Link.Sibling else Link.ParentChild
        new LinkCtor(model, refModel, @dotPath)
        if nested then utils.getListType(GraphQLID) else GraphQLID

      # If the schemaField or its 'type' attribute is a function, the
      # corresponding GraphQL type of that path is given by the type map. Note,
      # Mongoose's Mixed type does not map to any type such that these fields
      # are not added.
      when [schemaField, type].some(_.isFunction)
        # Look up the path's schema.
        pathSchema = @initializer.model.MongooseModel.schema.paths[@dotPath]
        # If the path is nested, look up the caster of the path schema.
        # TODO this feels slightly hacky
        pathSchema = pathSchema.caster if nested
        # Look up the corresponding GraphQL type of the path schema's instance.
        if pathSchema.instance of typeMap
          typeMap[pathSchema.instance]
        else
          @typeErr("The mongoose SchemaType '#{pathSchema.instance}' is
            ambiguous.")

      # If the schema field is an array, it is interpreted as a list of the
      # type given by the first element of the array.
      # i.e., [String] -> new GraphQLList(GraphQLString)
      when _.isArray(schemaField)
        utils.getListType(@getObjectType(true))

      # If the schema field is a subschema, get the object type of the
      # subschema.
      when _.isObject(schemaField)
        subQueryable = new Queryable("#{model.appearsAsSingular}.#{@dotPath}")
        new Initializer(model, subQueryable, @path, schemaField)
        # The input object type of the sub queryable entity is set on the field
        # interpreter.
        {@inputObjectType} = subQueryable
        # Return the sub queryable entity's object type.
        subQueryable.objectType

      # Throw if the type could not be interpreted.
      else
        @typeErr("Schema at path \"#{schemaField}\" is not an object")


# Initializes a supplied model and a queryable entity of that model with the
# fields of a supplied schema.
class Initializer
  constructor: (@model, @queryable, @path, schemaTree) ->
    # Interpret the fields of the supplied schema.
    _.forEach(schemaTree, @interpretField.bind(@))

  # Add fields to a queryable entity for an object and input object type. If no
  # input object type is given, the supplied object type is used instead.
  interpretField: (schemaField, name) ->
    # Mongoose's auto populated 'id' field is unnecessary for our purposes and
    # is ignored.
    return if name is 'id' and not @path.length
    # Create an interpreter for the schema's field.
    @addFields(new FieldInterpreter(@, schemaField, name))

  addFields: ({name, objectType, inputObjectType}) ->
    @queryable.addField(name, objectType)
    # If the field interpreter had no input object type use its object type as
    # an input type.
    @queryable.addInputField(name, inputObjectType || objectType)


# Called with an execution context of a MongoModel. Iterates over the schema of
# the MongooseModel to determine its fields and relationships.
module.exports = ->
  # Create an initializer for the model whose queryable entity is the model
  # itself with no path yet traversed and a schema equal to the whole tree of
  # the schema.
  new Initializer(@, @, [], @MongooseModel.schema.tree)
