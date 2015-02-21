
@Messages = new Mongo.Collection 'messages'
Messages.timestampable()

Messages.helpers
  connection: ->
    Connections.findOne(@connectionId)

  sender: ->
    Users.findOne(@senderId)

  recipient: ->
    Users.findOne(@recipientId)


# MARK: - Schema Validation
Messages.attachSchema new SimpleSchema
  connectionId: type: String
  senderId: type: String
  recipientId: type: String
  text: type: String

# TODO: Remove once outdated references are refactored
@messages = Messages