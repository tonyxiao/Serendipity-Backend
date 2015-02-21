
@Connections = new Mongo.Collection 'connections'
Connections.timestampable()

# MARK - Instance Methods
Connections.helpers
  messages: ->
    Messages.find
      connectionId: @_id

  # Relative to current user
  otherUser: (thisUser) ->
    thisUser ?= Meteor.user()
    if _.contains(@users, thisUser._id)
      recipientId = _.without(@users, thisUser._id)[0]
      return Users.findOne(recipientId)

# TODO: Remove once outdated references are refactored
@connections = Connections
