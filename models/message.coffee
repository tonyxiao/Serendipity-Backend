
@Messages = new Mongo.Collection 'messages'
Messages.timestampable()

Messages.helpers
  connection: ->
    Connections.findOne(@connectionId)

# TODO: Remove once outdated references are refactored
@messages = Messages