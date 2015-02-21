
@Messages = new Mongo.Collection 'messages'
Messages.timestampable()

Messages.helpers
  connection: ->
    Connections.findOne(@connectionId)

  sender: ->
    Users.findOne(@senderId)

  recipient: ->
    Users.findOne(@recipientId)

# TODO: Remove once outdated references are refactored
@messages = Messages