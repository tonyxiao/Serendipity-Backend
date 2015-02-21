
@Connections = new Mongo.Collection 'connections'
Connections.timestampable()

# MARK - Instance Methods
Connections.helpers
  messages: ->
    Messages.find
      connectionId: @_id

  # Relative to current user
  otherUser: ->
    if Meteor.userId()
      recipientId = _.without(@users, Meteor.userId())[0]
      return Users.findOne(recipientId)

# TODO: Remove once outdated references are refactored
@connections = Connections
