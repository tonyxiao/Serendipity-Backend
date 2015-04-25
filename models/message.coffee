
@Messages = new Mongo.Collection 'messages'
Messages.attachBehaviour('timestampable')

# MARK: - Schema Validation
Messages.attachSchema new SimpleSchema
  connectionId: type: String
  senderId: type: String
  recipientId: type: String
  text: type: String


# MARK: - Instance Methods
Messages.helpers
  connection: ->
    Connections.findOne(@connectionId)

  sender: ->
    Users.findOne(@senderId)

  recipient: ->
    Users.findOne(@recipientId)

  remove: ->
    Messages.remove @_id
